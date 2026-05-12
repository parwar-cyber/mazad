# Mazad — Architecture & Build Spec

> Final build spec. Place at `docs/architecture.md`.
> Target market: Iraq (KRI + federal). Languages: English, Arabic, Sorani Kurdish, Turkish.
> Stack: Flutter (iOS + Android + Web) · Supabase · Gemini · FCM · SMS · Email · WhatsApp-ready.
> Positioning: *Iraq's most trusted auction marketplace. No snipes. Verified video on every listing. Escrow on every order.*

---

## 1. Positioning & Trust Pillars

A clean, trustworthy auction marketplace with three sale modes — **Auction**, **Buy Now**, and **Group Bazaar** (under 10k IQD). The competitive edge comes from a stack of trust mechanisms tuned for the Iraqi market.

**Trust pillars:**
1. **Smart Close auctions** — extend while bidding is active, kill last-second snipes.
2. **Verified Video** — every listing can include a watermarked seller-recorded video, AI-checked for the listing ID. Badge boosts search ranking and conversion.
3. **Verified Sellers** — tiered KYC, two-way ratings, optional contact-network vouching.
4. **Escrow on every order** — held until delivery confirmed; seller-float system for COD.

**Growth surface:**
5. **Group Bazaar** — under-10k IQD viral group-buy mechanic.

**Seller-side magic:**
6. **AI Listing Co-pilot** — Gemini Vision turns 3 photos into a four-language listing.

**Future unlock (architected, not active at launch):**
7. **WhatsApp-native bidding** — schema and worker code ready, behind feature flag.

---

## 2. Mapping the standard auction checklist

### 🔐 User Onboarding & Profiles
- **Unified Registration** (not split) — phone OTP signup, anyone can browse and bid. "Start selling" upgrade triggers Tier 2 KYC.
- **KYC tiers** — Tier 0 (browse) → Tier 1 (buy/bid up to 100k IQD) → Tier 2 (sell + high-value bid).
- **Payment Onboarding** — wallet (ZainCash/FastPay) or payout bank account on seller profile.
- **User Dashboard** — "My Mazad": active bids, watchlist, won items, listings, orders, wallet, ratings.
- **Two-way Rating System** — buyer rates seller and vice versa after order completion.

### 🔨 Bidding & Item Pages
- **Media Gallery** — up to 10 photos + 1 short video (≤60s); zoomable carousel.
- **Verified Video badge** — Gemini Vision watermark verification, search-rank boost.
- **Dynamic Countdown** — realtime synced to `current_close_at`, with clear "Discovery ends in" vs "Smart Close: ends 12h after last bid".
- **One-tap Bid Console** — `+ min`, `+ 2x`, `+ 5x`, `Buy Now`, `Set max bid`.
- **Proxy Bidding** — user sets a max; system auto-bids.
- **Live Activity Feed** — pseudonymized bidders (e.g. "bidder_4f2a") + city.
- **Comprehensive Specs** — category-specific schemas: condition, dimensions, weight, provenance.

### 🔍 Discovery & Personalization
- **Search** — Postgres full-text (`tsvector` + `pg_trgm` + `unaccent`) across all 4 locales of title/description.
- **Granular Filters** — category, price range, ending soon, distance, condition, has-video, has-buy-now.
- **Watchlists** — push + SMS alerts on bid/ending/won.
- **Personalized Feed** — Phase 1 rule-based (categories + watched sellers); Phase 2 `pgvector` similarity.

### 💰 Transaction Management
- **Escrow** — platform wallet holds digital-wallet payments; 48h post-delivery release; seller-float for COD.
- **Invoice Generator** — Edge Function renders 4-language PDF with hammer + buyer premium + delivery + platform fee.
- **Shipping Hub** — Phase 1 seller-arranged with tracking input; Phase 2 courier API integration.
- **Dispute Center** — in-app form → freezes payout → admin queue → 72h resolution target.

### 🔔 System Administration
- **Moderation Panel** — Next.js admin: flagged listings, video review, takedown.
- **Fee Engine** — `fee_rules` table; configurable per-category from admin without code deploys.
- **Notification Dispatcher** — Push (FCM), SMS (Twilio/Vonage), Email (Resend), WhatsApp (deferred). Single `notifications` row fans out per user preferences.

