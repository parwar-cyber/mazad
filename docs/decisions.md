# Architecture Decision Records (ADRs)

Append-only. Each decision gets a numbered entry. Never edit historical entries — supersede with a new one.

---

## ADR-0001: Stack lock-in (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

**Context**: Need to commit to a single stack before scaffolding. Spec already names choices; this ADR records the lock so reviewers don't relitigate.

**Decision**:
- **Client**: Flutter 3.x, Dart 3.x, Riverpod 2 (with `riverpod_generator`), GoRouter, `flutter_localizations` + ARB files.
- **HTTP**: Supabase Dart client for backend; `dio` only for external APIs (and to host the `VersionInterceptor` for non-Supabase calls).
- **Backend**: Supabase (Postgres + Auth + Realtime + Storage + Edge Functions on Deno).
- **Observability**: Sentry (errors) + PostHog (analytics, feature flags client-side).
- **Push**: Firebase Cloud Messaging via `firebase_messaging` (added in Phase 5; deps deferred).
- **Admin console**: Next.js on Vercel (placeholder folder only at Phase 0).

**Alternatives considered**: React Native (rejected — weaker RTL story, two codegen toolchains), Firebase backend (rejected — weaker SQL/RLS story for an auction app with strict bid invariants).

---

## ADR-0002: Money handling (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

All IQD amounts are integers — `bigint` in Postgres, `int` in Dart, `bigint` in TypeScript. No `double`, `decimal`, `numeric`, or JS `Number` anywhere in the money path. Formatting only via `core/money/formatIQD`. See `.claude/skills/money-handling/SKILL.md`.

---

## ADR-0003: Internationalization & RTL (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Four launch locales: `en`, `ar`, `ku`, `tr`. `ar` and `ku` are RTL. ARB files for all static strings; UGC stored as JSONB `{en, ar, ku, tr}`. System-level case operations (slugs, search normalization, uniqueness checks) pinned to `en_US` to avoid the Turkish dotted/dotless `i` bug. See `.claude/skills/i18n-rtl/SKILL.md`.

---

## ADR-0004: Backend version-gating (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Every Edge Function calls `checkAppVersion(req)` first. Flutter client sends `App-Version` + `App-Platform` headers via `VersionInterceptor` (Dio) and `headers` option on the Supabase client. Server responds 426 if `App-Version < min_supported_version`. Client renders blocking `ForceUpdateScreen`. Shorebird and platform prompts layer on later (Phase 5 / Phase 9). See `.claude/skills/auto-update/SKILL.md`.

---

## ADR-0005: Design tokens — "Tigris" palette (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

**Context**: `frontend-design` skill demands distinctive, non-AI-default choices. Default Material 3 baseline (purple/teal) feels generic; pure Iraqi-flag green/red feels touristic. Tested several palettes in the splash + force-update screens.

**Decision**: Dark-first "Tigris" palette.

| Token | Dark | Light |
|---|---|---|
| `primary` | `#D4A04C` (warm muted gold) | `#A87A2C` |
| `onPrimary` | `#0E1116` | `#FFFBF2` |
| `background` | `#0E1116` (near-black, faint blue cast) | `#FBF8F2` (warm paper) |
| `surface` | `#171B22` | `#FFFFFF` |
| `onSurface` | `#EDE6D6` | `#1A1614` |
| `outline` | `#2A2F38` | `#D9D4C7` |
| `success` | `#5BA98F` (muted teal — "bid up") | same |
| `error` | `#E04E3D` (warm crimson — "outbid") | same |
| `info` | `#7DA9D8` (cool slate blue) | same |

**Typography**:
- Latin (en/tr): **Inter** — body 400, headings 700, display has `-0.02em` letter-spacing.
- Arabic-script (ar/ku): **Vazirmatn** (covers Sorani glyphs).
- Numeric values (prices, bids, countdowns): tabular figures (`FontFeature.tabularFigures()`).

