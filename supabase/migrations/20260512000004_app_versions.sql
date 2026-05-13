-- app_versions table.  Per auto-update skill — the backend kill switch.
--
-- Reads are public so the splash screen / unauthenticated endpoints can
-- enforce min-version gating.  Writes are service-role only (handled by
-- the admin console).

create table app_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('ios','android','web')),
  current_version text not null,                -- semver, e.g. "1.4.2"
  min_supported_version text not null,          -- semver
  release_notes_translations jsonb not null default '{}'::jsonb,  -- {en,ar,ku,tr}
  released_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform)
);

alter table app_versions enable row level security;

create policy "app_versions_public_read"
  on app_versions for select using (true);

-- Touch updated_at on every change (so clients can cache-bust).
create or replace function app_versions_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger app_versions_touch
  before update on app_versions
  for each row execute function app_versions_touch_updated_at();