---

## 3. Product Surfaces

| Surface | Description | Priority |
|---|---|---|
| Home / Discover | Live now, Hot, Group Bazaar, Categories, Personalized | P0 |
| Search / Browse | Autocomplete, filter sidebar, results grid | P0 |
| Listing Detail | Media, specs, bid feed, console, watch toggle, share | P0 |
| Create Listing | AI co-pilot multi-step | P0 |
| My Mazad | Bids, watchlist, wins, listings, orders, wallet, ratings | P0 |
| Seller Mode | Inventory, analytics, payout, float | P0 |
| Admin Console | Moderation, disputes, payouts, KYC, fee config (Next.js) | P1 |

---

## 4. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Client | **Flutter 3.x** | Single codebase, RTL support, mature SDKs |
| State | **Riverpod 2** + code-gen | Type-safe |
| Routing | **GoRouter** | Deep links, web URLs |
| Backend | **Supabase** (Postgres + Auth + Realtime + Storage + Edge Functions) | Familiar |
| Realtime | Supabase Realtime | Bid feeds, watchlists |
| Bid writes | Postgres RPC with `SELECT FOR UPDATE` | Atomic |
| Scheduled jobs | `pg_cron` + Edge Functions | Smart Close, dispatch |
| AI | **Gemini 2.x** (vision + text) | Trilingual listings, video verification |
| Search | Postgres `tsvector` + `pg_trgm` + `unaccent` | No extra infra |
| Push | **Firebase Cloud Messaging** | Standard |
| SMS | Twilio Verify / Vonage | Phone OTP + bid alerts |
| Email | Resend | Receipts, low-volume |
| WhatsApp (deferred) | Meta Cloud API / Twilio | Behind feature flag |
| Maps | Mapbox | Delivery zones |
| Video | FFmpeg Edge Function + Supabase Storage | Watermark, keyframes |
| Invoices (PDF) | `pdf-lib` or puppeteer in Edge Function | Multi-locale receipts |
| Analytics | PostHog | Funnels, feature flags |
| Error tracking | Sentry | Standard |
| Admin console | Next.js on Vercel | Familiar |

---

## 5. Data Model

`bigint` for IQD. `uuid` PKs. RLS default-deny on every table.

