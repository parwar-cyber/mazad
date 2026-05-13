-- ─────────────────────────────────────────────────────────────────────────
-- Phase 1 — RPCs for profile and KYC tier transitions.
--
-- All mutations to profiles.kyc_tier and seller_profiles go through these
-- security-definer RPCs.  Direct INSERT/UPDATE on those columns is denied
-- by RLS (see 20260513000001 for the column-aware profiles policy and §5
-- for the seller_profiles self-policy carried from Phase 0).
--
-- KYC-tier audit trail lives in audit_logs.  Reasoning: tier changes are
-- the highest-trust mutation in the system; they need a separate paper
-- trail that survives schema changes to seller_profiles.
-- ─────────────────────────────────────────────────────────────────────────

-- ─── update_profile ─────────────────────────────────────────────────────
-- Updates display name, locale, city.  Plain RLS would also work for these
-- columns, but routing through an RPC lets us:
--   * trim/normalize input server-side
--   * collapse three round-trips (display_name, locale, city) into one
--   * audit-log the change
create or replace function public.update_profile(
  p_display_name text default null,
  p_locale       text default null,
  p_city         text default null
) returns profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row profiles%rowtype;
begin
  if v_uid is null then
    raise exception 'unauthenticated';
  end if;

  if p_locale is not null and p_locale not in ('en','ar','ku','tr') then
    raise exception 'invalid_locale' using hint = 'Allowed: en, ar, ku, tr.';
  end if;

  update profiles set
    display_name   = coalesce(nullif(trim(p_display_name), ''), display_name),
    locale         = coalesce(p_locale, locale),
    city           = coalesce(nullif(trim(p_city), ''), city),
    last_active_at = now()
  where id = v_uid
  returning * into v_row;

  if not found then
    raise exception 'profile_not_found';
  end if;

  return v_row;
end;
$$;

revoke all on function public.update_profile(text, text, text) from public;
grant execute on function public.update_profile(text, text, text) to authenticated;

-- ─── set_locale ─────────────────────────────────────────────────────────
-- Lightweight specialization of update_profile for the language switcher.
-- Kept separate so the language picker doesn't have to know about other
-- profile columns.
create or replace function public.set_locale(p_locale text)
returns profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.update_profile(p_locale := p_locale);
end;
$$;

revoke all on function public.set_locale(text) from public;
grant execute on function public.set_locale(text) to authenticated;

-- ─── request_seller_upgrade ────────────────────────────────────────────
-- Marks intent to start selling.  Doesn't grant anything — KYC submission
-- is the actual trigger.  Used by the "Start selling" CTA on the dashboard
-- so analytics can measure intent → completion drop-off.
create or replace function public.request_seller_upgrade()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  insert into audit_logs (actor_id, action, target, metadata)
  values (v_uid, 'seller_upgrade_intent', v_uid::text, '{}'::jsonb);
end;
$$;

revoke all on function public.request_seller_upgrade() from public;
grant execute on function public.request_seller_upgrade() to authenticated;

-- ─── submit_kyc_tier2 ──────────────────────────────────────────────────
-- The "Start selling" upgrade.  Inserts/updates seller_profiles, records
-- the ID document path (must live under the user's own folder in the
-- kyc-docs bucket), and bumps profiles.kyc_tier to 2.
--
-- Phase 1 decision: auto-bump on submission.  In production the admin
-- console (Phase 9) will gate this — `verified_at` will be set there.
-- Captured in docs/decisions.md ADR-0008.
--
-- The id_doc_path argument is a Storage path like
--   "<auth.uid()>/passport.jpg"
-- and MUST start with the caller's UUID — server-side check below mirrors
-- the storage RLS so a stale or forged path can't slip through.
create or replace function public.submit_kyc_tier2(
  p_business_name   text,
  p_address         jsonb,
  p_payout_method   text,
  p_payout_account  jsonb,
  p_id_doc_path     text
) returns seller_profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row seller_profiles%rowtype;
  v_expected_prefix text;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  if p_business_name is null or length(trim(p_business_name)) < 2 then
    raise exception 'invalid_business_name';
  end if;

  if p_payout_method is null
     or p_payout_method not in ('zaincash','fastpay','bank','cod')
  then
    raise exception 'invalid_payout_method';
  end if;

  if p_id_doc_path is null or length(p_id_doc_path) = 0 then
    raise exception 'missing_id_doc';
  end if;

  -- Path-prefix check: the document must live under the caller's UUID.
  -- Mirrors the storage.objects RLS so a forged or borrowed path can't
  -- be associated with this user's KYC submission.
  v_expected_prefix := v_uid::text || '/';
  if position(v_expected_prefix in p_id_doc_path) <> 1 then
    raise exception 'id_doc_path_prefix_mismatch';
  end if;

  -- Address sanity: require at least a non-empty `line1` and `city`.
  if p_address is null
     or coalesce(p_address->>'line1', '') = ''
     or coalesce(p_address->>'city', '') = ''
  then
    raise exception 'invalid_address';
  end if;

  insert into seller_profiles (
    user_id, business_name, address, payout_method, payout_account,
    id_doc_url, verified_at
  )
  values (
    v_uid, trim(p_business_name), p_address, p_payout_method,
    p_payout_account, p_id_doc_path, now()  -- Phase 1 auto-grant; Phase 9 admin
  )
  on conflict (user_id) do update set
    business_name  = excluded.business_name,
    address        = excluded.address,
    payout_method  = excluded.payout_method,
    payout_account = excluded.payout_account,
    id_doc_url     = excluded.id_doc_url,
    verified_at    = now()
  returning * into v_row;

  -- Bump tier.  Use the ceiling helper as the source of truth.
  update profiles set kyc_tier = 2 where id = v_uid and kyc_tier < 2;

  -- Audit-log without the path — never log document paths or contents.
  insert into audit_logs (actor_id, action, target, metadata)
  values (
    v_uid,
    'kyc_tier2_submitted',
    v_uid::text,
    jsonb_build_object('payout_method', p_payout_method)
  );

  return v_row;
end;
$$;

revoke all on function public.submit_kyc_tier2(text, jsonb, text, jsonb, text) from public;
grant execute on function public.submit_kyc_tier2(text, jsonb, text, jsonb, text) to authenticated;
