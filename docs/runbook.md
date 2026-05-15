# Mazad — Runbook

> Operational procedures. Update as we accumulate ops scars.

## The kill switch (force-update every client)

If we ship a broken build and need every client off it:

```sql
update app_versions
   set min_supported_version = '<new-known-good>',
       current_version       = '<new-known-good>',
       updated_at            = now()
 where platform in ('ios', 'android', 'web');
```

Every running client hits 426 on its next API call → renders `ForceUpdateScreen`. Verify in PostHog 5 minutes later that traffic from the bad version has dropped to zero.

Reverse direction (if the bump itself was a mistake):

```sql
update app_versions
   set min_supported_version = '<previous-good>',
       updated_at            = now()
 where platform = '<affected>';
```

## Feature flags

Toggle a flag without code deploy:

```sql
update feature_flags set enabled = true  where name = 'whatsapp_notifications';
update feature_flags set enabled = false where name = 'whatsapp_notifications';
```

(`feature_flags` table + `feature_flag(name)` helper added in migration `..._feature_flags.sql`.)

## Migrations

Filenames: `YYYYMMDDHHMMSS_short_description.sql` (UTC). **Never edit an applied migration in production.** Add a new one.

```bash
just db-migrate   # apply to local
supabase db push --linked   # apply to remote (only after review)
```

## Local development

```bash
just db-up        # supabase start
just db-reset     # drop + re-apply + seed
just dev          # flutter run
```

## Twilio Verify (Phase 1)

Phone-OTP signup uses Supabase Auth's native Twilio Verify provider.
Credentials live in `.env` (never committed) and are referenced in
`supabase/config.toml` as `env(TWILIO_*)`.

| Variable | Where to find it |
|---|---|
| `TWILIO_ACCOUNT_SID` | Twilio Console → Account → API keys & tokens |
| `TWILIO_VERIFY_SID` | Twilio Console → Verify → Services (the `VAxxxxxx` SID) |
| `TWILIO_AUTH_TOKEN` | Twilio Console → Account → API keys & tokens |

If OTPs stop arriving:

1. Check Twilio Console → Verify → Logs for a delivery failure
   (carrier blocking, balance, geo block).
2. Confirm `supabase/config.toml` references the right SIDs; redeploy
   config if changed: `supabase config push`.
3. Failover plan: rotate to Vonage by swapping the provider stanza in
   `[auth.sms]` — credentials path is the same shape; carry the message
   template across.

## KYC documents (Phase 1)

ID documents live in the private `kyc-docs` bucket, under per-user
prefixes (`<user uuid>/...`). Retrieval is via 5-minute signed URLs
issued by the `kyc_doc_url` Edge Function.

**Never log object paths or contents.** The audit trail
(`audit_logs` rows with action `kyc_tier2_submitted`) intentionally
omits the path.

To pull an ID for admin review (Phase 9 will wrap this in a UI):

```ts
// from a service-role context only
const { data } = await admin.storage
  .from('kyc-docs')
  .createSignedUrl('<user-uuid>/<filename>', 300);
```

Bucket policy summary (see `20260513000003_phase1_kyc_docs_bucket.sql`):

- `select/insert/update/delete` allowed only when
  `(storage.foldername(name))[1] = auth.uid()::text`.
- `service_role` bypasses RLS (admin reviewers).
- `public = false` — no CDN URL pattern works.

## Listing photos & analyze_item (Phase 2)

Listing photos live in the public `listing-photos` bucket, under per-user
prefixes (`<seller uuid>/<listing uuid>/...`). Reads use the standard
Supabase public URL pattern.

```
{SUPABASE_URL}/storage/v1/object/public/listing-photos/<seller>/<listing>/<file>
```

Writes are RLS-gated to the path's owner. The bucket is **public-read on
purpose** — browse / search pages need URLs that render without auth.
Do NOT put PII or any seller-internal photos in this bucket.

The `analyze_item` Edge Function (AI Listing Co-pilot) requires the
`GEMINI_API_KEY` secret. Set with:

```bash
supabase secrets set GEMINI_API_KEY=...
```

If analyze_item returns `gemini_not_configured`, the secret is missing.
If it returns `image_fetch_failed`, the seller's photos didn't upload
correctly (check Storage logs; verify the path-prefix).

## Bidding (Phase 3)

### Close sweep — pg_cron, with Edge Function fallback

The primary scheduler is `cron.schedule('mazad_close_listings_sweep',
'* * * * *', ...)` registered by migration
`20260514100001_phase3_bidding_engine.sql`. Verify it's running:

```sql
select jobname, schedule, command
  from cron.job
 where jobname = 'mazad_close_listings_sweep';
```

If `pg_cron` isn't available in a managed Supabase environment, the
`close_listing_sweep` Edge Function is the fallback. Trigger it from an
external scheduler (e.g. GitHub Actions, Cloud Scheduler) every minute:

```bash
curl -X POST \
  -H "X-Admin-Trigger-Token: $ADMIN_TRIGGER_TOKEN" \
  -H "App-Version: 1.0.0" -H "App-Platform: web" \
  https://<project>.supabase.co/functions/v1/close_listing_sweep
```