```sql
-- ─── Identity & profiles ─────────────────────────────────────────────
profiles
  id uuid pk (fk auth.users), display_name, pseudonym, avatar_url,
  phone, locale check (locale in ('en','ar','ku','tr')),
  city, kyc_tier int (0|1|2), trust_score numeric,
  whatsapp_phone, whatsapp_opt_in bool, sms_opt_in bool, email,
  notification_prefs jsonb, created_at, last_active_at

seller_profiles
  user_id pk, business_name, id_doc_url, address, payout_method,
  payout_account jsonb, float_balance bigint, verified_at,
  total_sold bigint, dispute_count int

-- ─── Catalog ─────────────────────────────────────────────────────────
categories
  id, slug, parent_id,
  name_translations jsonb,  -- {en, ar, ku, tr}
  spec_schema jsonb

listings
  id, seller_id, type ('auction'|'fixed'|'bazaar'),
  title_translations jsonb,        -- {en, ar, ku, tr}
  description_translations jsonb,  -- {en, ar, ku, tr}
  category_id, condition, specs jsonb,
  images jsonb, video_url, video_verified bool, video_verification_meta jsonb,
  location jsonb {city, lat, lng},
  status ('draft'|'pending_review'|'active'|'sold'|'expired'|'cancelled'),
  starting_price bigint, buy_now_price bigint, reserve_price bigint,
  currency text default 'IQD',
  -- Smart Close fields
  discovery_ends_at timestamptz,        -- publish + 48h (24h bazaar)
  smart_close_window interval default '12 hours',  -- 6h bazaar
  current_close_at timestamptz,
  hard_close_at timestamptz,            -- publish + 14d
  current_high bigint, current_high_bidder_id uuid,
  bid_count int default 0,
  watch_count int default 0,
  view_count int default 0,
  search_vector tsvector,
  created_at, published_at,
  check (title_translations ?| array['en','ar','ku','tr'])

-- ─── Bidding ─────────────────────────────────────────────────────────
bids
  id, listing_id, bidder_id, amount bigint, max_amount bigint,
  source ('app'|'web'|'whatsapp'), is_proxy bool,
  status ('valid'|'retracted'|'rejected'),
  ip_hash, device_id, created_at

watches
  user_id, listing_id pk(composite),
  notify_channels jsonb {push, sms, whatsapp, email},
  created_at

-- ─── Group Bazaar ────────────────────────────────────────────────────
group_deals
  id, listing_id, tiers jsonb,  -- [{participants, price}]
  current_participants int, current_tier_index int,
  floor_price bigint, expires_at

deal_signups
  deal_id, user_id pk(composite), signed_up_at, committed bool

-- ─── Orders, payments, shipping ──────────────────────────────────────
orders
  id, buyer_id, seller_id, listing_id,
  hammer_price bigint, buyer_premium bigint, platform_fee bigint,
  delivery_fee bigint, total bigint,
  status ('pending'|'paid'|'shipped'|'delivered'|'released'|'refunded'|'disputed'),
  payment_method, shipping_address jsonb, invoice_url,
  created_at, paid_at, shipped_at, delivered_at, released_at

payments
  id, order_id, provider ('zaincash'|'fastpay'|'fib'|'cod'),
  provider_ref, status, amount bigint, captured_at

shipments
  id, order_id, courier, tracking_ref, label_url,
  cost bigint, status, dispatched_at, delivered_at

-- ─── Reputation & trust ──────────────────────────────────────────────
reviews
  id, order_id, reviewer_id, reviewee_id,
  rating int (1-5), comment, created_at

vouches
  voucher_id, vouchee_id pk(composite), weight numeric, created_at

disputes
  id, order_id, raised_by, reason, evidence_urls jsonb,
  status, resolution, assigned_to, created_at, resolved_at

-- ─── Notifications (multi-channel, 4-language) ───────────────────────
notification_templates
  id, kind, locale check (locale in ('en','ar','ku','tr')),
  channel check (channel in ('push','sms','email','whatsapp')),
  subject, body, variables jsonb,
  unique(kind, locale, channel)

notifications
  id, user_id, kind, payload jsonb, channels jsonb,
  push_sent_at, sms_sent_at, whatsapp_sent_at, email_sent_at,
  read_at, created_at

-- ─── WhatsApp (deferred but schema ready) ────────────────────────────
whatsapp_threads
  id, user_id, phone, active_listing_id, last_message_at

whatsapp_messages
  id, thread_id, direction, body, intent, processed_at

-- ─── Fee engine ──────────────────────────────────────────────────────
fee_rules
  id, scope ('global'|'category'|'seller'), scope_id,
  listing_fee bigint, success_fee_pct numeric,
  buyer_premium_pct numeric, active_from, active_until

-- ─── App version gating (see auto-update skill) ──────────────────────
app_versions
  id, platform ('ios'|'android'|'web'),
  current_version, min_supported_version,
  release_notes_translations jsonb,  -- {en, ar, ku, tr}
  released_at, updated_at, unique(platform)

-- ─── Audit ───────────────────────────────────────────────────────────
audit_logs
  actor_id, action, target, metadata jsonb, at
```

**Key invariants enforced in DB:**
- Bids only via `place_bid()` RPC (RLS denies direct INSERT).
- `place_bid()` uses `SELECT ... FOR UPDATE` for atomic validation.
- `current_close_at` updates inside the same transaction.
- `pg_cron` job sweeps `current_close_at <= now()` every 60s.
- Sellers cannot bid on their own listings.
- Bazaar listings cap at 10,000 IQD (CHECK constraint).
- Listings must have at least one non-null title locale (CHECK constraint).

---

## 6. Key Flows

### 6.1 Placing a bid

