-- ─────────────────────────────────────────────────────────────────────────
-- Phase 2 — listing-photos storage bucket.
--
-- Public-read bucket because listing photos render in browse / search /
-- detail without auth.  Writes are gated to authenticated callers and the
-- path MUST start with the caller's UUID — same model as kyc-docs but
-- with a public read policy added so browse pages can fetch via the
-- standard public URL pattern.
--
-- Convention for object names (enforced by `update_listing_draft` and
-- mirrored by Storage RLS): "<seller_uid>/<listing_id>/<basename>.<ext>".
-- The seller_uid prefix is enforced here; the listing_id prefix is
-- enforced in the RPC (storage RLS doesn't know about listings).
-- ─────────────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('listing-photos', 'listing-photos', true)
on conflict (id) do nothing;

-- Anyone can read.  This is the entire point of a public-read bucket and
-- the standard pattern for Supabase Storage with `public = true`.
create policy "listing_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'listing-photos');

-- INSERT: caller can write under their own UUID folder only.
create policy "listing_photos_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'listing-photos'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- UPDATE: same scope as insert.  Allows re-upload to the same path.
create policy "listing_photos_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'listing-photos'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- DELETE: same scope.  Once a listing is published the seller can still
-- remove old draft photos.  The historical listings.images jsonb survives
-- the deletion, but downstream consumers must handle 404s gracefully.
create policy "listing_photos_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'listing-photos'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );
