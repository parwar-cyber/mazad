---
name: auto-update
description: Use when implementing app version checks, force-update flows, backend min-version gating, Shorebird code push, Google Play in-app updates on Android, App Store update prompts on iOS, or PWA service-worker update banners on web. Provides the layered update strategy that gives ops a kill switch over the entire client fleet from the database.
---

# Auto-update & Version Gating

The single most important production safety feature in this app. If we ship a broken bid client that's losing users money, we need to force every client to upgrade within seconds — not wait for App Store review.

## The three layers

1. **Backend min-version gate** — the kill switch. Every Edge Function checks `App-Version` header against `min_supported_version` in the `app_versions` table. Returns 426 if too old. **Build this in Phase 0.**
2. **Shorebird code push** — hotfix Dart code without App Store review. Use for non-native fixes. **Add in Phase 5.**
3. **Platform update prompts** — Google Play in-app updates (Android), App Store deep-link banners (iOS), PWA service-worker update banner (web). **Add in Phase 9.**

The version gate is non-negotiable. Shorebird and platform prompts are improvements layered on top.

---

## Layer 1: Backend min-version gate

### Database schema

```sql
create table app_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('ios', 'android', 'web')),
  current_version text not null,           -- semver, e.g. "1.4.2"
  min_supported_version text not null,     -- semver
  release_notes_translations jsonb,        -- {en, ar, ku, tr}
  released_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(platform)
);

-- RLS: anyone can read, only admin can write
alter table app_versions enable row level security;

create policy "anyone reads app_versions"
  on app_versions for select using (true);

create policy "admin writes app_versions"
  on app_versions for all to service_role using (true);

-- Seed
insert into app_versions (platform, current_version, min_supported_version) values
  ('ios', '1.0.0', '1.0.0'),
  ('android', '1.0.0', '1.0.0'),
  ('web', '1.0.0', '1.0.0');
```

### Edge Function middleware

Every Edge Function calls this first:

```typescript
// supabase/functions/_shared/version_check.ts
import { createClient } from 'npm:@supabase/supabase-js';

export async function checkAppVersion(req: Request): Promise<Response | null> {
  const appVersion = req.headers.get('App-Version');
  const platform = req.headers.get('App-Platform'); // 'ios' | 'android' | 'web'

  if (!appVersion || !platform) {
    return new Response(JSON.stringify({ error: 'missing_version_headers' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await supabase
    .from('app_versions')
    .select('min_supported_version, current_version, release_notes_translations')
    .eq('platform', platform)
    .single();

  if (error || !data) return null; // fail open in case of DB error

  if (compareSemver(appVersion, data.min_supported_version) < 0) {
    return new Response(JSON.stringify({
      error: 'upgrade_required',
      min_supported_version: data.min_supported_version,
      current_version: data.current_version,
      release_notes: data.release_notes_translations,
      store_url: storeUrlFor(platform),
    }), {
      status: 426, // Upgrade Required
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return null; // allowed to proceed
}

function compareSemver(a: string, b: string): number {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if ((pa[i] ?? 0) !== (pb[i] ?? 0)) return (pa[i] ?? 0) - (pb[i] ?? 0);
  }
  return 0;
}

function storeUrlFor(platform: string): string {
  switch (platform) {
    case 'ios': return 'https://apps.apple.com/app/idXXXXX';
    case 'android': return 'https://play.google.com/store/apps/details?id=com.mazad.app';
    case 'web': return 'https://app.mazad.iq';
    default: return '';
  }
}
```

Use it at the top of every Edge Function:

```typescript
// supabase/functions/place_bid/index.ts
import { checkAppVersion } from '../_shared/version_check.ts';

Deno.serve(async (req) => {
  const versionBlock = await checkAppVersion(req);
  if (versionBlock) return versionBlock;
  // ... rest of the function
});
```

### Flutter HTTP interceptor

```dart
// app/lib/core/network/version_interceptor.dart
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class VersionInterceptor extends Interceptor {
  late final String _version;
  late final String _platform;

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version; // e.g. "1.0.0"
    _platform = _detectPlatform();
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['App-Version'] = _version;
    options.headers['App-Platform'] = _platform;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 426) {
      final data = err.response?.data as Map<String, dynamic>?;
      // Push the force-update screen via a global router event
      ForceUpdateNotifier.show(
        minVersion: data?['min_supported_version'],
        storeUrl: data?['store_url'],
        releaseNotes: data?['release_notes'],
      );
      // Do NOT continue with the request — the app is blocked.
      return;
    }
    handler.next(err);
  }
}
```

For Supabase client requests, use the same headers via `headers` option on `SupabaseClient` initialization.

### Force-update screen

A blocking screen that cannot be dismissed:

```dart
// app/lib/features/system/force_update_screen.dart
class ForceUpdateScreen extends StatelessWidget {
  final String storeUrl;
  final Map<String, dynamic>? releaseNotes;

  const ForceUpdateScreen({super.key, required this.storeUrl, this.releaseNotes});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async => false, // cannot back out
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_update, size: 64),
                const SizedBox(height: 16),
                Text(l10n.updateRequiredTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.updateRequiredBody, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse(storeUrl)),
                  child: Text(l10n.updateNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

ARB string keys: `updateRequiredTitle`, `updateRequiredBody`, `updateNow` — translated in all 4 locales per the `i18n-rtl` skill.

### How to use the kill switch in production

When you ship a bad version 1.4.2 and need to force-upgrade everyone:

```sql
update app_versions
   set min_supported_version = '1.4.3',
       current_version = '1.4.3',
       updated_at = now()
 where platform = 'android';