```sql
create or replace function place_bid(
  p_listing_id uuid,
  p_amount bigint,
  p_max_amount bigint default null,
  p_source text default 'app'
) returns bids as $$
declare
  v_listing listings%rowtype;
  v_bid bids%rowtype;
  v_min_increment bigint;
  v_current bigint;
begin
  select * into v_listing from listings where id = p_listing_id for update;

  if v_listing.status != 'active' then raise exception 'listing_not_active'; end if;
  if now() >= v_listing.current_close_at then raise exception 'listing_closed'; end if;
  if auth.uid() = v_listing.seller_id then raise exception 'self_bid_forbidden'; end if;

  v_current := coalesce(v_listing.current_high, v_listing.starting_price);
  v_min_increment := greatest(1000, (v_current * 5) / 100);

  if p_amount < v_current + v_min_increment then raise exception 'bid_too_low'; end if;

  insert into bids (listing_id, bidder_id, amount, max_amount, source)
  values (p_listing_id, auth.uid(), p_amount, p_max_amount, p_source)
  returning * into v_bid;

  update listings set
    current_high = p_amount,
    current_high_bidder_id = auth.uid(),
    bid_count = bid_count + 1,
    current_close_at = case
      when now() < discovery_ends_at then discovery_ends_at
      else least(now() + smart_close_window, hard_close_at)
    end
  where id = p_listing_id;

  return v_bid;
end;
$$ language plpgsql security definer;
```

A trigger handles **proxy bidding**: after a successful bid, find other valid bids with `max_amount > new_high + min_increment` and auto-place the next bid.

### 6.2 Smart Close lifecycle

- Publish → `discovery_ends_at = now() + 48h` (24h bazaar), `current_close_at = discovery_ends_at`, `hard_close_at = now() + 14d`.
- Bid during discovery → `current_close_at` stays = `discovery_ends_at`.
- Bid after discovery → `current_close_at = now() + 12h` (6h bazaar), capped at `hard_close_at`.
- `pg_cron` every 60s closes listings where `current_close_at <= now()`.
- Edge Function `close_listing()` validates reserve, marks `sold`, creates order, sends multi-channel notifications in all 4 locales.

### 6.3 Verified Video

1. Seller records 30–60s video in-app; watermark with listing ID + timestamp overlaid before upload.
2. Edge Function `verify_video(listing_id, video_url)`:
   - Extracts 5 keyframes via FFmpeg.
   - Calls Gemini Vision: "Does this frame contain `LST-{id_short}` watermark? Item visible? Matches photos?"
   - ≥3 frames pass → `video_verified = true`.
   - Fail → manual review queue.
3. Verified Video badge in search results and detail. Search-rank boost.

### 6.4 Multi-channel notification dispatch

`notifications` row written by triggers on bid/order events. Worker reads, checks user preferences, dispatches to enabled channels:

- **Push** (FCM): always for opted-in.
- **SMS** (Twilio/Vonage): high-value events (outbid on auction ≥ 50k IQD, won/lost, shipped, dispute). Sparingly — cost.
- **Email** (Resend): receipts, dispute updates, weekly summary.
- **WhatsApp** (deferred): code path exists, gated by `feature_flag('whatsapp_notifications')`.

Each `(kind, locale, channel)` template stored in `notification_templates`. Dispatcher renders user's locale.

### 6.5 AI Listing Co-pilot

1. Seller picks 3+ photos.
2. App calls `analyze_item(images)` Edge Function → Gemini Vision returns:

```json
{
  "category_id": "phones-smartphones",
  "title": { "en": "...", "ar": "...", "ku": "...", "tr": "..." },
  "description": { "en": "...", "ar": "...", "ku": "...", "tr": "..." },
  "condition": "good",
  "suggested_specs": { "brand": "Samsung", "model": "Galaxy S22", "storage_gb": 128 },
  "suggested_starting_price_iqd": 280000,
  "red_flags": []
}
```

Prompt rules: English concise/factual; Arabic = MSA with Iraqi register; Kurdish = Sorani with proper glyphs (ێ ۆ ڕ ڵ); Turkish = standard Istanbul with diacritics (ç ğ ı İ ö ş ü). Server validates all four locale fields non-empty before returning.

3. Seller reviews, edits, publishes.

### 6.6 Group Bazaar

