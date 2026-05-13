-- Feature-flag table + helper.  Architecture.md §11 (Phase 0 acceptance).

create table feature_flags (
  name text primary key,
  enabled boolean not null default false,
  description text,
  updated_at timestamptz not null default now()
);

alter table feature_flags enable row level security;

create policy "feature_flags_public_read"
  on feature_flags for select using (true);

-- Helper: `select feature_flag('whatsapp_notifications')` returns boolean.
-- Treats missing flags as disabled (fail closed).
create or replace function feature_flag(p_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select enabled from feature_flags where name = p_name),
    false
  );
$$;
