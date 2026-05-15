-- ─────────────────────────────────────────────────────────────────────────
-- Phase 3 — Bidding engine + Smart Close
--
-- Implements:
--   * place_bid(listing_id, amount, max_amount, source) RPC per
--     architecture.md §6.1.  Atomic via SELECT ... FOR UPDATE on the listing
--     row.
--   * Smart Close timer per §6.2 — discovery vs post-discovery, hard cap at
--     hard_close_at.
--   * Proxy bidding as an iterative loop inside the same transaction.  Hard
--     cap of MAX_PROXY_ITERATIONS auto-bids per user-bid event to prevent
--     runaway when two users have overlapping max_amount values.
--   * Per-user rate limit: 10 bids / 60 seconds, enforced inside the RPC
--     (no separate table — counted against the bids table directly).
--   * KYC tier gate: bidder must be Tier 1+ (bid/buy up to 100k IQD).  Per
--     the spec, sellers need Tier 2 to publish an auction, but bidders only
--     need Tier 1 — and Tier 1 ceiling applies via kyc_max_action_iqd().
--   * ADR-0008 hard gate: when feature_flag('auto_grant_tier2') is OFF,
--     refuse bids on listings owned by sellers whose Tier 2 was auto-granted
--     without an admin reviewer ID (`seller_profiles.reviewed_by`).  Adds
--     `reviewed_by` / `reviewed_at` columns now so Phase 9 admin console can
--     populate them.  See ADR-0013 for the bidding-side gate.
--   * pg_cron sweep every 60s to close listings whose current_close_at has
--     passed.  The Edge Function `close_listing_sweep` handles notification
--     fan-out and order creation (Phase 7 reads what this row sets).
--
-- RLS:
--   bids — direct INSERT is denied (no policy).  place_bid() runs with
--   security definer.  Read policy from Phase 0 unchanged (bidder or seller
--   may read).
-- ─────────────────────────────────────────────────────────────────────────

-- ─── Phase 1 search_path fix ───────────────────────────────────────────
-- `generate_pseudonym` was created in Phase 1 with `set search_path =
-- public, pg_temp` but calls `gen_random_bytes` from pgcrypto, which lives
-- in the `extensions` schema in Supabase.  The function was effectively
-- broken: every auth signup raised "function gen_random_bytes(integer)
-- does not exist".  We never noticed because Phase 1 had no integration
-- test exercising the auth-user-create trigger end-to-end.
--
-- Re-create with `extensions` on the search_path.  Behavior is otherwise
-- unchanged.  See ADR-0013 — fix-in-place rather than a separate hotfix
-- migration because Phase 3 is the first phase to write integration tests
-- that depend on it, and rolling forward catches the rest of the schema.
create or replace function public.generate_pseudonym()
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_candidate text;
  v_attempt int := 0;
begin
  loop
    v_attempt := v_attempt + 1;
    v_candidate := 'bidder_' || lower(encode(gen_random_bytes(3), 'hex'));
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

-- ─── Reviewer columns on seller_profiles (ADR-0008 follow-through) ──────
alter table seller_profiles
  add column if not exists reviewed_by uuid references profiles(id),
  add column if not exists reviewed_at timestamptz;

comment on column seller_profiles.reviewed_by is
  'Admin who reviewed this seller''s Tier 2 KYC. NULL means auto-grant only — '
  'bids are gated when feature_flag(''auto_grant_tier2'') is OFF.';

-- ─── auto_grant_tier2 feature flag (ADR-0008 gate, bid side) ───────────
-- Default TRUE: dev/early-launch behavior keeps the auto-grant working.
-- Flip OFF in production once Phase 9 admin queue starts setting reviewed_by
-- on Tier-2 sellers.  Coordinated with phase7_escrow_enabled at launch.
insert into feature_flags (name, enabled, description) values
  (
    'auto_grant_tier2',
    true,
    'When true: bids accepted on auto-granted Tier-2 sellers (dev/early). '
    'When false: place_bid raises seller_not_reviewed unless seller_profiles.reviewed_by is set.'
  )
on conflict (name) do nothing;

-- ─── Index supporting per-user rate-limit lookup ────────────────────────
-- We count valid bids by (bidder_id, created_at) within a 60-second window.
-- The existing bids_bidder_idx (bidder_id, created_at desc) already covers
-- this query — no new index needed.

