-- ─────────────────────────────────────────────────────────────────────────
-- Mazad — initial schema  (architecture.md §5)
--
-- Money: bigint (see money-handling skill).
-- IDs:   uuid.
-- Time:  timestamptz.
-- RLS:   enabled on every user-touched table in this migration; default-deny.
--        Read/write policies live in the next migration to keep diffs small.
-- ─────────────────────────────────────────────────────────────────────────

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists unaccent;
create extension if not exists btree_gin;

-- ─── Identity & profiles ────────────────────────────────────────────────
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  pseudonym text unique,
  avatar_url text,
  phone text unique,
  locale text not null default 'en' check (locale in ('en','ar','ku','tr')),
  city text,
  kyc_tier int not null default 0 check (kyc_tier between 0 and 2),
  trust_score numeric not null default 0,
  whatsapp_phone text,
  whatsapp_opt_in boolean not null default false,
  sms_opt_in boolean not null default true,
  email text,
  notification_prefs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  last_active_at timestamptz
);
alter table profiles enable row level security;

create table seller_profiles (
  user_id uuid primary key references profiles(id) on delete cascade,
  business_name text,
  id_doc_url text,
  address jsonb,
  payout_method text check (payout_method in ('zaincash','fastpay','bank','cod')),
  payout_account jsonb,
  float_balance bigint not null default 0, -- IQD; may go negative for COD overdraft
  verified_at timestamptz,
  total_sold bigint not null default 0,
  dispute_count int not null default 0
);
alter table seller_profiles enable row level security;

-- ─── Catalog ────────────────────────────────────────────────────────────
create table categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  parent_id uuid references categories(id) on delete set null,
  name_translations jsonb not null,
  spec_schema jsonb not null default '{}'::jsonb,
  check (name_translations ?| array['en','ar','ku','tr'])
);
alter table categories enable row level security;

create table listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references profiles(id) on delete restrict,
  type text not null check (type in ('auction','fixed','bazaar')),
  title_translations jsonb not null,
  description_translations jsonb not null default '{}'::jsonb,
  category_id uuid references categories(id),
  condition text check (condition in ('new','like_new','good','fair','for_parts')),
  specs jsonb not null default '{}'::jsonb,
  images jsonb not null default '[]'::jsonb,
  video_url text,
  video_verified boolean not null default false,
  video_verification_meta jsonb,
  location jsonb,                              -- {city, lat, lng}
  status text not null default 'draft'
    check (status in ('draft','pending_review','active','sold','expired','cancelled')),
  starting_price bigint not null check (starting_price >= 0),
  buy_now_price bigint check (buy_now_price is null or buy_now_price >= 0),
  reserve_price bigint check (reserve_price is null or reserve_price >= 0),
  currency text not null default 'IQD',
  -- Smart Close fields (architecture.md §6.2)
  discovery_ends_at timestamptz,
  smart_close_window interval not null default interval '12 hours',
  current_close_at timestamptz,
  hard_close_at timestamptz,
  current_high bigint,
  current_high_bidder_id uuid references profiles(id),
  bid_count int not null default 0,
  watch_count int not null default 0,
  view_count int not null default 0,
  created_at timestamptz not null default now(),
  published_at timestamptz,
  -- Invariants
  check (title_translations ?| array['en','ar','ku','tr']),
  check (type <> 'bazaar' or starting_price <= 10000),   -- Group Bazaar ≤ 10k IQD
  check (buy_now_price is null or buy_now_price >= starting_price)
);
alter table listings enable row level security;

create index listings_status_idx on listings(status);
create index listings_seller_idx on listings(seller_id);
create index listings_close_idx on listings(current_close_at) where status = 'active';

-- ─── Bidding ────────────────────────────────────────────────────────────
create table bids (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings(id) on delete cascade,
  bidder_id uuid not null references profiles(id),
  amount bigint not null check (amount > 0),
  max_amount bigint check (max_amount is null or max_amount >= amount),
  source text not null default 'app' check (source in ('app','web','whatsapp')),
  is_proxy boolean not null default false,
  status text not null default 'valid' check (status in ('valid','retracted','rejected')),
  ip_hash text,
  device_id text,
  created_at timestamptz not null default now()
);
alter table bids enable row level security;
create index bids_listing_idx on bids(listing_id, created_at desc);
create index bids_bidder_idx on bids(bidder_id, created_at desc);