```

Every client running ≤1.4.2 hits 426 on the next API call and sees the force-update screen. Use sparingly — too-aggressive use erodes trust.

---

## Layer 2: Shorebird (code push for Flutter)

Shorebird lets you push Dart code updates without going through App Store review. Critical for hotfixes.

### Setup

```bash
# Install Shorebird CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -ssf | sh

# Initialize in the Flutter app
cd app
shorebird init
```

This adds a `shorebird.yaml` next to `pubspec.yaml`.

### Release workflow

```bash
# Initial release (replaces flutter build + upload)
shorebird release android
shorebird release ios

# Push a patch later (replaces hotfix release)
shorebird patch android
shorebird patch ios
```

### What Shorebird can and cannot do

- ✅ Patch Dart code — bug fixes, logic changes, UI tweaks
- ✅ Patch assets (images, ARB translations) bundled with the app
- ❌ Patch native code (iOS Swift/ObjC, Android Java/Kotlin, native plugins)
- ❌ Patch dependencies (pubspec.yaml changes)

If a hotfix requires native or dependency changes, you must do a full app store release.

### iOS App Store policy

Apple historically restricted code push. Shorebird operates within Apple's current rules (no executable code download — uses precompiled binary patches). Read Shorebird's iOS notes before shipping.

### Workflow for production hotfix

1. Reproduce the bug locally.
2. Fix in Dart only (no native, no new deps).
3. Run regression tests.
4. `shorebird patch android` and `shorebird patch ios`.
5. Monitor Sentry for the next 30 minutes — rollback the patch if error rates spike.

### Rollback

```bash
shorebird patch --rollback android
```

Within seconds, clients revert to the previous patch level.

---

## Layer 3: Platform update prompts (non-blocking)

For *recommended* updates (current version > installed version, but installed >= min), prompt the user.

### Android — Google Play In-App Updates

```dart
// app/pubspec.yaml
// in_app_update: ^4.2.0

import 'package:in_app_update/in_app_update.dart';

Future<void> checkAndroidUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable) {
      // For non-critical: flexible update (background download)
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    }
  } catch (e) {
    // log but don't block app
  }
}
```

Call on app start, but not on every cold launch — gate by "checked within last 24h."

### iOS — App Store deep-link prompt

Apple does not expose a native API for triggering in-app updates. Pattern:

1. On app start, call `/version` Edge Function to learn the latest version.
2. If installed < current and installed >= min, show a dismissible banner.
3. Tap → deep-link to App Store: `itms-apps://apps.apple.com/app/id{APP_ID}`.

```dart
Future<void> checkIosUpdate() async {
  if (!Platform.isIOS) return;
  final latest = await VersionService.fetchLatest('ios');
  final installed = (await PackageInfo.fromPlatform()).version;
  if (compareSemver(installed, latest) < 0) {
    UpdateBannerService.show(
      message: AppLocalizations.of(context).updateAvailableMessage,
      onTap: () => launchUrl(Uri.parse('itms-apps://apps.apple.com/app/id$appId')),
    );
  }
}
```

### Web — PWA service worker update banner

```javascript
// app/web/sw.js or via Workbox
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
```

In the Flutter web app:

```dart
// Listen for the controllerchange event in JS interop
// Show "A new version is available — tap to reload" banner
```

When user taps reload, `window.location.reload()` picks up the new bundle.

---

## Semantic versioning

Use semver strictly: `MAJOR.MINOR.PATCH`.

- **MAJOR**: breaking schema or RPC contract changes. Bump `min_supported_version`.
- **MINOR**: new features, backward compatible. Do not bump min.
- **PATCH**: bug fixes only. Do not bump min.

Build numbers (`+1`, `+2` in `pubspec.yaml`) increment per release; visible only to platform stores.

## Release checklist

Before bumping `min_supported_version`:

- [ ] Confirm the breaking change is severe enough to force users off old versions.
- [ ] The release notes are translated in all 4 locales.
- [ ] You've checked active usage of old versions in PostHog — know how many users you'll force-upgrade.
- [ ] You have a rollback plan if the new version itself is broken (revert `min_supported_version` to previous value).

## What this skill prevents

- Shipping a bad bid RPC and being stuck while 30k users continue placing wrong bids during App Store review.
- Users on a year-old version hitting RPCs that have schema-incompatible inputs.
- Force-update flows that aren't translated for Arabic/Kurdish/Turkish users.
- "Update available" prompts that are nagging or non-dismissible for non-critical updates.

## What to refuse

- Force-update flows triggered from client logic alone (must come from server 426).
- Min-version bumps without checking release notes are translated.
- Shorebird patches that touch native code or dependencies (will silently fail).
- Hardcoded App Store / Play Store URLs scattered across the codebase — centralize in `storeUrlFor()`.

## File locations in our repo

- Schema: `supabase/migrations/{timestamp}_app_versions.sql`
- Middleware: `supabase/functions/_shared/version_check.ts`
- Interceptor: `app/lib/core/network/version_interceptor.dart`
- Force-update screen: `app/lib/features/system/force_update_screen.dart`
- Update banner service: `app/lib/features/system/update_banner_service.dart`
- Shorebird config: `app/shorebird.yaml`