-- ─── place_bid ──────────────────────────────────────────────────────────
create or replace function public.place_bid(
  p_listing_id uuid,
  p_amount     bigint,
  p_max_amount bigint default null,
  p_source     text   default 'app'
) returns bids
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid             uuid := auth.uid();
  v_listing         listings%rowtype;
  v_bid             bids%rowtype;
  v_min_increment   bigint;
  v_current         bigint;
  v_recent_count    int;
  v_tier            int;
  v_seller_profile  seller_profiles%rowtype;
  v_auto_grant_ok   boolean;
  v_now             timestamptz := now();
  v_next_close      timestamptz;
  v_max_proxy_iters constant int := 20;
  v_iter            int := 0;
  v_proxy_bidder    uuid;
  v_proxy_max       bigint;
  v_proxy_amount    bigint;
begin
  -- 0. Auth.
  if v_uid is null then raise exception 'unauthenticated'; end if;

  -- 1. Source enum (architecture.md schema: 'app'|'web'|'whatsapp').
  if p_source is null or p_source not in ('app','web','whatsapp') then
    raise exception 'invalid_source';
  end if;

  -- 2. Money invariants — bigint discipline (money-handling skill).
  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;
  if p_max_amount is not null and p_max_amount < p_amount then
    raise exception 'max_amount_below_amount';
  end if;

  -- 3. Per-user rate limit: 10 bids / 60s.  Counted against valid bids
  --    only — proxy auto-bids are excluded from the cap so a user can't
  --    rate-limit themselves by setting an aggressive max.
  select count(*)
    into v_recent_count
    from bids
   where bidder_id = v_uid
     and is_proxy  = false
     and created_at > v_now - interval '60 seconds';
  if v_recent_count >= 10 then
    raise exception 'rate_limited';
  end if;

  -- 4. Lock the listing row for the rest of the transaction.
  select * into v_listing from listings where id = p_listing_id for update;
  if not found then raise exception 'listing_not_found'; end if;

  -- 5. Listing-state validation.
  if v_listing.status <> 'active' then
    raise exception 'listing_not_active';
  end if;
  if v_listing.type not in ('auction','bazaar') then
    -- Buy-now uses a different RPC (Phase 7).  place_bid is auction/bazaar.
    raise exception 'listing_not_biddable';
  end if;
  if v_now >= v_listing.current_close_at then
    raise exception 'listing_closed';
  end if;
  if v_uid = v_listing.seller_id then
    raise exception 'self_bid_forbidden';
  end if;

  -- 6. Bidder tier — Tier 1+ may bid (per architecture.md §2 / ADR §11).
  select kyc_tier into v_tier from profiles where id = v_uid;
  if v_tier is null then raise exception 'profile_not_found'; end if;
  if v_tier < 1 then raise exception 'kyc_tier_1_required'; end if;

  -- 7. Tier-1 ceiling: 100,000 IQD per single action.  Tier 2 has no cap.
  if v_tier = 1 and p_amount > kyc_max_action_iqd(1) then
    raise exception 'bid_exceeds_tier_ceiling';
  end if;
  if v_tier = 1 and p_max_amount is not null
     and p_max_amount > kyc_max_action_iqd(1) then
    raise exception 'max_amount_exceeds_tier_ceiling';
  end if;

  -- 8. ADR-0008 hard gate.  When auto_grant_tier2 is OFF and the seller's
  --    Tier 2 was auto-granted (no admin reviewer), refuse the bid.
  --    Sellers who passed admin review (reviewed_by IS NOT NULL) are
  --    always accepted regardless of the flag.
  v_auto_grant_ok := public.feature_flag('auto_grant_tier2');
  if not v_auto_grant_ok then
    select * into v_seller_profile
      from seller_profiles
     where user_id = v_listing.seller_id;
    if not found or v_seller_profile.reviewed_by is null then
      raise exception 'seller_not_reviewed';
    end if;
  end if;

  -- 9. Min-increment + amount sanity.  Server is authoritative (the client
  --    may have a stale current_high; this is the only check that matters).
  --    Mirror of money_format.dart `minimumBidIncrement`:
  --        max(1000, (current_high * 5) / 100)
  --    Integer arithmetic — truncation by design (see money-handling skill).
  v_current       := coalesce(v_listing.current_high, v_listing.starting_price);
  v_min_increment := greatest(1000::bigint, (v_current * 5) / 100);
  if p_amount < v_current + v_min_increment then
    raise exception 'bid_too_low';
  end if;

  -- 10. Insert the bid.
  insert into bids (listing_id, bidder_id, amount, max_amount, source, is_proxy)
  values (p_listing_id, v_uid, p_amount, p_max_amount, p_source, false)
  returning * into v_bid;

  -- 11. Update listing high + Smart Close timer (architecture.md §6.2).
  --     During discovery (now < discovery_ends_at): close stays put.
  --     After discovery: close = now + smart_close_window, capped at
  --     hard_close_at.
  v_next_close := case
    when v_listing.discovery_ends_at is not null and v_now < v_listing.discovery_ends_at
      then v_listing.discovery_ends_at
    else least(v_now + v_listing.smart_close_window, v_listing.hard_close_at)
  end;

  update listings set
    current_high           = p_amount,
    current_high_bidder_id = v_uid,
    bid_count              = bid_count + 1,
    current_close_at       = v_next_close
   where id = p_listing_id;

  -- 12. Proxy bid loop.  Iterate at most v_max_proxy_iters times to prevent
  --     runaway when two users have overlapping max_amount.  Each step:
  --       a. Find the candidate: another user with the highest standing
  --          max_amount strictly greater than the current high; ties go to
  --          the earliest bid (first-come first-served).
  --       b. If the candidate can outbid by at least min_increment, place
  --          an auto-bid at min(candidate.max, current_high + min_increment).
  --       c. Re-read current_high and re-compute min_increment for the next
  --          iteration.  Re-extend the Smart Close timer per the same rules.
  loop
    v_iter := v_iter + 1;
    exit when v_iter > v_max_proxy_iters;

    -- Re-read the locked listing row to get the latest current_high.
    -- (We're still in the same transaction; no other writer can touch it.)
    select current_high into v_current from listings where id = p_listing_id;
    v_min_increment := greatest(1000::bigint, (v_current * 5) / 100);

    -- Highest standing max_amount among other bidders, latest per-user.
    -- "Latest per-user" because a user can lower their max by placing a
    -- new bid with a smaller max_amount; we honor their most recent intent.
    select b.bidder_id, b.max_amount
      into v_proxy_bidder, v_proxy_max
    from (
      select distinct on (bidder_id)
             bidder_id, max_amount, created_at
        from bids
       where listing_id = p_listing_id
         and status     = 'valid'
         and max_amount is not null
         and bidder_id  <> (select current_high_bidder_id
                              from listings where id = p_listing_id)
       order by bidder_id, created_at desc
    ) b
    where b.max_amount >= v_current + v_min_increment
    order by b.max_amount desc, b.created_at asc
    limit 1;

    exit when v_proxy_bidder is null;

    -- Tier-1 ceiling check on the proxy bidder.  If their max ceiling has
    -- been exceeded by escalation, clamp the auto-bid (which can't exceed
    -- their declared max either).
    select kyc_tier into v_tier from profiles where id = v_proxy_bidder;
    v_proxy_amount := least(v_proxy_max, v_current + v_min_increment);
    if v_tier = 1 and v_proxy_amount > kyc_max_action_iqd(1) then
      -- Can't auto-bid above the ceiling.  Skip this user permanently for
      -- this iteration round by exiting the loop — no further proxies will
      -- be able to outbid either (if the ceiling blocks the top max, it
      -- blocks every lesser max too).
      exit;
    end if;

    insert into bids (
      listing_id, bidder_id, amount, max_amount, source, is_proxy
    ) values (
      p_listing_id, v_proxy_bidder, v_proxy_amount, v_proxy_max, 'app', true
    );

    v_next_close := case
      when v_listing.discovery_ends_at is not null
       and v_now < v_listing.discovery_ends_at
        then v_listing.discovery_ends_at
      else least(v_now + v_listing.smart_close_window, v_listing.hard_close_at)
    end;

    update listings set
      current_high           = v_proxy_amount,
      current_high_bidder_id = v_proxy_bidder,
      bid_count              = bid_count + 1,
      current_close_at       = v_next_close
     where id = p_listing_id;

    -- Reset for next iteration.
    v_proxy_bidder := null;
    v_proxy_max    := null;
  end loop;

  return v_bid;
end;
$$;

revoke all on function public.place_bid(uuid, bigint, bigint, text) from public;
grant execute on function public.place_bid(uuid, bigint, bigint, text) to authenticated;

comment on function public.place_bid(uuid, bigint, bigint, text) is
  'Atomic bid placement with Smart Close + iterative proxy bidding. '
  'Hard cap of 20 proxy auto-bids per user-bid event. See ADR-0013.';

-- ─── close_listings_sweep ──────────────────────────────────────────────
-- Marks listings whose current_close_at has passed as 'sold' (winner) or
-- 'expired' (no bid / reserve unmet).  Returns the list of newly-closed
-- listing IDs so the Edge Function can dispatch notifications and create
-- orders downstream (Phase 7).
--
-- Idempotent — re-running is safe; only active listings with passed close
-- times are touched.
create or replace function public.close_listings_sweep(p_limit int default 200)
returns table (
  listing_id  uuid,
  new_status  text,
  winner_id   uuid,
  hammer      bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row listings%rowtype;
  v_new_status text;
  v_now timestamptz := now();
begin
  for v_row in
    select * from listings
     where status = 'active'
       and current_close_at is not null
       and current_close_at <= v_now
       and type in ('auction','bazaar','fixed')
     order by current_close_at asc
     limit greatest(coalesce(p_limit, 200), 1)
     for update skip locked
  loop
    -- Winner determined by current_high_bidder_id.  Reserve price (if set)
    -- must be met or the listing expires unsold.
    if v_row.current_high_bidder_id is not null
       and (v_row.reserve_price is null
            or v_row.current_high >= v_row.reserve_price)
    then
      v_new_status := 'sold';
    else
      v_new_status := 'expired';
    end if;

    update listings
       set status = v_new_status
     where id = v_row.id;

    insert into audit_logs (actor_id, action, target, metadata)
    values (
      null,
      'listing_closed',
      v_row.id::text,
      jsonb_build_object(
        'new_status',  v_new_status,
        'hammer',      coalesce(v_row.current_high, 0),
        'winner_id',   v_row.current_high_bidder_id,
        'bid_count',   v_row.bid_count
      )
    );

    listing_id := v_row.id;
    new_status := v_new_status;
    winner_id  := v_row.current_high_bidder_id;
    hammer     := coalesce(v_row.current_high, 0);
    return next;
  end loop;
end;
$$;

-- Only service_role calls this (from the Edge Function / pg_cron).
revoke all on function public.close_listings_sweep(int) from public;
grant execute on function public.close_listings_sweep(int) to service_role;

-- ─── pg_cron job: sweep every 60 seconds ───────────────────────────────
-- pg_cron may not be available in the local supabase stack with default
-- config; the migration installs the extension if possible and registers
-- the schedule.  If pg_cron isn't installed (managed envs sometimes block
-- it), the close_listing_sweep Edge Function can be invoked from an
-- external scheduler — see runbook.md.
do $cron_setup$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;

    -- Idempotent re-schedule: drop the existing job by name before
    -- re-registering.  cron.unschedule(text) raises if the name is
    -- unknown, so we guard with EXISTS first.
    if exists (
      select 1 from cron.job where jobname = 'mazad_close_listings_sweep'
    ) then
      perform cron.unschedule('mazad_close_listings_sweep');
    end if;

    perform cron.schedule(
      'mazad_close_listings_sweep',
      '* * * * *',
      'select public.close_listings_sweep(200);'
    );
  else
    raise notice
      'pg_cron not available — close_listings_sweep relies on external scheduler';
  end if;
end
$cron_setup$;

-- ─── Bids: explicit deny-direct-insert documentation ───────────────────
-- RLS on bids is enabled at Phase 0; no INSERT policy exists, so direct
-- INSERT is already denied.  We don't add a permissive insert policy here
-- — place_bid() is security-definer and bypasses RLS for the privileged
-- write.  Reads are governed by `bids_self_or_seller_read` from Phase 0.
--
-- The check below is defensive: if a future migration adds a permissive
-- INSERT policy by mistake, this `revoke` makes sure non-service-role
-- callers still can't INSERT via PostgREST.  It does not affect SECURITY
-- DEFINER functions (which run as the function owner).
revoke insert, update, delete on table bids from authenticated, anon;

-- ─── Helper view: active bid feed (pseudonymized) ──────────────────────
-- Used by the realtime activity feed on listing detail.  Joins bids with
-- the public profile projection (pseudonym + city only — never
-- display_name).  Excludes proxy bids by default? — no, include them;
-- proxy bids ARE the live activity from the bidder's perspective and
-- showing them lets the user see the auction state escalating.
create or replace view public.listing_bid_feed as
  select
    b.id            as bid_id,
    b.listing_id,
    b.amount,
    b.is_proxy,
    b.source,
    b.created_at,
    p.pseudonym     as bidder_pseudonym,
    p.city          as bidder_city
  from bids b
  join profiles_public p on p.id = b.bidder_id
  where b.status = 'valid';

grant select on public.listing_bid_feed to anon, authenticated;

comment on view public.listing_bid_feed is
  'Pseudonymized bid feed for the live activity surface. Never join '
  'profiles.display_name into this view.';