1. Seller creates bazaar listing (≤10,000 IQD CHECK).
2. Defines tiers: `[{participants: 1, price: 9500}, {participants: 5, price: 8000}, {participants: 10, price: 6500}]`.
3. Buyers tap "I want one" → `deal_signups`.
4. Threshold hit → tier updated, Realtime push.
5. Shareable deep link with OG preview.
6. On `expires_at`: charge all committed signups at unlocked tier, create orders.

### 6.7 Invoice generation

Edge Function `generate_invoice(order_id)` runs on order finalization. Renders PDF (4-locale templates, RTL-aware for AR/KU) via `pdf-lib` or puppeteer. Stores in Supabase Storage; URL on order.

### 6.8 COD with seller float

- Seller has `float_balance` (positive credit).
- Buyer wins COD → courier delivers → cash to courier → courier remits weekly (Phase 1 manual; Phase 2 courier API).
- Platform deducts platform fee + delivery from seller's float per order.
- Negative float → seller blocked from listing high-value items until top-up.
- 48h buyer protection window after delivered; dispute pauses release.

### 6.9 Disputes

Buyer or seller files with reason + evidence → order → `disputed`, payout frozen → admin queue, 72h target → resolution (refund / partial / release / split) → both parties notified.

---

## 7. Internationalization (EN / AR / KU / TR)

| Language | Code | Script | Direction | Numerals |
|---|---|---|---|---|
| English | `en` | Latin | LTR | Western |
| Arabic | `ar` | Arabic | RTL | Western default, Eastern Arabic optional |
| Kurdish (Sorani) | `ku` | Arabic | RTL | Western |
| Turkish | `tr` | Latin | LTR | Western |

- Flutter `intl` with ARB files: `app_en.arb`, `app_ar.arb`, `app_ku.arb`, `app_tr.arb`.
- **RTL by default** for `ar` and `ku`. Mirror icons; use `EdgeInsetsDirectional`.
- UGC fields use JSONB `{en, ar, ku, tr}`. Sellers fill ≥1; AI fills the rest with seller review.
- **Turkish dotted/dotless `i` rule**: system-level case ops pinned to `en_US`. See `.claude/skills/i18n-rtl/`.
- Currency: see `.claude/skills/money-handling/`.
- Fonts: **Vazirmatn** or **Noto Sans Arabic** for AR/KU (Sorani glyph coverage); **Inter** for EN/TR.
- Search: Postgres `tsvector` + `unaccent` for Turkish diacritics, Arabic vowel marks.
- Turkish text runs ~20% longer than English — overflow audit on every screen.

---

## 8. Trust & Safety

- **KYC tiers** as in §2.
- **Anti-shill detection** on every bid: IP/device cluster patterns, new-account velocity, < 7-day accounts on same-seller items. Flag → manual review → auto-cancel if confirmed.
- **Content moderation**: image+video hash blacklist + Gemini classifier for prohibited categories (weapons, drugs, counterfeit, adult). Auto-reject high-confidence; queue ambiguous; user-reportable.
- **Reputation**: weighted (completed orders, avg rating, dispute rate, account age, vouches).
- **Pseudonyms** in public bid feeds: `bidder_4f2a` + city.

---

## 9. Payments & Escrow

| Method | MVP? | Notes |
|---|---|---|
| **ZainCash** | Yes | Most common Iraqi wallet |
| **FastPay** | Yes | Second-most common |
| **COD (seller float)** | Yes | Dominant in Iraq |
| **AsiaHawala** | Phase 2 | Common in KRI |
| **FIB / Switch (card)** | Phase 2 | Lower volume |
| **Qi Card** | Phase 2 | Gov payroll |

**Fee engine** is data-driven via `fee_rules`. Default at launch: 7% success fee from seller, 0% buyer premium, 0 listing fee. Buyer premium enablable later for premium auctions.

**Escrow**: digital-wallet payments held in platform wallet; released 48h post-delivery. COD uses seller-float.

---

## 10. WhatsApp-Ready Architecture (deferred)

Schema, dispatch worker, and inbound webhook scaffold built but **feature-flagged off**.

