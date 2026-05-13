-- Seed data for local dev.  `supabase db reset` will replay this after
-- migrations.  Production seeding is separate (handled in admin console).

-- App versions baseline (the kill-switch row).  See auto-update skill.
insert into app_versions (platform, current_version, min_supported_version)
values
  ('ios',     '1.0.0', '1.0.0'),
  ('android', '1.0.0', '1.0.0'),
  ('web',     '1.0.0', '1.0.0')
on conflict (platform) do nothing;

-- Feature flags baseline.  All deferred capabilities default OFF.
insert into feature_flags (name, enabled, description) values
  ('whatsapp_notifications', false, 'Phase 10 — WhatsApp dispatch path.'),
  ('eastern_arabic_numerals', false, 'Per-user opt-in lives on profile; this is the global enable.'),
  ('shorebird_code_push',    false, 'Layer 2 of auto-update (Phase 5+).')
on conflict (name) do nothing;

-- Launch categories (per architecture.md §13 open question 3 — go narrow).
insert into categories (slug, name_translations) values
  ('phones',       '{"en":"Phones","ar":"هواتف","ku":"مۆبایل","tr":"Telefonlar"}'::jsonb),
  ('fashion',      '{"en":"Fashion","ar":"أزياء","ku":"فاشن","tr":"Moda"}'::jsonb),
  ('collectibles', '{"en":"Collectibles","ar":"مقتنيات","ku":"کۆکراوەکان","tr":"Koleksiyon"}'::jsonb),
  ('home-goods',   '{"en":"Home goods","ar":"لوازم منزلية","ku":"کەلوپەلی ماڵ","tr":"Ev eşyaları"}'::jsonb)
on conflict (slug) do nothing;
