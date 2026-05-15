# Mazad — dev commands
# Install `just`: brew install just

set shell := ["bash", "-cu"]

# Default: show available recipes
default:
    @just --list

# --- Flutter app ---

# Run app for current device
dev:
    cd app && flutter run

# Build web (PWA)
build-web:
    cd app && flutter build web --release

# Build Android APK
build-android:
    cd app && flutter build apk --release

# Build iOS (requires macOS + Xcode)
build-ios:
    cd app && flutter build ios --release --no-codesign

# Regenerate ARB / Riverpod / freezed code
codegen:
    cd app && flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs

# Run all Flutter tests
test:
    cd app && flutter test

# Run only money math tests
test-money:
    cd app && flutter test test/core/money_test.dart

# Format + analyze
lint:
    cd app && dart format --set-exit-if-changed lib test && flutter analyze

# --- Supabase ---

# Start local Supabase stack
db-up:
    supabase start

# Apply migrations to local DB
db-migrate:
    supabase db push

# Reset local DB (drop + re-apply all migrations + seed)
db-reset:
    supabase db reset

# Generate Dart types from Postgres schema (Phase 2+)
db-types:
    supabase gen types typescript --local > supabase/types.ts

# Deploy all Edge Functions to remote project
functions-deploy:
    supabase functions deploy

# Deploy one Edge Function (usage: just functions-deploy-one place_bid)
functions-deploy-one fn:
    supabase functions deploy {{fn}}

# Tail logs for one Edge Function
functions-logs fn:
    supabase functions logs {{fn}} --tail

# Phase 3 — Postgres integration tests for the bidding engine.
# Runs the place_bid RPC under concurrency (50 bidders) + Smart Close +
# proxy + RLS + error-case scenarios against the local supabase stack.
# Requires `supabase start` first.
test-bidding:
    cd supabase/tests && deno test --no-check \
      --allow-net --allow-env --allow-read --allow-sys --allow-write \
      phase3_bidding_test.ts