To activate when Meta API access lands:
1. Add BSP credentials.
2. Pre-approve template messages in Meta Business Manager (4 languages × ~10 templates).
3. Flip `whatsapp_notifications` feature flag.
4. Enable webhook route.
5. Roll out to opted-in users.

~1–2 days of work plus Meta approval timeline.

---

## 11. Phased Build Plan

Run each phase in a fresh Claude Code session. Review and commit between phases.

### Phase 0 — Repo + infra (1–2 days)
> Set up a Flutter 3.x monorepo for "Mazad" targeting iOS, Android, Web. Use Riverpod 2 with code-gen, GoRouter, Supabase Flutter client, flutter_intl with ARB files for **en/ar/ku/tr** (RTL by default for ar/ku, LTR for en/tr). Add Sentry, FCM, PostHog. Create `supabase/` with migrations and Edge Functions structure. Provide a `justfile` with: `dev`, `build:web`, `build:android`, `build:ios`, `db:migrate`, `db:reset`, `functions:deploy`. Apply the Postgres schema from §5 as the initial migration. RLS default-deny on every table. Add feature flag table and helper `feature_flag(name)`. **Per the `auto-update` skill, also create `app_versions` table, `_shared/version_check.ts` middleware, `VersionInterceptor`, and a placeholder `ForceUpdateScreen` translated in all 4 locales.**

**Acceptance**: app boots on web + iOS sim + Android emulator. Locale switches between en/ar/ku/tr; RTL flips for ar/ku. Supabase connects. Migrations clean. Version interceptor adds `App-Version` and `App-Platform` headers; force-update screen renders.

### Phase 1 — Auth, profiles, KYC (3–4 days)
> Implement unified phone-OTP signup via Supabase Auth + Twilio Verify. Tier 0 default. Profile setup (display name, locale, city). "Start selling" upgrade → Tier 2 KYC (ID upload, address, payout account). Tier 1 auto-granted on phone verification. "My Mazad" dashboard skeleton: My Bids, Watchlist, Wins, My Listings, Orders, Wallet, Ratings. Pseudonym auto-generated on signup.

**Acceptance**: user signs up, sees Tier 1 access, upgrades to seller, completes Tier 2 KYC. All 4 locales.

### Phase 2 — Listings + AI Co-pilot (4–5 days)
> Implement listing creation for all three types (auction, fixed, bazaar with 10k IQD CHECK). Multi-step UI: photos → AI co-pilot → review → publish. Build Edge Function `analyze_item(images)` calling Gemini Vision per §6.5, returning 4-language title/description, suggested price, specs, red flags. **Validate all four locale strings are non-empty before returning.** Categories with `spec_schema` JSONB drive dynamic spec fields. Category browse + search (Postgres `tsvector` + `pg_trgm` + `unaccent`). Home feed sections: Ending Soon, Hot, Group Bazaar, Categories. RLS: anyone reads active listings, only seller updates own.

**Acceptance**: seller uploads 3 photos → AI-generated 4-language draft → edits → publishes. Buyer browses, searches with typos and Turkish diacritics, filters. Listings render in all 4 locales.

### Phase 3 — Bidding engine + Smart Close (4–5 days)
> Implement `place_bid()` exactly per §6.1. Smart Close: 48h discovery (24h bazaar), 12h-from-last-bid (6h bazaar), 14d hard cap. `pg_cron` close job per §6.2. Proxy bidding via trigger. Listing detail screen with realtime bid feed (Supabase Realtime), one-tap bid console, pseudonymized activity feed. **Integration tests: 50 concurrent bidders → exactly one winner; Smart Close timer correct; proxy bidding auto-bids correctly; sniping fails (auction extends).**

**Acceptance**: bid integrity correct under concurrency; UI countdown synced.

### Phase 4 — Verified Video + Media (3–4 days)
> In-app video recording (≤60s, watermark overlay with listing ID + timestamp) and upload. Edge Function `verify_video(listing_id)` per §6.3. Media gallery on listing detail (zoomable photos + inline video). Verified Video badge on cards and detail. Failed verifications → admin queue.

**Acceptance**: seller records and uploads, verification runs, badge appears (or queued). Buyers see badge in search and detail.

