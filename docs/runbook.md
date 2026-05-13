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

## To be expanded as we accumulate ops procedures

- Bid integrity incident response
- Payment provider outage failover
- Dispute SLA escalation
- SMS provider rotation (Twilio ↔ Vonage)
