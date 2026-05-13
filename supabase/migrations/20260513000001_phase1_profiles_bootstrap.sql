-- ─────────────────────────────────────────────────────────────────────────
-- Phase 1 — profile bootstrap, pseudonym generator, KYC tier helpers.
--
-- On every new auth.users insert (Supabase Auth → Twilio Verify path), a
-- profile row is created with:
--   * a unique `bidder_xxxxxx` pseudonym (6 hex chars, retry up to 3x on
--     collision; surface error if all retries fail — the caller decides).
--   * kyc_tier = 1 if the user arrived with a verified phone (the unified
--     phone-OTP signup always does); kyc_tier = 0 otherwise.
--   * phone copied from auth.users.phone (E.164).
--
-- Tier-1 ceiling (100,000 IQD) is bigint per money-handling skill. Phase 7
-- bid validation will read it via `kyc_max_action_iqd(tier)` — kept here so
-- the constant is co-located with the trust-tier code.
-- ─────────────────────────────────────────────────────────────────────────

-- ─── Pseudonym generator ────────────────────────────────────────────────
-- bidder_<6 hex chars>.  6 hex chars = 16M space; collisions are rare even
-- at scale, but we still retry up to 3 times before surfacing an error.
create or replace function public.generate_pseudonym()
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_candidate text;
  v_attempt int := 0;
begin
  loop
    v_attempt := v_attempt + 1;
    -- 3 random bytes → 6 hex chars.  Lowercase for visual consistency
    -- with the example in architecture.md §2 ("bidder_4f2a").
    v_candidate := 'bidder_' || lower(encode(gen_random_bytes(3), 'hex'));

    -- Uniqueness probe inside the same statement.  Race with a concurrent
    -- insert is still possible; the unique constraint on profiles.pseudonym
    -- is the final arbiter.
    if not exists (select 1 from profiles where pseudonym = v_candidate) then
      return v_candidate;
    end if;

    if v_attempt >= 3 then
      raise exception 'pseudonym_collision_retry_exhausted'
        using hint = 'Three random pseudonyms collided. Investigate the random source.';
    end if;
  end loop;
end;
$$;

comment on function public.generate_pseudonym() is
  'Returns a unique bidder_<6hex> handle. Retries up to 3 times on collision.';

-- ─── Profile bootstrap trigger ──────────────────────────────────────────
-- Fires on auth.users INSERT.  Creates the matching profiles row.
--
-- Phone is copied as-is (E.164 from Supabase Auth).  Email is copied if
-- present (web sign-in fallback in later phases will set this).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pseudonym text;
  v_initial_tier int;
begin
  v_pseudonym := public.generate_pseudonym();

  -- Tier 1 (bid/buy up to 100k IQD) is auto-granted on phone verification.
  -- Supabase Auth's phone-OTP path inserts auth.users only AFTER the OTP is
  -- verified, so phone_confirmed_at is set at insertion time.  Other auth
  -- providers (web email, Phase 2+) start at Tier 0.
  v_initial_tier := case
    when new.phone_confirmed_at is not null then 1
    else 0
  end;

  insert into public.profiles (id, pseudonym, phone, email, kyc_tier)
  values (
    new.id,
    v_pseudonym,
    new.phone,
    new.email,
    v_initial_tier
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ─── Phone-confirmation upgrade ─────────────────────────────────────────
-- If a profile was created at Tier 0 and the phone later gets confirmed
-- (e.g., a user added their phone post-signup), bump to Tier 1.  Never
-- downgrade, never bump past 1 here — Tier 2 requires explicit KYC.
create or replace function public.handle_auth_user_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.phone_confirmed_at is not null
     and (old.phone_confirmed_at is null or old.phone is distinct from new.phone)
  then
    update public.profiles
       set kyc_tier = greatest(kyc_tier, 1),
           phone = new.phone
     where id = new.id
       and kyc_tier < 2;  -- never disturb Tier 2 sellers
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update on auth.users
  for each row execute function public.handle_auth_user_updated();

-- ─── KYC ceiling helper (money-handling skill) ──────────────────────────
-- Tier 0: browse only (0 IQD action ceiling).
-- Tier 1: bid/buy up to 100,000 IQD.
-- Tier 2: sell + high-value bid (no ceiling enforced here).
--
-- Returns the maximum single-action amount in IQD.  bigint per the
-- money-handling skill — never numeric / float.
create or replace function public.kyc_max_action_iqd(p_tier int)
returns bigint
language sql
immutable
parallel safe
as $$
  select case p_tier
    when 0 then 0::bigint
    when 1 then 100000::bigint            -- 100,000 IQD ceiling for Tier 1
    when 2 then 9223372036854775807::bigint -- bigint max — no ceiling
    else 0::bigint
  end;
$$;

comment on function public.kyc_max_action_iqd(int) is
  'IQD ceiling per KYC tier. Tier 1 = 100,000 IQD. Bigint per money skill.';

-- ─── Tighten profiles update policy ─────────────────────────────────────
-- Phase 0 granted the user `update` on their own profile row.  That allowed
-- them to set kyc_tier = 2 themselves.  Replace with a column-aware policy:
-- the user can update display fields, but kyc_tier / pseudonym / phone /
-- trust_score / created_at remain immutable from the client.  Mutations to
-- those columns happen only via security-definer RPCs in this phase
-- (submit_kyc_tier2) or service-role flows (admin).

drop policy if exists "profiles_self_update" on profiles;

create policy "profiles_self_update_safe_columns"
  on profiles for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    -- Reject updates that try to elevate the tier or rewrite locked fields.
    -- Postgres evaluates with-check against the proposed NEW row; we compare
    -- to the existing row via a subquery on profiles.id.
    and kyc_tier      = (select kyc_tier from profiles where id = auth.uid())
    and pseudonym     = (select pseudonym from profiles where id = auth.uid())
    and phone is not distinct from (select phone from profiles where id = auth.uid())
    and trust_score   = (select trust_score from profiles where id = auth.uid())
    and created_at    = (select created_at from profiles where id = auth.uid())
  );

-- ─── Public profile view ────────────────────────────────────────────────
-- Phase 3 (bidding) needs to render bidder pseudonyms in the live activity
-- feed.  Anyone authenticated can read pseudonym + city.  Display name and
-- avatar are NOT exposed publicly — pseudonyms are the public identity.
create or replace view public.profiles_public as
  select id, pseudonym, city
  from public.profiles;

comment on view public.profiles_public is
  'Pseudonymized public projection. Use in bid feeds; never expose display_name here.';

grant select on public.profiles_public to anon, authenticated;
