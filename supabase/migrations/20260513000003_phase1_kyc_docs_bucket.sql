-- ─────────────────────────────────────────────────────────────────────────
-- Phase 1 — kyc-docs private storage bucket.
--
-- Policy: users can read/write objects only under their own UUID prefix
-- ("<auth.uid()>/..."), service_role bypasses RLS automatically and can
-- read everything for admin review.  Retrieval from the client is always
-- via signed URLs with 5-minute expiry — see the `kyc_doc_url` Edge
-- Function — never via direct download.
--
-- File contents and paths must NEVER be logged.  The Edge Function logs
-- only request id / outcome.  The audit_logs table records "kyc_tier2_
-- submitted" without the path (see submit_kyc_tier2 RPC).
-- ─────────────────────────────────────────────────────────────────────────

-- Idempotent bucket creation.  `public = false` means objects are not
-- accessible via the public CDN URL pattern; signed URLs are the only
-- delivery mechanism.
insert into storage.buckets (id, name, public)
values ('kyc-docs', 'kyc-docs', false)
on conflict (id) do nothing;

-- Path-prefix model: storage.objects.name is "<uid>/<filename>".
-- foldername(name)[1] returns the first path segment.
--
-- INSERT: caller can write under their own folder.
create policy "kyc_docs_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'kyc-docs'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- SELECT: caller can list/read objects only under their own folder.
-- service_role bypasses RLS, so the admin console (Phase 9) sees all.
create policy "kyc_docs_owner_select"
  on storage.objects for select
  using (
    bucket_id = 'kyc-docs'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- UPDATE: same scope as SELECT, in case the user re-uploads the same path.
create policy "kyc_docs_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'kyc-docs'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- DELETE: same scope.  Letting the user delete a stale draft is fine;
-- once submit_kyc_tier2 has recorded the path on seller_profiles, the
-- audit trail (audit_logs + seller_profiles.id_doc_url) survives the
-- file deletion.
create policy "kyc_docs_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'kyc-docs'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- (Intentionally no `comment on policy ... on storage.objects` here.
-- COMMENT requires owning the underlying table; storage.objects is owned
-- by supabase_storage_admin and regular migrations can CREATE POLICY on
-- it but not COMMENT.  The policy names are self-documenting.)