create table watches (
  user_id uuid not null references profiles(id) on delete cascade,
  listing_id uuid not null references listings(id) on delete cascade,
  notify_channels jsonb not null default '{"push":true,"sms":false,"whatsapp":false,"email":false}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
alter table watches enable row level security;

-- ─── Group Bazaar ───────────────────────────────────────────────────────
create table group_deals (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null unique references listings(id) on delete cascade,
  tiers jsonb not null,                        -- [{participants, price}]
  current_participants int not null default 0,
  current_tier_index int not null default 0,
  floor_price bigint not null check (floor_price > 0 and floor_price <= 10000),
  expires_at timestamptz not null
);
alter table group_deals enable row level security;

create table deal_signups (
  deal_id uuid not null references group_deals(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  signed_up_at timestamptz not null default now(),
  committed boolean not null default false,
  primary key (deal_id, user_id)
);
alter table deal_signups enable row level security;

-- ─── Orders, payments, shipping ─────────────────────────────────────────
create table orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references profiles(id),
  seller_id uuid not null references profiles(id),
  listing_id uuid not null references listings(id),
  hammer_price bigint not null check (hammer_price >= 0),
  buyer_premium bigint not null default 0 check (buyer_premium >= 0),
  platform_fee bigint not null default 0 check (platform_fee >= 0),
  delivery_fee bigint not null default 0 check (delivery_fee >= 0),
  total bigint not null check (total >= 0),
  status text not null default 'pending'
    check (status in ('pending','paid','shipped','delivered','released','refunded','disputed')),
  payment_method text,
  shipping_address jsonb,
  invoice_url text,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  shipped_at timestamptz,
  delivered_at timestamptz,
  released_at timestamptz
);
alter table orders enable row level security;

create table payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  provider text not null check (provider in ('zaincash','fastpay','fib','cod')),
  provider_ref text,
  status text not null check (status in ('pending','captured','failed','refunded')),
  amount bigint not null check (amount >= 0),
  captured_at timestamptz
);
alter table payments enable row level security;

create table shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  courier text,
  tracking_ref text,
  label_url text,
  cost bigint not null default 0 check (cost >= 0),
  status text,
  dispatched_at timestamptz,
  delivered_at timestamptz
);
alter table shipments enable row level security;

-- ─── Reputation & trust ─────────────────────────────────────────────────
create table reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  reviewer_id uuid not null references profiles(id),
  reviewee_id uuid not null references profiles(id),
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (order_id, reviewer_id)
);
alter table reviews enable row level security;

create table vouches (
  voucher_id uuid not null references profiles(id) on delete cascade,
  vouchee_id uuid not null references profiles(id) on delete cascade,
  weight numeric not null default 1,
  created_at timestamptz not null default now(),
  primary key (voucher_id, vouchee_id),
  check (voucher_id <> vouchee_id)
);
alter table vouches enable row level security;

create table disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  raised_by uuid not null references profiles(id),
  reason text not null,
  evidence_urls jsonb not null default '[]'::jsonb,
  status text not null default 'open'
    check (status in ('open','investigating','resolved','closed')),
  resolution text,
  assigned_to uuid references profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
alter table disputes enable row level security;

-- ─── Notifications (multi-channel, 4-language) ──────────────────────────
create table notification_templates (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  locale text not null check (locale in ('en','ar','ku','tr')),
  channel text not null check (channel in ('push','sms','email','whatsapp')),
  subject text,
  body text not null,
  variables jsonb not null default '[]'::jsonb,
  unique (kind, locale, channel)
);
alter table notification_templates enable row level security;

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  kind text not null,
  payload jsonb not null default '{}'::jsonb,
  channels jsonb not null default '{}'::jsonb,
  push_sent_at timestamptz,
  sms_sent_at timestamptz,
  whatsapp_sent_at timestamptz,
  email_sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
alter table notifications enable row level security;
create index notifications_user_idx on notifications(user_id, created_at desc);

-- ─── WhatsApp (deferred but schema ready) ───────────────────────────────
create table whatsapp_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  phone text not null,
  active_listing_id uuid references listings(id),
  last_message_at timestamptz
);
alter table whatsapp_threads enable row level security;

create table whatsapp_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references whatsapp_threads(id) on delete cascade,
  direction text not null check (direction in ('in','out')),
  body text not null,
  intent text,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);
alter table whatsapp_messages enable row level security;

-- ─── Fee engine ─────────────────────────────────────────────────────────
create table fee_rules (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('global','category','seller')),
  scope_id uuid,
  listing_fee bigint not null default 0 check (listing_fee >= 0),
  success_fee_pct numeric not null default 7 check (success_fee_pct >= 0 and success_fee_pct <= 100),
  buyer_premium_pct numeric not null default 0 check (buyer_premium_pct >= 0 and buyer_premium_pct <= 100),
  active_from timestamptz not null default now(),
  active_until timestamptz
);
alter table fee_rules enable row level security;

-- ─── Audit ──────────────────────────────────────────────────────────────
create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text not null,
  target text,
  metadata jsonb not null default '{}'::jsonb,
  at timestamptz not null default now()
);
alter table audit_logs enable row level security;
create index audit_logs_actor_idx on audit_logs(actor_id, at desc);
