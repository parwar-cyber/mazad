// analyze_item — AI Listing Co-pilot (architecture.md §6.5).
//
// Input:  { listing_id: uuid } — the draft row owned by the authed caller.
// Output: 4-locale title/description, suggested category slug, condition,
//         specs, suggested starting price (IQD, integer), red flags.
//
// Server-side guarantees:
//   * App-Version gate runs FIRST (auto-update skill).
//   * Caller must be authenticated AND own the listing.
//   * Image paths read from the DB — never from the client.  Each path is
//     re-validated against "<seller_uid>/<listing_id>/" before constructing
//     a public URL.  This is the SSRF firewall: Gemini can only ever fetch
//     URLs inside our own listing-photos bucket, under the caller's folder.
//   * All four locale strings (title + description) are validated non-empty
//     before returning.  If Gemini can't produce all four, we 422 the
//     request so the client falls back to manual entry.
//   * suggested_starting_price_iqd is coerced to a non-negative integer
//     (money-handling skill — never float).
//
// We do NOT persist anything here.  The seller reviews the suggestion in
// the UI and calls `update_listing_draft` to save the edited fields.  This
// keeps the AI advisory rather than authoritative.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { checkAppVersion } from '../_shared/version_check.ts';
import { handlePreflight, jsonResponse } from '../_shared/cors.ts';

const GEMINI_MODEL = 'gemini-2.0-flash';
const GEMINI_ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// Max images to send to Gemini.  Architecture says "3+ photos"; we cap at
// 5 to keep the call cheap and avoid context-window edge cases.
const MAX_IMAGES_TO_ANALYZE = 5;

const LOCALES = ['en', 'ar', 'ku', 'tr'] as const;
type Locale = (typeof LOCALES)[number];

const CONDITIONS = ['new', 'like_new', 'good', 'fair', 'for_parts'] as const;

