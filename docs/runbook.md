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

## To be expanded as we accumulate ops procedures

- Bid integrity incident response
- Payment provider outage failover
- Dispute SLA escalation
- SMS provider rotation (Twilio ↔ Vonage)