**Why**:
- Gold + near-black evokes auction/value without screaming "Iraq souk."
- Muted teal for "going up" reads safer than green-vs-red colorblind clash.
- Tabular figures eliminate price jitter in live bid feeds.

**Tokens live in**: `app/lib/core/design/tokens.dart`. **Never inline** colors, spacing, or font sizes.

---

## ADR-0006: Dependency policy (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Every new Dart or npm dependency is a security surface and a maintenance cost. Before adding one:
1. Confirm it's needed (not just convenient).
2. Add to this file with a one-line justification.
3. Pin a version.

Phase 0 dependencies (Flutter app):

| Package | Why |
|---|---|
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | State management (ADR-0001) |
| `go_router` | Routing (ADR-0001) |
| `supabase_flutter` | Backend client (ADR-0001) |
| `dio` | External HTTP + host for `VersionInterceptor` |
| `package_info_plus` | Reads installed app version for `App-Version` header |
| `intl` | Locale-aware number/date formatting |
| `flutter_localizations` (SDK) | ARB-driven `AppLocalizations` |
| `google_fonts` | Inter + Vazirmatn at runtime (acceptable for Phase 0; bundle fonts as a Phase 9 polish task) |
| `url_launcher` | Open App Store / Play Store from `ForceUpdateScreen` |
| `build_runner` (dev) | Code generation for Riverpod |
| `flutter_lints` (dev) | Lints |

Deferred to later phases (do **not** install at Phase 0): `sentry_flutter`, `firebase_messaging`, `posthog_flutter`, `cached_network_image`, `mapbox_gl`, `in_app_update`, `shorebird_code_push`.

---

## ADR-0007: Phone-OTP signup via Supabase Auth + Twilio Verify (Phase 1)

**Date**: 2026-05-13
**Status**: Accepted

**Context**: Phase 1 needs phone-OTP signup. Two integration paths exist:
(a) Supabase Auth's native Twilio Verify provider — `signInWithOtp` and
`verifyOtp` on the Flutter client, Twilio creds configured in
`supabase/config.toml`; or (b) hand-rolled Edge Functions wrapping
Twilio's API directly.

**Decision**: Use Supabase Auth's native Twilio Verify provider. The
Flutter app calls `auth.signInWithOtp(phone:)` and `auth.verifyOTP(...)`
directly. No custom Edge Function for OTP send/verify.

**Why**:
- Single source of truth for the session token.
- Built-in per-phone rate limits (`max_frequency`, daily caps) without
  re-implementing a hot-path rate-limit table.
- Profile bootstrap is a Postgres trigger on `auth.users` — no Edge
  Function indirection.

