-- ─────────────────────────────────────────────────────────────────────────
-- RLS policies.  Every table is default-deny (RLS is enabled in the prior
-- migration without any policies, which denies all anon/auth access).
-- This migration adds the minimum read/write policies needed for Phase 0
-- boot.  Mutation policies for Phase 1+ surfaces are intentionally absent —
-- they are added with the migrations that introduce the RPCs.
-- ─────────────────────────────────────────────────────────────────────────

-- profiles: a user can read/update their own row.  Public read is via a
-- limited view introduced in Phase 1 — not here.
create policy "profiles_self_select"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_self_update"
  on profiles for update
  using (auth.uid() = id);

create policy "profiles_self_insert"
  on profiles for insert
  with check (auth.uid() = id);

-- seller_profiles: self read/write only.
create policy "seller_profiles_self_select"
  on seller_profiles for select
  using (auth.uid() = user_id);

create policy "seller_profiles_self_upsert"
  on seller_profiles for insert
  with check (auth.uid() = user_id);

create policy "seller_profiles_self_update"
  on seller_profiles for update
  using (auth.uid() = user_id);

-- categories: anyone can read; writes via service_role only.
create policy "categories_public_read"
  on categories for select using (true);

-- listings: anyone reads active listings.  Drafts/pending are seller-only.
-- Mutations land with the listing-creation migration (Phase 2).
create policy "listings_public_read_active"
  on listings for select
  using (status = 'active' or auth.uid() = seller_id);

-- bids: bidder or listing seller can read.  Inserts go through place_bid()
-- (Phase 3) — no direct insert policy.
create policy "bids_self_or_seller_read"
  on bids for select
  using (
    auth.uid() = bidder_id
    or auth.uid() = (select seller_id from listings where id = listing_id)
  );

-- watches: self only.
create policy "watches_self_all"
  on watches for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- orders: buyer or seller can read; writes via RPCs (Phase 7).
create policy "orders_party_read"
  on orders for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- payments / shipments: visible to the order's parties.
create policy "payments_party_read"
  on payments for select
  using (
    exists (
      select 1 from orders o
      where o.id = order_id
        and (auth.uid() = o.buyer_id or auth.uid() = o.seller_id)
    )
  );

create policy "shipments_party_read"
  on shipments for select
  using (
    exists (
      select 1 from orders o
      where o.id = order_id
        and (auth.uid() = o.buyer_id or auth.uid() = o.seller_id)
    )
  );

-- reviews: anyone reads (public reputation surface); writes via RPC (Phase 8).
create policy "reviews_public_read" on reviews for select using (true);

-- vouches: any authenticated user can read; writes via RPC (Phase 8).
create policy "vouches_authed_read"
  on vouches for select
  using (auth.uid() is not null);

-- disputes: parties + assigned admin only.
create policy "disputes_party_read"
  on disputes for select
  using (
    auth.uid() = raised_by
    or auth.uid() = assigned_to
    or exists (
      select 1 from orders o
      where o.id = order_id
        and (auth.uid() = o.buyer_id or auth.uid() = o.seller_id)
    )
  );

-- notifications: self only.
create policy "notifications_self_read"
  on notifications for select
  using (auth.uid() = user_id);

create policy "notifications_self_update_read_at"
  on notifications for update
  using (auth.uid() = user_id);

-- notification_templates / fee_rules: service-role-only writes; public read
-- of templates is fine (no PII).
create policy "notification_templates_public_read"
  on notification_templates for select using (true);

create policy "fee_rules_public_read"
  on fee_rules for select using (true);

-- WhatsApp tables: self only.
create policy "wa_threads_self_read"
  on whatsapp_threads for select
  using (auth.uid() = user_id);

create policy "wa_messages_self_read"
  on whatsapp_messages for select
  using (exists (
    select 1 from whatsapp_threads t
    where t.id = thread_id and t.user_id = auth.uid()
  ));

-- audit_logs / group_deals / deal_signups: service-role for writes;
-- deal_signups readable to the signing user.
create policy "deal_signups_self_read"
  on deal_signups for select
  using (auth.uid() = user_id);

create policy "group_deals_public_read"
  on group_deals for select using (true);