### Phase 5 — Watches, notifications, multi-channel dispatch (3–4 days)
> Watchlists (`watches` table). Notification dispatcher: triggers write to `notifications`; worker fans out per user prefs. Integrate FCM (push), Twilio/Vonage (SMS), Resend (email). Templates in `notification_templates` keyed by `(kind, locale, channel)` with **4 locales per template**. User settings for per-kind, per-channel prefs. SMS rate limiting + high-value threshold. **Implement WhatsApp dispatch path code with feature flag gate (`whatsapp_notifications`), but leave flag OFF.** Watchlist screen + "Ending Soon for You" feed.

**Acceptance**: notifications arrive on Push + SMS + Email per prefs; WhatsApp code path exists but disabled.

### Phase 6 — Group Bazaar (2–3 days)
> Implement per §6.6. Tier definition UI for seller. "I want one" signup, realtime price-drop, social share with rich OG preview. On `expires_at`, charge all committed at unlocked tier and create orders.

**Acceptance**: bazaar listing attracts signups, drops via Realtime, share works, orders generate.

### Phase 7 — Orders, payments, escrow, invoices (5–7 days)
> Integrate ZainCash + FastPay. Order lifecycle (pending → paid → shipped → delivered → released) with 48h escrow. Seller float for COD per §6.8. Order screens, post-delivery rating, dispute filing. `generate_invoice(order_id)` Edge Function producing 4-locale RTL-aware PDF. Admin endpoints for dispute resolution, payout management, float top-ups. Fee engine per §9.

**Acceptance**: end-to-end via ZainCash and COD; escrow releases; invoices download in user's locale; disputes file/resolve.

### Phase 8 — Vouches + Reputation (2–3 days)
> Optional contact sync (explicit consent, server-side hash matching only). Surface "vouched by N of your contacts." Vouching action; weight decays over 12 months. Reputation = weighted blend; surface on profile.

**Acceptance**: contact-synced users see vouches from network; reputation reflects activity.

### Phase 9 — Admin console, analytics, polish (5–7 days)
> Next.js admin console on Vercel using service role. Surfaces: moderation queue, video verification review, dispute resolution, payouts, KYC, fee rules, feature flags, analytics dashboards (GMV, sellers, conversion, watch-to-bid, dispute rate). PostHog events throughout Flutter: `signup`, `kyc_upgraded`, `listing_created`, `video_uploaded`, `bid_placed` (with source), `order_completed`, `dispute_raised`, `share_clicked`. **Full RTL audit + Turkish-text-overflow audit in all 4 locales.**

**Acceptance**: ops can run the business from console; PostHog funnels populate; RTL+Turkish audit passes.

### Phase 10 (deferred) — WhatsApp activation (1–2 days when ready)
> When Meta API access granted: add BSP credentials, register pre-approved templates in 4 locales (~10 templates), flip `whatsapp_notifications` flag on, enable webhook route, monitor `whatsapp_messages` for intent parsing failures.

**Acceptance**: opted-in users receive WhatsApp notifications and bid via reply messages.

---

## 12. What's intentionally cut from MVP

- Live video / live commerce — TikTok and Instagram Live own it in Iraq.
- Card payments (FIB, Switch) — Phase 2.
- Multi-currency — IQD only.
- In-app chat between buyer and seller — invites scams.
- Real-time courier label generation — Phase 2.
- Buyer premium — 0% at launch; enable later for premium auctions.

---

## 13. Open questions

1. Name and domain. Check Iraqi trademark register.
2. Sorani only for Kurdish (confirmed: no Kurmanji at MVP).
3. Launch categories — go narrow (phones, fashion, collectibles, home goods).
4. First sellers — Founding Sellers program with reduced fees for first 50.
5. Smart Close window calibration — A/B test 8h vs 12h vs 24h after volume.
6. SMS provider — compare Twilio vs Vonage vs regional per-message cost on Iraqi numbers.
7. WhatsApp BSP choice when ready — Twilio vs Meta Cloud API direct.
8. Buyer premium — default 0%; enable later for premium-category auctions.

---

*Apply changes to this document as decisions are made and learnings accumulate. Expect revisions in week 1.*
