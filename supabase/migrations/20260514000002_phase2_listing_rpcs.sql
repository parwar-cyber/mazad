-- ─────────────────────────────────────────────────────────────────────────
-- Phase 2 — listing creation, update, publish, browse, search.
--
-- All mutations go through security-definer RPCs that validate auth.uid()
-- and the seller's KYC tier.  Direct INSERT / UPDATE on `listings` is
-- denied by RLS (no insert/update policy exists; default-deny holds).
--
-- KYC gating (per CLAUDE.md / docs/architecture.md §2):
--   Tier 0 — cannot create listings.
--   Tier 1 — can create / publish `fixed` and `bazaar` listings.
--   Tier 2 — can additionally create / publish `auction` listings.
--
-- Smart Close timing fields are populated at publish time so Phase 3's
-- pg_cron sweep job can take over without back-filling.  See
-- architecture.md §6.2.
-- ─────────────────────────────────────────────────────────────────────────

-- ─── Constants (cheap inline functions, immutable) ──────────────────────
-- Discovery window:           48h auction, 24h bazaar.
-- Smart-close window:         12h auction, 6h bazaar.
-- Hard close:                 14 days from publish.
-- Tier required:              1 for fixed/bazaar, 2 for auction.
-- Sanitization caps:          200 chars title, 4000 chars description per
--                             locale; 24 KB total spec payload.
-- Per-listing image cap:      10 photos (architecture.md §3 media gallery).

-- ─── Text sanitization helper ───────────────────────────────────────────
-- Strips C0 control characters (except CR/LF/TAB) and trims length.
-- Prevents stored-XSS payloads and weird invisible glyphs in titles.  The
-- Flutter `Text` widget renders plain text, but the Phase 9 Next.js admin
-- console (and any future web surface) will render UGC into HTML — strip
-- the dangerous codepoints at write time, defense-in-depth.
create or replace function public.sanitize_listing_text(p_input text, p_max_len int)
returns text
language sql
immutable
parallel safe
as $$
  select case
    when p_input is null then null
    else left(
      trim(
        regexp_replace(
          p_input,
          -- Drop C0 control characters except \t \n \r, and DEL (U+007F).
          E'[\\x00-\\x08\\x0B-\\x0C\\x0E-\\x1F\\x7F]',
          '',
          'g'
        )
      ),
      p_max_len
    )
  end;
$$;

comment on function public.sanitize_listing_text(text, int) is
  'Strip C0 control chars and truncate. Use for all UGC text written to listings.';

-- ─── Sanitize the {en, ar, ku, tr} JSONB shape ─────────────────────────
-- Returns a new jsonb with each present locale value sanitized.  Missing
-- locales are dropped rather than null-filled so the CHECK constraint
-- (`?| array['en','ar','ku','tr']`) is evaluated against a clean shape.
create or replace function public.sanitize_translations(
  p_input jsonb,
  p_max_len int
) returns jsonb
language plpgsql
immutable
parallel safe
as $$
declare
  v_out jsonb := '{}'::jsonb;
  v_locale text;
  v_raw text;
  v_clean text;
begin
  if p_input is null then return null; end if;
  if jsonb_typeof(p_input) <> 'object' then
    raise exception 'translations_not_object';
  end if;

  foreach v_locale in array array['en','ar','ku','tr'] loop
    v_raw := p_input->>v_locale;
    if v_raw is not null then
      v_clean := public.sanitize_listing_text(v_raw, p_max_len);
      if v_clean is not null and length(v_clean) > 0 then
        v_out := v_out || jsonb_build_object(v_locale, v_clean);
      end if;
    end if;
  end loop;

  return v_out;
end;
$$;

