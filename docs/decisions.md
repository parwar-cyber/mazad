# Architecture Decision Records (ADRs)

Append-only. Each decision gets a numbered entry. Never edit historical entries — supersede with a new one.

---

## ADR-0001: Stack lock-in (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

**Context**: Need to commit to a single stack before scaffolding. Spec already names choices; this ADR records the lock so reviewers don't relitigate.

**Decision**:
- **Client**: Flutter 3.x, Dart 3.x, Riverpod 2 (with `riverpod_generator`), GoRouter, `flutter_localizations` + ARB files.
- **HTTP**: Supabase Dart client for backend; `dio` only for external APIs (and to host the `VersionInterceptor` for non-Supabase calls).
- **Backend**: Supabase (Postgres + Auth + Realtime + Storage + Edge Functions on Deno).
- **Observability**: Sentry (errors) + PostHog (analytics, feature flags client-side).
- **Push**: Firebase Cloud Messaging via `firebase_messaging` (added in Phase 5; deps deferred).
- **Admin console**: Next.js on Vercel (placeholder folder only at Phase 0).

**Alternatives considered**: React Native (rejected — weaker RTL story, two codegen toolchains), Firebase backend (rejected — weaker SQL/RLS story for an auction app with strict bid invariants).

---

## ADR-0002: Money handling (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

All IQD amounts are integers — `bigint` in Postgres, `int` in Dart, `bigint` in TypeScript. No `double`, `decimal`, `numeric`, or JS `Number` anywhere in the money path. Formatting only via `core/money/formatIQD`. See `.claude/skills/money-handling/SKILL.md`.

---

## ADR-0003: Internationalization & RTL (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Four launch locales: `en`, `ar`, `ku`, `tr`. `ar` and `ku` are RTL. ARB files for all static strings; UGC stored as JSONB `{en, ar, ku, tr}`. System-level case operations (slugs, search normalization, uniqueness checks) pinned to `en_US` to avoid the Turkish dotted/dotless `i` bug. See `.claude/skills/i18n-rtl/SKILL.md`.

---

## ADR-0004: Backend version-gating (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Every Edge Function calls `checkAppVersion(req)` first. Flutter client sends `App-Version` + `App-Platform` headers via `VersionInterceptor` (Dio) and `headers` option on the Supabase client. Server responds 426 if `App-Version < min_supported_version`. Client renders blocking `ForceUpdateScreen`. Shorebird and platform prompts layer on later (Phase 5 / Phase 9). See `.claude/skills/auto-update/SKILL.md`.

---

## ADR-0005: Design tokens — "Tigris" palette (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

**Context**: `frontend-design` skill demands distinctive, non-AI-default choices. Default Material 3 baseline (purple/teal) feels generic; pure Iraqi-flag green/red feels touristic. Tested several palettes in the splash + force-update screens.

**Decision**: Dark-first "Tigris" palette.

| Token | Dark | Light |
|---|---|---|
| `primary` | `#D4A04C` (warm muted gold) | `#A87A2C` |
| `onPrimary` | `#0E1116` | `#FFFBF2` |
| `background` | `#0E1116` (near-black, faint blue cast) | `#FBF8F2` (warm paper) |
| `surface` | `#171B22` | `#FFFFFF` |
| `onSurface` | `#EDE6D6` | `#1A1614` |
| `outline` | `#2A2F38` | `#D9D4C7` |
| `success` | `#5BA98F` (muted teal — "bid up") | same |
| `error` | `#E04E3D` (warm crimson — "outbid") | same |
| `info` | `#7DA9D8` (cool slate blue) | same |

**Typography**:
- Latin (en/tr): **Inter** — body 400, headings 700, display has `-0.02em` letter-spacing.
- Arabic-script (ar/ku): **Vazirmatn** (covers Sorani glyphs).
- Numeric values (prices, bids, countdowns): tabular figures (`FontFeature.tabularFigures()`).

**Why**:
- Gold + near-black evokes auction/value without screaming "Iraq souk."
- Muted teal for "going up" reads safer than green-vs-red colorblind clash.
- Tabular figures eliminate price jitter in live bid feeds.

**Tokens live in**: `app/lib/core/design/tokens.dart`. **Never inline** colors, spacing, or font sizes.

---

## ADR-0006: Dependency policy (Phase 0)

**Date**: 2026-05-12
**Status**: Accepted

Every new Dart or npm dependency is a security surface and a maintenance cost. Before adding one:
1. Confirm it's needed (not just convenient).
2. Add to this file with a one-line justification.
3. Pin a version.

Phase 0 dependencies (Flutter app):

| Package | Why |
|---|---|
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | State management (ADR-0001) |
| `go_router` | Routing (ADR-0001) |
| `supabase_flutter` | Backend client (ADR-0001) |
| `dio` | External HTTP + host for `VersionInterceptor` |
| `package_info_plus` | Reads installed app version for `App-Version` header |
| `intl` | Locale-aware number/date formatting |
| `flutter_localizations` (SDK) | ARB-driven `AppLocalizations` |
| `google_fonts` | Inter + Vazirmatn at runtime (acceptable for Phase 0; bundle fonts as a Phase 9 polish task) |
| `url_launcher` | Open App Store / Play Store from `ForceUpdateScreen` |
| `build_runner` (dev) | Code generation for Riverpod |
| `flutter_lints` (dev) | Lints |

Deferred to later phases (do **not** install at Phase 0): `sentry_flutter`, `firebase_messaging`, `posthog_flutter`, `cached_network_image`, `mapbox_gl`, `in_app_update`, `shorebird_code_push`.

---

## Open refactor TODOs

- Bundle Inter + Vazirmatn as repo assets instead of `google_fonts` runtime fetch — improves cold-start, removes external dependency at boot. Phase 9 polish task.
- Consider replacing Dio's `VersionInterceptor` with a Supabase-only client interceptor once all backend calls go through Edge Functions (no external Dio surface remains).

---

## Local setup (engineer onboarding)

```bash
# Flutter (FVM recommended)
brew install --cask flutter
flutter --version  # require >= 3.24

# Supabase CLI
brew install supabase/tap/supabase

# Deno (for Edge Functions)
brew install deno

# just (task runner)
brew install just

# Project bootstrap
cd app && flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
cd ../supabase && supabase start && supabase db reset
```