Set `ADMIN_TRIGGER_TOKEN` as an Edge Function secret. **Do not commit
this token.**

### Bid integrity incident response

If a user reports an auction that closed incorrectly:

1. Pull `audit_logs` rows for the listing —
   `select * from audit_logs where target = '<listing-uuid>' order by at`.
2. Cross-check with the `bids` table — server-recorded amounts are
   authoritative; client-displayed numbers may have been stale.
3. If a duplicate `current_high_bidder_id` ever appears in `listings`,
   that's a place_bid invariant violation. Treat as a sev-1: snapshot
   the row, halt the close sweep with
   `select cron.unschedule('mazad_close_listings_sweep');`, and replay
   the bids in arrival order against a freshly-reset listing to find
   the divergence point before resuming.

### Tuning the proxy-bid iteration cap

Default cap is 20 per user-bid event (ADR-0013). If `bid_count` is
regularly hitting `(user_bids * 22)` in real auctions — i.e. real
chains are being truncated — bump the cap in the migration's
`v_max_proxy_iters` constant and ship a follow-up migration.

## Production hard-gate flip checklist

Before any public launch, flip the following hard-gate flags from their
dev/early-launch defaults to production values:

```sql
-- ADR-0008: Tier 2 KYC admin review queue must be live BEFORE this flip.
update feature_flags set enabled = false where name = 'auto_grant_tier2';

-- ADR-0008: Escrow opens only after the KYC admin queue is live.
update feature_flags set enabled = true  where name = 'phase7_escrow_enabled';
```

Verify in the same session:

```sql
select name, enabled from feature_flags
 where name in ('auto_grant_tier2', 'phase7_escrow_enabled');
```

After the flip, bids on auto-granted (admin-unreviewed) sellers raise
`seller_not_reviewed`. The admin console must show every Tier-2 seller
that needs human review.

## To be expanded as we accumulate ops procedures

- Payment provider outage failover
- Dispute SLA escalation
- SMS provider rotation (Twilio ↔ Vonage)

## Pre-launch checklist

These items must be resolved before any public launch, App Store submission, or paid marketing. Each has a hard gate noted.

### 1. OTP rate limit (per-phone)
- **Status**: Deferred from Phase 1 (ADR-0007). Only Supabase Auth's `max_frequency = 1m` is active.
- **Required**: Per-phone caps of 3 OTPs/hour and 10 OTPs/day enforced via Supabase Auth webhook → `otp_attempts` table → `before_send` Postgres function.
- **Hard gate**: Must be live before public launch. OTP abuse on Iraqi numbers is a real Twilio cost-attack vector.
- **Owner**: Engineering. Schedule in Phase 5 (notifications infrastructure).

### 2. KYC admin review queue
- **Status**: Deferred from Phase 1 (ADR-0008). `submit_kyc_tier2` auto-grants Tier 2 when `feature_flag('auto_grant_tier2')` is on (dev default).
- **Required**: Admin queue in Next.js console (Phase 9) where each Tier 2 submission is reviewed by a human before `verified_at` is set.
- **Hard gate**: `feature_flag('auto_grant_tier2')` must be set to `false` in production. Phase 7 (escrow) MUST NOT open until the queue is live and the flag is off.
- **Owner**: Engineering (queue) + Ops (reviewer process).

### 3. Translation review status
- **Status**: All four locales are AI-generated. Only `en` is native-fluent (the engineer).
- **Required**: Native-speaker review pass on `ar`, `ku`, `tr` ARB files and any UGC AI-translation prompts.
- **Hard gate**: Before any paid marketing or App Store submission. Wrong Sorani in particular will embarrass the brand with KRI users.
- **Estimated cost**: ~$200 each for `ar` and `ku`, ~$150 for `tr` (freelance, one-pass review). Sorani translator hardest to source — start search early.
- **Owner**: Founder.

### 4. Font bundling
- **Status**: Currently using `google_fonts` (runtime CDN fetch). Iraqi networks are patchy; first-launch Arabic/Kurdish users may see Latin fallback while Vazirmatn downloads.
- **Required**: Bundle Inter and Vazirmatn as repo assets, ship in app bundle.
- **Hard gate**: Soft — recommended before public launch but not blocking. Will improve first-launch experience for RTL users.
- **Owner**: Engineering. Schedule in Phase 9 (polish).

### 5. Force-update 426 CORS headers
- **Status**: Deferred from Phase 2. `version_check.ts` returns 426 without CORS headers on the body.
- **Required**: Add CORS headers to the 426 response so Flutter Web clients can read the body and render the force-update screen instead of a generic network error.
- **Hard gate**: Before public web launch.
- **Owner**: Engineering. ~30 min fix.

### 6. Production hard-gate flag flip
- **Status**: Phase 3 added `auto_grant_tier2` defaulted ON; combined with `phase7_escrow_enabled` (off by default), bids are accepted on auto-granted sellers in dev.
- **Required**: Flip `auto_grant_tier2 = false` and `phase7_escrow_enabled = true` as one coordinated migration, gated on the KYC admin review queue going live.
- **Hard gate**: Before any public launch. See "Production hard-gate flip checklist" above.
- **Owner**: Engineering + Ops (review queue must be staffed before the flip).