-- ─── create_listing_draft ──────────────────────────────────────────────
-- Creates an empty draft row owned by the caller.  Tier-gated.  The draft
-- is the unit the multi-step UI builds up (photos → AI → review → publish).
create or replace function public.create_listing_draft(p_type text)
returns listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tier int;
  v_row listings%rowtype;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  if p_type is null or p_type not in ('auction','fixed','bazaar') then
    raise exception 'invalid_listing_type';
  end if;

  select kyc_tier into v_tier from profiles where id = v_uid;
  if v_tier is null then raise exception 'profile_not_found'; end if;

  -- Tier gating: fixed/bazaar require Tier 1 (verified buyer can list a
  -- buy-now item), auction requires Tier 2 (full seller KYC).
  if p_type = 'auction' and v_tier < 2 then
    raise exception 'kyc_tier_2_required';
  end if;
  if p_type in ('fixed','bazaar') and v_tier < 1 then
    raise exception 'kyc_tier_1_required';
  end if;

  insert into listings (
    seller_id, type, title_translations, description_translations,
    starting_price, status
  ) values (
    v_uid, p_type,
    -- CHECK requires at least one of {en,ar,ku,tr} present; seed an empty
    -- en placeholder so the draft satisfies the constraint until the AI
    -- co-pilot or the seller fills it in.
    jsonb_build_object('en',''),
    '{}'::jsonb,
    0,
    'draft'
  ) returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.create_listing_draft(text) from public;
grant execute on function public.create_listing_draft(text) to authenticated;

-- ─── update_listing_draft ──────────────────────────────────────────────
-- Patches a draft.  Only the owner can update.  Status must be 'draft' or
-- 'pending_review'.  Each field is optional; null means "no change".
--
-- Image paths are validated path-prefix-style: every path must begin with
-- "<seller_uid>/<listing_id>/" so the SSRF surface is constrained to the
-- caller's own folder in our own bucket (see analyze_item Edge Function).
create or replace function public.update_listing_draft(
  p_id uuid,
  p_title_translations       jsonb default null,
  p_description_translations jsonb default null,
  p_category_id              uuid default null,
  p_condition                text default null,
  p_specs                    jsonb default null,
  p_images                   jsonb default null,  -- array of storage paths
  p_starting_price           bigint default null,
  p_buy_now_price            bigint default null,
  p_reserve_price            bigint default null,
  p_location                 jsonb default null
) returns listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row listings%rowtype;
  v_titles jsonb;
  v_descs  jsonb;
  v_images jsonb;
  v_path text;
  v_prefix text;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  select * into v_row from listings where id = p_id for update;
  if not found then raise exception 'listing_not_found'; end if;
  if v_row.seller_id <> v_uid then raise exception 'not_listing_owner'; end if;
  if v_row.status not in ('draft','pending_review') then
    raise exception 'listing_not_editable';
  end if;

  -- Sanitize text inputs.  Caps:
  --   title       200 chars per locale
  --   description 4000 chars per locale
  if p_title_translations is not null then
    v_titles := public.sanitize_translations(p_title_translations, 200);
    -- Must still satisfy the schema CHECK (at least one of the 4 keys).
    if not (v_titles ?| array['en','ar','ku','tr']) then
      v_titles := jsonb_build_object('en','');
    end if;
  end if;
  if p_description_translations is not null then
    v_descs := public.sanitize_translations(p_description_translations, 4000);
    if v_descs is null then v_descs := '{}'::jsonb; end if;
  end if;

  -- Validate condition enum if provided.
  if p_condition is not null
     and p_condition not in ('new','like_new','good','fair','for_parts') then
    raise exception 'invalid_condition';
  end if;

  -- Validate spec payload size — cap at 24 KB to keep RPC responses sane.
  if p_specs is not null and octet_length(p_specs::text) > 24576 then
    raise exception 'specs_too_large';
  end if;

  -- Images: must be an array of strings, each starting with
  -- "<seller_uid>/<listing_id>/".  Max 10 entries (architecture.md §3).
  if p_images is not null then
    if jsonb_typeof(p_images) <> 'array' then
      raise exception 'images_not_array';
    end if;
    if jsonb_array_length(p_images) > 10 then
      raise exception 'images_too_many';
    end if;
    v_prefix := v_uid::text || '/' || p_id::text || '/';
    for v_path in select jsonb_array_elements_text(p_images) loop
      if v_path is null or length(v_path) = 0 then
        raise exception 'invalid_image_path';
      end if;
      if position(v_prefix in v_path) <> 1 then
        raise exception 'image_path_prefix_mismatch';
      end if;
    end loop;
    v_images := p_images;
  end if;

  -- Money invariants (money-handling skill): bigint, non-negative.
  -- Bazaar price ceiling (10,000 IQD) is also enforced by the table CHECK,
  -- but raising the named error here gives the UI a useful message.
  if p_starting_price is not null and p_starting_price < 0 then
    raise exception 'invalid_starting_price';
  end if;
  if p_buy_now_price is not null and p_buy_now_price < 0 then
    raise exception 'invalid_buy_now_price';
  end if;
  if p_reserve_price is not null and p_reserve_price < 0 then
    raise exception 'invalid_reserve_price';
  end if;
  if v_row.type = 'bazaar' and p_starting_price is not null
     and p_starting_price > 10000 then
    raise exception 'bazaar_price_ceiling_10000_iqd';
  end if;

  update listings set
    title_translations       = coalesce(v_titles, title_translations),
    description_translations = coalesce(v_descs,  description_translations),
    category_id              = coalesce(p_category_id, category_id),
    condition                = coalesce(p_condition, condition),
    specs                    = coalesce(p_specs, specs),
    images                   = coalesce(v_images, images),
    starting_price           = coalesce(p_starting_price, starting_price),
    buy_now_price            = coalesce(p_buy_now_price, buy_now_price),
    reserve_price            = coalesce(p_reserve_price, reserve_price),
    location                 = coalesce(p_location, location)
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.update_listing_draft(
  uuid, jsonb, jsonb, uuid, text, jsonb, jsonb, bigint, bigint, bigint, jsonb
) from public;
grant execute on function public.update_listing_draft(
  uuid, jsonb, jsonb, uuid, text, jsonb, jsonb, bigint, bigint, bigint, jsonb
) to authenticated;

