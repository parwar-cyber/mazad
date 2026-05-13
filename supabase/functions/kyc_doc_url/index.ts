// kyc_doc_url — issues a 5-minute signed URL for a kyc-docs object.
//
// Two callers:
//   1. The owning user, re-fetching their own ID doc to display on the
//      KYC review screen.
//   2. The admin console (Phase 9, via service-role JWT), reviewing a
//      submitted KYC.
//
// Privacy invariants (Phase 1 PR description spells these out):
//   * Object paths are NEVER logged.
//   * Document contents are NEVER logged.
//   * Error responses are intentionally generic ("kyc_doc_unavailable")
//     so we don't leak whether a path exists for someone else's UUID.
//
// Per auto-update skill, every Edge Function calls checkAppVersion() first.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { checkAppVersion } from '../_shared/version_check.ts';

const SIGNED_URL_TTL_SECONDS = 5 * 60; // 5 minutes — non-negotiable per spec

Deno.serve(async (req) => {
  const versionBlock = await checkAppVersion(req);
  if (versionBlock) return versionBlock;

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return jsonResponse(401, { error: 'unauthenticated' });

  let body: { path?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: 'invalid_json' });
  }
  const path = body.path;
  if (typeof path !== 'string' || path.length === 0) {
    return jsonResponse(400, { error: 'missing_path' });
  }

  // Identify the caller via the user JWT.  The anon key is fine for the
  // user-context client; signed URL minting itself requires the service
  // role and is done with a separate client below.
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

  // Authorization: caller must own the path (path-prefix match).
  // Storage RLS would also reject a non-owner, but doing the check here
  // keeps service-role minting from accidentally widening the scope.
  // Admins (Phase 9) will hit this Edge Function with a service-role JWT
  // and will bypass this check — gated by the `aud === 'admin'` claim
  // we will introduce when the admin console lands.  For Phase 1 the
  // strict owner check is correct.
  const expectedPrefix = `${uid}/`;
  if (!path.startsWith(expectedPrefix)) {
    // Generic error — do not leak the existence of others' files.
    return jsonResponse(404, { error: 'kyc_doc_unavailable' });
  }

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: signed, error: signErr } = await adminClient.storage
    .from('kyc-docs')
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);

  if (signErr || !signed?.signedUrl) {
    // Structured log — outcome only, no path or contents.
    console.log(JSON.stringify({
      event: 'kyc_doc_url.sign_failed',
      uid,
      reason: signErr?.message ?? 'unknown',
    }));
    return jsonResponse(404, { error: 'kyc_doc_unavailable' });
  }

  // Success log — outcome only.
  console.log(JSON.stringify({
    event: 'kyc_doc_url.signed',
    uid,
    ttl_seconds: SIGNED_URL_TTL_SECONDS,
  }));

  return jsonResponse(200, {
    url: signed.signedUrl,
    expires_in: SIGNED_URL_TTL_SECONDS,
  });
});

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
