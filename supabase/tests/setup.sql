-- ─────────────────────────────────────────────────────────────────────────
-- Test fixtures for Phase 3 bidding-engine integration tests.
--
-- Drops & recreates a known set of profiles, an auction listing, and a
-- bazaar listing.  Run before every test that needs a clean slate.
--
-- All times pinned relative to now() so smart-close logic exercises the
-- same code paths a real publish_listing call would.
--
-- Test convention: profile ids are deterministic UUIDs derived from
-- 't0000000-0000-0000-0000-NNNNNNNNNNNN' for easy debugging.
-- ─────────────────────────────────────────────────────────────────────────

-- Clean prior fixtures (idempotent).
delete from bids        where listing_id in (
  select id from listings where seller_id in (
    select id from profiles where pseudonym like 'bidder_test_%'
  )
);
delete from listings    where seller_id in (
  select id from profiles where pseudonym like 'bidder_test_%'
);
delete from seller_profiles where user_id in (
  select id from profiles where pseudonym like 'bidder_test_%'
);
delete from profiles   where pseudonym like 'bidder_test_%';
delete from auth.users where email like 'bidder_test_%@mazad.test';

-- Helper: ensure an auth.users row exists for each test user.
-- profiles.id has an FK to auth.users(id); the Phase 1 trigger
-- handle_new_auth_user() would normally create the profile but it picks a
-- random pseudonym.  We bypass the trigger by inserting profiles directly
-- after the auth user, with `on conflict (id) do update` to override the
-- trigger-created row.
create or replace function _phase3_test_make_user(
  p_uid     uuid,
  p_email   text,
  p_pseudonym text,
  p_tier    int
) returns void
language plpgsql as $$
begin
  -- Minimal auth.users row.  encrypted_password / aud kept null/default;
  -- these users never sign in over the API in tests — we set request.jwt
  -- claims directly on the test connection.
  insert into auth.users (id, email, instance_id, aud, role)
  values (p_uid, p_email, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  -- The on-insert trigger created a profile with a random pseudonym; rewrite it.
  update profiles set pseudonym = p_pseudonym, kyc_tier = p_tier, locale = 'en', city = 'Baghdad'
   where id = p_uid;
  -- If the trigger didn't fire for some reason, insert one.
  insert into profiles (id, pseudonym, kyc_tier, locale, city)
  values (p_uid, p_pseudonym, p_tier, 'en', 'Baghdad')
  on conflict (id) do nothing;
end$$;

-- Seller (Tier 2, reviewed).
select _phase3_test_make_user(
  '11111111-0000-0000-0000-000000000001'::uuid,
  'bidder_test_seller@mazad.test',
  'bidder_test_seller',
  2
);

insert into seller_profiles (user_id, business_name, payout_method, reviewed_by, reviewed_at)
values (
  '11111111-0000-0000-0000-000000000001'::uuid,
  'Test Seller', 'cod',
  '11111111-0000-0000-0000-000000000001'::uuid,
  now()
)
on conflict (user_id) do update set
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at;

-- 60 bidder profiles (we use 50 for the concurrency test, plus extras for
-- proxy / rate-limit / tier scenarios).
-- Bidders 1..50 are Tier 1 (verified buyers; ceiling 100k IQD).
-- Bidders 51..60 are Tier 2 (no ceiling) — used by pathological-max
-- proxy and high-value tests.
do $$
declare
  i int;
  v_tier int;
begin
  for i in 1..60 loop
    v_tier := case when i <= 50 then 1 else 2 end;
    perform _phase3_test_make_user(
      ('22222222-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
      'bidder_test_' || lpad(i::text, 3, '0') || '@mazad.test',
      'bidder_test_' || lpad(i::text, 3, '0'),
      v_tier
    );
  end loop;
end
$$;

-- One Tier-0 user (browse only) for the kyc_tier_1_required test.
select _phase3_test_make_user(
  '33333333-0000-0000-0000-000000000099'::uuid,
  'bidder_test_tier0@mazad.test',
  'bidder_test_tier0',
  0
);

-- One auto-granted seller (no reviewed_by) for the seller_not_reviewed test.
select _phase3_test_make_user(
  '44444444-0000-0000-0000-000000000001'::uuid,
  'bidder_test_unrev_seller@mazad.test',
  'bidder_test_unrev_seller',
  2
);

insert into seller_profiles (user_id, business_name, payout_method)
values (
  '44444444-0000-0000-0000-000000000001'::uuid,
  'Unreviewed Seller', 'cod'
)
on conflict (user_id) do update set business_name = excluded.business_name;

-- ─── Listings ──────────────────────────────────────────────────────────
-- A1 — concurrent / general auction.  Discovery already over so each bid
-- extends the close by 12 hours from now().
insert into listings (
  id, seller_id, type, title_translations, description_translations,
  category_id, condition, images, starting_price,
  status, discovery_ends_at, smart_close_window, current_close_at,
  hard_close_at, published_at
)
select
  '55555555-0000-0000-0000-000000000001'::uuid,
  '11111111-0000-0000-0000-000000000001'::uuid,
  'auction',
  jsonb_build_object(
    'en','test auction','ar','مزاد اختبار','ku','مزایەدەی تاقیکردنەوە','tr','test açık artırma'
  ),
  jsonb_build_object(
    'en','t','ar','ت','ku','ت','tr','t'
  ),
  c.id, 'good',
  jsonb_build_array('11111111-0000-0000-0000-000000000001/55555555-0000-0000-0000-000000000001/p1.jpg'),
  10000,
  'active',
  now() - interval '1 hour',    -- discovery ENDED an hour ago
  interval '12 hours',
  now() + interval '12 hours',
  now() + interval '14 days',
  now() - interval '49 hours'
from categories c where slug = 'phones' limit 1;

-- A2 — discovery STILL active.  Each bid keeps close = discovery_ends_at.
insert into listings (
  id, seller_id, type, title_translations, description_translations,
  category_id, condition, images, starting_price,
  status, discovery_ends_at, smart_close_window, current_close_at,
  hard_close_at, published_at
)
select
  '55555555-0000-0000-0000-000000000002'::uuid,
  '11111111-0000-0000-0000-000000000001'::uuid,
  'auction',
  jsonb_build_object(
    'en','discovery auction','ar','مزاد اكتشاف','ku','مزایەدەی دۆزینەوە','tr','keşif açık artırma'
  ),
  jsonb_build_object('en','t','ar','ت','ku','ت','tr','t'),
  c.id, 'good',
  jsonb_build_array('11111111-0000-0000-0000-000000000001/55555555-0000-0000-0000-000000000002/p1.jpg'),
  10000,
  'active',
  now() + interval '12 hours',  -- discovery still active for 12h
  interval '12 hours',
  now() + interval '12 hours',
  now() + interval '14 days',
  now() - interval '36 hours'
from categories c where slug = 'phones' limit 1;

-- A3 — hard cap test.  Close already pushed near hard cap.
insert into listings (
  id, seller_id, type, title_translations, description_translations,
  category_id, condition, images, starting_price,
  status, discovery_ends_at, smart_close_window, current_close_at,
  hard_close_at, published_at
)
select
  '55555555-0000-0000-0000-000000000003'::uuid,
  '11111111-0000-0000-0000-000000000001'::uuid,
  'auction',
  jsonb_build_object(
    'en','hard cap auction','ar','مزاد سقف','ku','مزایەدەی سنوور','tr','sert kapama'
  ),
  jsonb_build_object('en','t','ar','ت','ku','ت','tr','t'),
  c.id, 'good',
  jsonb_build_array('11111111-0000-0000-0000-000000000001/55555555-0000-0000-0000-000000000003/p1.jpg'),
  10000,
  'active',
  now() - interval '13 days 23 hours',
  interval '12 hours',
  -- close almost at hard_close, with hard_close 30 minutes away
  now() + interval '30 minutes',
  now() + interval '30 minutes',
  now() - interval '13 days 23 hours'
from categories c where slug = 'phones' limit 1;

-- A4 — listing on the UNREVIEWED seller (for seller_not_reviewed test).
insert into listings (
  id, seller_id, type, title_translations, description_translations,
  category_id, condition, images, starting_price,
  status, discovery_ends_at, smart_close_window, current_close_at,
  hard_close_at, published_at
)
select
  '55555555-0000-0000-0000-000000000004'::uuid,
  '44444444-0000-0000-0000-000000000001'::uuid,
  'auction',
  jsonb_build_object(
    'en','unreviewed seller auction','ar','بائع غير مراجع','ku','فرۆشیار هەڵنەسەنگێنراو','tr','denetlenmemiş satıcı'
  ),
  jsonb_build_object('en','t','ar','ت','ku','ت','tr','t'),
  c.id, 'good',
  jsonb_build_array('44444444-0000-0000-0000-000000000001/55555555-0000-0000-0000-000000000004/p1.jpg'),
  10000,
  'active',
  now() - interval '1 hour',
  interval '12 hours',
  now() + interval '12 hours',
  now() + interval '14 days',
  now() - interval '49 hours'
from categories c where slug = 'phones' limit 1;