**Trade-offs / consequences**:
- The OTP send/verify endpoints DON'T go through our `checkAppVersion`
  middleware (they're Supabase-managed). The first business RPC after
  sign-in (`update_profile`, `submit_kyc_tier2`, etc.) will catch a stale
  client via the 426 gate. This is acceptable for the security model:
  the OTP endpoint can't damage user funds, and the version gate fires
  before any money-touching call. This deliberate gap is mitigated by
  the fact that the first business RPC after signup catches stale clients.
- If we later want CLAUDE.md's stricter `3/hour, 10/day` per phone, we'll
  need a DB-side OTP-log table fed by a webhook from Supabase Auth.
  Captured as a refactor TODO.

**Dependency added (per ADR-0006)**:

| Package | Why |
|---|---|
| `image_picker` | KYC ID document capture from camera or gallery. Used only on the `kyc/id` step; not loaded elsewhere. |

---

## ADR-0008: KYC Tier 2 auto-grant at submission (Phase 1)

**Date**: 2026-05-13
**Status**: Accepted (transitional — see consequences)

**Context**: Architecture.md §11 acceptance for Phase 1 reads "user signs
up, sees Tier 1 access, upgrades to seller, completes Tier 2 KYC." The
admin review workflow (manual approval queue, KYC ops dashboard) lands
in Phase 9. Phase 1 needs a working end-to-end path before that exists.

**Decision**: `submit_kyc_tier2()` auto-bumps `profiles.kyc_tier` to 2
and sets `seller_profiles.verified_at = now()` on successful submission.
The full audit trail (path-checked ID doc in private bucket, audit_logs
entry, seller_profiles row with submission details) is captured so the
Phase 9 admin console can retroactively validate, suspend, or
re-classify any auto-granted seller.

**Consequences**:
- Phase 1 launches with effectively zero KYC gating — anyone with a
  verified phone can become a seller. Mitigations:
  1. Tier 2 actions (creating listings, accepting orders) don't ship
     until Phase 2 and Phase 7. We have time before fraud is exploitable.
  2. The fraud surface is "fake seller absconds with buyer payment."
     Escrow (Phase 7) holds buyer payments until delivery — the seller
     never touches funds before review.
  3. Audit-log trail means any tier-2 user can be flipped back to tier-1
     from the admin console without data loss.
- **Hard gate enforced in DB**: feature flag `phase7_escrow_enabled`
  (created in migration `20260513000004_phase1_phase7_gate_flag.sql`,
  default `false`). Phase 7 wiring will read this flag and refuse to
  operate until it is flipped on. The flip is tied to Phase 9 admin
  review-queue readiness — a single conscious decision, not a silent
  code-deploy event.

**Supersedes**: nothing.

---

## ADR-0009: Pseudonym format `bidder_<6 hex chars>` (Phase 1)

**Date**: 2026-05-13
**Status**: Accepted

**Context**: Bid feeds (Phase 3) and notification surfaces (Phase 5) need
a public identifier for users that doesn't leak the display name or
phone. Architecture.md §2 shows the format `bidder_4f2a`.

**Decision**: `bidder_` followed by exactly 6 lowercase hex characters
(3 random bytes encoded). 16M possible handles. Collision retry up to
3 attempts in `generate_pseudonym()`; persistent collision raises an
error rather than expanding the namespace, because: collisions at our
expected user count are vanishingly rare, and silent format drift would
break downstream regex consumers (notification templates, deep links).

**Why these choices**:
- Hex (vs base32 / numeric) keeps the format trivially regex-matchable
  (`^bidder_[0-9a-f]{6}$`) for parsers in any language.
- 6 chars (not 4 as in the spec example) gives ~16M-space — well past
  the birthday-paradox knee for our projected scale.
- Lowercase only — system-field-style normalization (pinned to en_US,
  see ADR-0003).

---

## ADR-0010: Listing tier gating — Tier 1 for fixed/bazaar, Tier 2 for auction (Phase 2)

**Date**: 2026-05-14
**Status**: Accepted

**Context**: CLAUDE.md and architecture.md §2 describe three KYC tiers but
don't pin down the per-listing-type gate. Phase 2 needs an explicit rule:
who is allowed to create which listing type?

**Decision**:
- Tier 0 (browse only): cannot create any listing.
- Tier 1 (verified buyer, phone-OTP): may create `fixed` and `bazaar`
  drafts and publish them.
- Tier 2 (full KYC, ID + payout): all three types — adds `auction`.

Enforced in `create_listing_draft` and re-enforced in `publish_listing`
(in case the seller's tier was downgraded between draft and publish).

**Why**:
- Fixed-price and bazaar listings carry less fraud surface than auctions —
  no proxy bidding, no time-pressure manipulation, no shill bid risk. A
  phone-verified user is allowed to test the seller path with a small
  buy-now item before committing to full KYC for high-value auctions.
- The hard money invariant (escrow holding buyer funds until delivery,
  Phase 7) still applies — sellers never touch funds before review.
- Aligns with "anyone with a verified phone can browse and bid up to
  100k IQD" (Tier 1 ceiling per ADR-0008 / migration 20260513000001).

**Consequences**:
- The listing-type picker disables `auction` for Tier 1 users with an
  inline hint to upgrade. The server still defends with the named
  `kyc_tier_2_required` error.
- Tier 1 fixed/bazaar listings cap at the buyer-side Tier 1 ceiling
  through transaction limits in Phase 7 — not enforced at listing time.

---

## ADR-0011: AI Listing Co-pilot — server-only image fetch (Phase 2)

**Date**: 2026-05-14
**Status**: Accepted

**Context**: The AI Co-pilot needs to feed seller photos to Gemini Vision.
Two integration paths:

(a) Client posts public image URLs to the Edge Function; the function
    forwards them to Gemini directly via `file_data` references.
(b) Client posts only the `listing_id`; the Edge Function reads the
    listing row, validates each path begins with `<seller>/<listing_id>/`,
    constructs the public Supabase storage URL, fetches each image
    server-side, and sends them to Gemini as `inline_data`.

**Decision**: Option (b).

**Why (vibesec skill)**:
- The function is now incapable of being weaponized as an SSRF probe.
  Even if the client lies about which paths are on the listing, the
  server reads the truth from the DB row and re-checks the prefix.
- The 4-locale validation runs server-side over a known-shape response.
  No locale gap can slip through to the client.
- Gemini never sees a URL that isn't inside our own bucket, under the
  seller's own folder — so a future change that adds private listings
  doesn't accidentally surface their photos to a third-party fetcher.

**Trade-offs**:
- Higher Edge Function memory pressure (we base64 each image once).
  Mitigated by the 5-image cap and the 4 MB per-photo client cap (8 MB
  hard cap on the server side).
- One extra DB hit per analyze call. Acceptable — analyze is a low-rate,
  high-value operation.

---

## ADR-0012: Sell-flow KYC gate — listing creation, NOT KYC upgrade (Phase 2)

**Date**: 2026-05-14
**Status**: Accepted

**Context**: The "My Mazad" dashboard had a "Start selling" CTA in Phase 1
that routed Tier-0 users into `/kyc`. With Phase 2, a Tier-1 user can list
buy-now items — they don't need Tier 2 to start selling at all.

**Decision**:
- Dashboard "Listings" tab for Tier 1+ shows the user's listings plus a
  primary "Sell" FAB that goes to `/sell` (the listing-type picker).
- The `/kyc` flow remains the path for upgrading to Tier 2 — the listing
  type picker surfaces a locked auction card with a hint to upgrade, not
  an automatic redirect.

**Why**: A locked CTA with an explanation beats a silent redirect. Users
who want to list a buy-now item shouldn't be forced through ID-document
upload they don't need.

**Cross-reference**: ADR-0010 (tier gating) is the policy this UX encodes.

---

## Open refactor TODOs

- Bundle Inter + Vazirmatn as repo assets instead of `google_fonts` runtime fetch — improves cold-start, removes external dependency at boot. Phase 9 polish task.
- Consider replacing Dio's `VersionInterceptor` with a Supabase-only client interceptor once all backend calls go through Edge Functions (no external Dio surface remains).
- **Scheduled for Phase 5** (notifications phase — adjacent infra): hook a Supabase Auth webhook into a DB-side OTP log to enforce CLAUDE.md's stricter `3/hour, 10/day per phone` cap. Today only `max_frequency = 1m` at the Supabase layer is enforced. Owned in-house — don't wait on Supabase support; the webhook pattern is well-documented and the half-day cost beats a third-party dependency on the launch timeline.
- KYC admin queue + manual approval workflow — required before Phase 7 escrow goes live. See ADR-0008.
- `profiles.theme_mode` column + light/dark/system toggle (was an open design TODO at Phase 0).

---

## Local setup (engineer onboarding)

```bash
# Flutter (FVM recommended)
brew install --cask flutter
flutter --version  # require >= 3.24

# Supabase CLI
brew install supabase/tap/supabase

# Deno (for Edge Functions)
brew install deno

# just (task runner)
brew install just

# Project bootstrap
cd app && flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
cd ../supabase && supabase start && supabase db reset
```