const PROMPT = `You are the AI listing assistant for Mazad, an Iraqi auction marketplace.

You will see 1-5 photographs of an item a seller wants to list. Inspect the photos and return JSON with these exact fields:

{
  "category_slug": one of: "phones" | "fashion" | "collectibles" | "home-goods",
  "title": { "en": "...", "ar": "...", "ku": "...", "tr": "..." },
  "description": { "en": "...", "ar": "...", "ku": "...", "tr": "..." },
  "condition": one of: "new" | "like_new" | "good" | "fair" | "for_parts",
  "suggested_specs": object with relevant key/value attributes (brand, model, size, color, etc.),
  "suggested_starting_price_iqd": integer (NEVER decimal) — a reasonable Iraqi-market starting price in IQD,
  "red_flags": array of short strings — anything concerning (counterfeit hints, restricted category, unclear photos)
}

Language rules — every locale string MUST be non-empty:
- "en": clean concise English. 6-12 word title, 30-100 word description.
- "ar": Modern Standard Arabic with natural Iraqi register. Right-to-left.
- "ku": Sorani (Central Kurdish) in Arabic script. Use proper Sorani glyphs (ێ ۆ ڕ ڵ). Right-to-left.
- "tr": Standard Istanbul Turkish with all required diacritics (ç ğ ı İ ö ş ü).

Pricing rules:
- IQD only. Never USD.
- Integer. No decimals. No commas.
- Conservative for unknown brands; aggressive for premium brands in poor condition is wrong — anchor low.

Return ONLY the JSON object — no prose, no markdown fences.
`;

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  const versionBlock = await checkAppVersion(req);
  if (versionBlock) return versionBlock;

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return jsonResponse(401, { error: 'unauthenticated' });

  let body: { listing_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: 'invalid_json' });
  }

  const listingId = body.listing_id;
  if (typeof listingId !== 'string' || !isUuid(listingId)) {
    return jsonResponse(400, { error: 'invalid_listing_id' });
  }

  // 1. Identify caller via the user JWT.
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    return jsonResponse(401, { error: 'unauthenticated' });
  }
  const uid = userData.user.id;

  // 2. Read the draft via the service-role definer RPC.  Never trust
  //    client-sent image paths — read what the seller has actually stored.
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: listing, error: listingErr } = await adminClient
    .rpc('get_listing_for_analysis', { p_id: listingId })
    .maybeSingle();

  if (listingErr || !listing) {
    return jsonResponse(404, { error: 'listing_not_found' });
  }
  if (listing.seller_id !== uid) {
    return jsonResponse(403, { error: 'not_listing_owner' });
  }

  const imagePaths = Array.isArray(listing.images) ? listing.images : [];
  if (imagePaths.length === 0) {
    return jsonResponse(422, { error: 'no_images' });
  }

  // 3. Re-validate each path begins with "<uid>/<listingId>/" — defense in
  //    depth even though update_listing_draft already enforces this.
  const expectedPrefix = `${uid}/${listingId}/`;
  const validPaths = imagePaths.filter(
    (p: unknown) => typeof p === 'string' && p.startsWith(expectedPrefix),
  ) as string[];
  if (validPaths.length === 0) {
    return jsonResponse(422, { error: 'no_valid_images' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const publicUrls = validPaths
    .slice(0, MAX_IMAGES_TO_ANALYZE)
    .map((p) => publicUrlFor(supabaseUrl, p));

  // 4. Fetch each image and base64-encode for Gemini's inline_data form.
  //    We could give Gemini the URL directly via `file_data`, but inline
  //    keeps the call deterministic and avoids exposing internal infra
  //    to the model's fetcher.
  const images = await Promise.all(publicUrls.map(fetchImageAsInlineData));
  const successfulImages = images.filter((i): i is NonNullable<typeof i> => i !== null);
  if (successfulImages.length === 0) {
    return jsonResponse(502, { error: 'image_fetch_failed' });
  }

  // 5. Call Gemini.
  const geminiKey = Deno.env.get('GEMINI_API_KEY');
  if (!geminiKey) {
    return jsonResponse(500, { error: 'gemini_not_configured' });
  }

  const geminiBody = {
    contents: [
      {
        role: 'user',
        parts: [
          { text: PROMPT },
          ...successfulImages.map((img) => ({
            inline_data: { mime_type: img.mime, data: img.b64 },
          })),
        ],
      },
    ],
    generationConfig: {
      response_mime_type: 'application/json',
      temperature: 0.3,
    },
  };

  const geminiRes = await fetch(`${GEMINI_ENDPOINT}?key=${geminiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(geminiBody),
  });

  if (!geminiRes.ok) {
    const text = await geminiRes.text().catch(() => '');
    console.log(JSON.stringify({
      event: 'analyze_item.gemini_http_error',
      status: geminiRes.status,
      uid,
      listing_id: listingId,
      body_excerpt: text.slice(0, 240),
    }));
    return jsonResponse(502, { error: 'gemini_request_failed' });
  }

  const geminiJson = await geminiRes.json().catch(() => null);
  const textOut = extractGeminiText(geminiJson);
  if (!textOut) {
    return jsonResponse(502, { error: 'gemini_empty_response' });
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(textOut);
  } catch {
    console.log(JSON.stringify({
      event: 'analyze_item.parse_failed',
      uid,
      listing_id: listingId,
      excerpt: textOut.slice(0, 240),
    }));
    return jsonResponse(502, { error: 'gemini_invalid_json' });
  }

  const validated = validateAndCoerce(parsed);
  if (!validated.ok) {
    console.log(JSON.stringify({
      event: 'analyze_item.validation_failed',
      uid,
      listing_id: listingId,
      reason: validated.reason,
    }));
    return jsonResponse(422, { error: validated.reason });
  }

  console.log(JSON.stringify({
    event: 'analyze_item.ok',
    uid,
    listing_id: listingId,
    image_count: successfulImages.length,
    category_slug: validated.value.category_slug,
    condition: validated.value.condition,
    red_flag_count: validated.value.red_flags.length,
  }));

  return jsonResponse(200, validated.value);
});

// ─── Helpers ─────────────────────────────────────────────────────────────

function isUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

function publicUrlFor(supabaseUrl: string, path: string): string {
  return `${supabaseUrl}/storage/v1/object/public/listing-photos/${path
    .split('/')
    .map(encodeURIComponent)
    .join('/')}`;
}

async function fetchImageAsInlineData(
  url: string,
): Promise<{ mime: string; b64: string } | null> {
  try {
    const res = await fetch(url);
    if (!res.ok) return null;
    const mime = res.headers.get('Content-Type') ?? 'image/jpeg';
    if (!mime.startsWith('image/')) return null;
    const buf = await res.arrayBuffer();
    // Reject anything > 8 MB — Gemini limits inline payload size and we
    // already cap upload size on the client to 4 MB per photo.
    if (buf.byteLength > 8 * 1024 * 1024) return null;
    return { mime, b64: bufferToBase64(buf) };
  } catch {
    return null;
  }
}

function bufferToBase64(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let bin = '';
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
  }
  return btoa(bin);
}

function extractGeminiText(json: unknown): string | null {
  if (!json || typeof json !== 'object') return null;
  // deno-lint-ignore no-explicit-any
  const cands = (json as any).candidates;
  if (!Array.isArray(cands) || cands.length === 0) return null;
  const parts = cands[0]?.content?.parts;
  if (!Array.isArray(parts)) return null;
  const out = parts.map((p: { text?: string }) => p?.text ?? '').join('');
  return out.length > 0 ? out : null;
}

type Validated = {
  category_slug: string;
  title: Record<Locale, string>;
  description: Record<Locale, string>;
  condition: typeof CONDITIONS[number];
  suggested_specs: Record<string, unknown>;
  suggested_starting_price_iqd: number;
  red_flags: string[];
};

function validateAndCoerce(
  raw: unknown,
):
  | { ok: true; value: Validated }
  | { ok: false; reason: string } {
  if (!raw || typeof raw !== 'object') {
    return { ok: false, reason: 'not_object' };
  }
  // deno-lint-ignore no-explicit-any
  const r = raw as any;

  if (typeof r.category_slug !== 'string') return { ok: false, reason: 'category_slug_missing' };

  // Validate the 4-locale strings — non-empty in every locale.  This is
  // the contract the spec is most insistent on.
  const title = coerceTranslations(r.title);
  if (!title) return { ok: false, reason: 'title_missing_locale' };
  const description = coerceTranslations(r.description);
  if (!description) return { ok: false, reason: 'description_missing_locale' };

  if (typeof r.condition !== 'string'
      || !(CONDITIONS as readonly string[]).includes(r.condition)) {
    return { ok: false, reason: 'condition_invalid' };
  }

  const specs = (r.suggested_specs && typeof r.suggested_specs === 'object'
    && !Array.isArray(r.suggested_specs))
    ? r.suggested_specs as Record<string, unknown>
    : {};

  // Money — integer, non-negative.  Coerce Gemini's number to floor int.
  // If it comes back as a string, parse; reject NaN.
  let priceN: number;
  if (typeof r.suggested_starting_price_iqd === 'number') {
    priceN = r.suggested_starting_price_iqd;
  } else if (typeof r.suggested_starting_price_iqd === 'string') {
    priceN = parseInt(r.suggested_starting_price_iqd.replace(/[^\d-]/g, ''), 10);
  } else {
    priceN = 0;
  }
  if (!Number.isFinite(priceN) || priceN < 0) priceN = 0;
  // Cap at a sane upper bound to neutralize hallucinations.
  const priceInt = Math.min(Math.floor(priceN), 1_000_000_000); // 1B IQD cap

  const redFlags = Array.isArray(r.red_flags)
    ? r.red_flags
        .filter((s: unknown) => typeof s === 'string')
        .slice(0, 8)
        .map((s: string) => s.slice(0, 200))
    : [];

  return {
    ok: true,
    value: {
      category_slug: r.category_slug,
      title,
      description,
      condition: r.condition as typeof CONDITIONS[number],
      suggested_specs: specs,
      suggested_starting_price_iqd: priceInt,
      red_flags: redFlags,
    },
  };
}

function coerceTranslations(input: unknown): Record<Locale, string> | null {
  if (!input || typeof input !== 'object') return null;
  // deno-lint-ignore no-explicit-any
  const obj = input as any;
  const out: Partial<Record<Locale, string>> = {};
  for (const loc of LOCALES) {
    const raw = obj[loc];
    if (typeof raw !== 'string') return null;
    const trimmed = raw.trim();
    if (trimmed.length === 0) return null;
    // Soft cap; Postgres also truncates inside update_listing_draft.
    out[loc] = trimmed.slice(0, 4000);
  }
  return out as Record<Locale, string>;
}