-- ─── publish_listing ────────────────────────────────────────────────────
-- Promotes a draft to active.  Re-validates KYC tier (in case the seller
-- has been downgraded since drafting), sets Smart Close timing fields, and
-- stamps published_at.
create or replace function public.publish_listing(p_id uuid)
returns listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tier int;
  v_row listings%rowtype;
  v_now timestamptz := now();
  v_discovery interval;
  v_close_window interval;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  select * into v_row from listings where id = p_id for update;
  if not found then raise exception 'listing_not_found'; end if;
  if v_row.seller_id <> v_uid then raise exception 'not_listing_owner'; end if;
  if v_row.status <> 'draft' then raise exception 'listing_not_publishable'; end if;

  -- Re-check tier at publish time.
  select kyc_tier into v_tier from profiles where id = v_uid;
  if v_row.type = 'auction' and v_tier < 2 then
    raise exception 'kyc_tier_2_required';
  end if;
  if v_row.type in ('fixed','bazaar') and v_tier < 1 then
    raise exception 'kyc_tier_1_required';
  end if;

  -- Required fields at publish time.
  if not (v_row.title_translations ?| array['en','ar','ku','tr'])
     or coalesce(v_row.title_translations->>'en','') = ''
     or coalesce(v_row.title_translations->>'ar','') = ''
     or coalesce(v_row.title_translations->>'ku','') = ''
     or coalesce(v_row.title_translations->>'tr','') = '' then
    raise exception 'title_missing_locale';
  end if;
  if coalesce(v_row.description_translations->>'en','') = ''
     or coalesce(v_row.description_translations->>'ar','') = ''
     or coalesce(v_row.description_translations->>'ku','') = ''
     or coalesce(v_row.description_translations->>'tr','') = '' then
    raise exception 'description_missing_locale';
  end if;
  if v_row.category_id is null then raise exception 'category_required'; end if;
  if v_row.condition is null then raise exception 'condition_required'; end if;
  if jsonb_array_length(coalesce(v_row.images, '[]'::jsonb)) < 1 then
    raise exception 'images_required';
  end if;

  -- Type-specific price requirements.
  if v_row.type = 'fixed' then
    if v_row.buy_now_price is null or v_row.buy_now_price <= 0 then
      raise exception 'buy_now_price_required_for_fixed';
    end if;
  elsif v_row.type in ('auction','bazaar') then
    if v_row.starting_price is null or v_row.starting_price <= 0 then
      raise exception 'starting_price_required';
    end if;
  end if;

  -- Smart Close windows (architecture.md §6.2).
  if v_row.type = 'bazaar' then
    v_discovery    := interval '24 hours';
    v_close_window := interval '6 hours';
  else
    v_discovery    := interval '48 hours';
    v_close_window := interval '12 hours';
  end if;

  update listings set
    status              = 'active',
    published_at        = v_now,
    -- For 'fixed' these fields are still set so the same close-sweep job
    -- (Phase 3) can mark expired fixed-price listings after the hard cap.
    discovery_ends_at   = v_now + v_discovery,
    smart_close_window  = v_close_window,
    current_close_at    = v_now + v_discovery,
    hard_close_at       = v_now + interval '14 days'
  where id = p_id
  returning * into v_row;

  insert into audit_logs (actor_id, action, target, metadata)
  values (
    v_uid, 'listing_published', p_id::text,
    jsonb_build_object('type', v_row.type)
  );

  return v_row;
end;
$$;

revoke all on function public.publish_listing(uuid) from public;
grant execute on function public.publish_listing(uuid) to authenticated;

-- ─── cancel_listing ─────────────────────────────────────────────────────
create or replace function public.cancel_listing(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row listings%rowtype;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;
  select * into v_row from listings where id = p_id for update;
  if not found then raise exception 'listing_not_found'; end if;
  if v_row.seller_id <> v_uid then raise exception 'not_listing_owner'; end if;
  if v_row.status not in ('draft','pending_review','active') then
    raise exception 'listing_not_cancellable';
  end if;
  update listings set status = 'cancelled' where id = p_id;

  insert into audit_logs (actor_id, action, target, metadata)
  values (v_uid, 'listing_cancelled', p_id::text, '{}'::jsonb);
end;
$$;

revoke all on function public.cancel_listing(uuid) from public;
grant execute on function public.cancel_listing(uuid) to authenticated;

-- ─── increment_listing_view ────────────────────────────────────────────
-- Called by the client when a listing detail screen opens.  Fire-and-
-- forget; we don't care about exact counts at Phase 2.  Future phases may
-- replace this with a unique-viewer table.
create or replace function public.increment_listing_view(p_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  update listings
     set view_count = view_count + 1
   where id = p_id and status = 'active';
$$;

revoke all on function public.increment_listing_view(uuid) from public;
grant execute on function public.increment_listing_view(uuid) to authenticated, anon;

-- ─── search_listings ────────────────────────────────────────────────────
-- Cross-locale full-text + filters.  Uses the generated `search_vector`
-- column (i18n-rtl skill §Search) which already runs `f_unaccent` over all
-- four locale strings — so Turkish "şarj" matches "sarj" and Arabic with
-- diacritics matches without.
--
-- The query argument is run through the same f_unaccent so the query side
-- normalizes identically to the indexed side.
--
-- Returns columns the browse / search UI needs.  Excludes raw bid stats
-- (Phase 3 will replace those).
create or replace function public.search_listings(
  p_query        text default null,
  p_category_id  uuid default null,
  p_type         text default null,
  p_has_buy_now  boolean default null,
  p_min_price    bigint default null,
  p_max_price    bigint default null,
  p_limit        int default 24,
  p_offset       int default 0
) returns table (
  id uuid,
  seller_id uuid,
  type text,
  title_translations jsonb,
  description_translations jsonb,
  category_id uuid,
  condition text,
  images jsonb,
  starting_price bigint,
  buy_now_price bigint,
  current_high bigint,
  bid_count int,
  view_count int,
  current_close_at timestamptz,
  published_at timestamptz,
  video_verified boolean,
  rank real
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_q   text := nullif(trim(coalesce(p_query, '')), '');
  v_lim int := least(greatest(coalesce(p_limit, 24), 1), 60);
  v_off int := greatest(coalesce(p_offset, 0), 0);
  v_tsq tsquery;
begin
  if p_type is not null and p_type not in ('auction','fixed','bazaar') then
    raise exception 'invalid_listing_type';
  end if;

  if v_q is not null then
    -- websearch_to_tsquery is forgiving of arbitrary user input.  We pin
    -- the en_US system locale on the query path via f_unaccent (which is
    -- IMMUTABLE).
    v_tsq := websearch_to_tsquery('simple', public.f_unaccent(v_q));
  end if;

  return query
  select
    l.id, l.seller_id, l.type, l.title_translations, l.description_translations,
    l.category_id, l.condition, l.images, l.starting_price, l.buy_now_price,
    l.current_high, l.bid_count, l.view_count, l.current_close_at,
    l.published_at, l.video_verified,
    case when v_tsq is null then 0::real
         else ts_rank(l.search_vector, v_tsq) end as rank
  from listings l
  where l.status = 'active'
    and (p_category_id is null or l.category_id = p_category_id)
    and (p_type        is null or l.type        = p_type)
    and (p_has_buy_now is null
         or (p_has_buy_now and l.buy_now_price is not null)
         or (not p_has_buy_now and l.buy_now_price is null))
    and (p_min_price is null or coalesce(l.buy_now_price, l.starting_price) >= p_min_price)
    and (p_max_price is null or coalesce(l.buy_now_price, l.starting_price) <= p_max_price)
    and (v_tsq is null or l.search_vector @@ v_tsq)
  order by
    case when v_tsq is null then 0::real
         else ts_rank(l.search_vector, v_tsq) end desc,
    coalesce(l.published_at, l.created_at) desc
  limit v_lim offset v_off;
end;
$$;

revoke all on function public.search_listings(text, uuid, text, boolean, bigint, bigint, int, int) from public;
grant execute on function public.search_listings(text, uuid, text, boolean, bigint, bigint, int, int) to authenticated, anon;

-- ─── home_feed_ending_soon ──────────────────────────────────────────────
-- Active auction + bazaar listings ordered by current_close_at ascending.
-- Phase 2 has no bid traffic yet but the ordering is stable and the same
-- query will keep working once the bid sweep starts updating close times.
create or replace function public.home_feed_ending_soon(p_limit int default 12)
returns setof listings
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select *
  from listings
  where status = 'active'
    and type in ('auction','bazaar')
    and current_close_at is not null
  order by current_close_at asc nulls last
  limit least(greatest(coalesce(p_limit, 12), 1), 30);
$$;

grant execute on function public.home_feed_ending_soon(int) to authenticated, anon;

-- ─── home_feed_hot ─────────────────────────────────────────────────────
-- Phase 2: most-viewed active listings.  Phase 3+ will weight by bid
-- velocity once that data exists.
create or replace function public.home_feed_hot(p_limit int default 12)
returns setof listings
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select *
  from listings
  where status = 'active'
  order by view_count desc, published_at desc nulls last
  limit least(greatest(coalesce(p_limit, 12), 1), 30);
$$;

grant execute on function public.home_feed_hot(int) to authenticated, anon;

-- ─── home_feed_bazaar ──────────────────────────────────────────────────
create or replace function public.home_feed_bazaar(p_limit int default 12)
returns setof listings
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select *
  from listings
  where status = 'active' and type = 'bazaar'
  order by published_at desc nulls last
  limit least(greatest(coalesce(p_limit, 12), 1), 30);
$$;

grant execute on function public.home_feed_bazaar(int) to authenticated, anon;

-- ─── get_listing_for_analysis (security definer; used by Edge Function) ─
-- Returns the listing's image paths + seller_id so the analyze_item Edge
-- Function can validate paths and construct public URLs without exposing
-- our schema to clients.  Callable only with the service-role key from
-- the Edge Function — REVOKE from everyone else.
create or replace function public.get_listing_for_analysis(p_id uuid)
returns table (
  id uuid,
  seller_id uuid,
  type text,
  images jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select id, seller_id, type, images
  from listings
  where id = p_id and status = 'draft';
$$;

revoke all on function public.get_listing_for_analysis(uuid) from public;
-- Only service_role calls this from the Edge Function.
grant execute on function public.get_listing_for_analysis(uuid) to service_role;
