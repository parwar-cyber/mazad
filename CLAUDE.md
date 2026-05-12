# CLAUDE.md

> Project orientation for Claude Code. Read this at the start of every session.
> Last updated: 2026-05-12

## What this project is

**Mazad** is a four-language (English, Arabic, Sorani Kurdish, Turkish) auction marketplace for Iraq. Three sale modes: auction with Smart Close, fixed-price Buy Now, and Group Bazaar (under 10k IQD). Cross-platform: iOS + Android + Web from a single Flutter codebase.

**Always read first**:
- `docs/architecture.md` — the build spec. Phase plan, data model, key flows.
- `docs/decisions.md` — architecture decision records.

## Tech stack (do not change without an ADR in `decisions.md`)

- **Client**: Flutter 3.x, Dart, Riverpod 2 (with code-gen), GoRouter, flutter_intl
- **Backend**: Supabase — Postgres, Auth, Realtime, Storage, Edge Functions (Deno)
- **AI**: Gemini (vision + text) via REST API in Edge Functions
- **Notifications**: FCM (push), Twilio/Vonage (SMS), Resend (email), WhatsApp (deferred, feature-flagged)
- **Admin console**: Next.js on Vercel
- **Observability**: Sentry, PostHog

**Hard rules on stack choices**:
- State: Riverpod 2 only. No Provider, no Bloc, no Redux.
- Routing: GoRouter only. No Navigator 1.0 named routes.
- HTTP: Supabase client for backend; `dio` only when calling external APIs.

## Skills installed in this repo

Relevant skills load automatically when their description matches the task.

**Official / community skills**:
- `supabase` and `supabase-postgres-best-practices` — Supabase RLS, migrations, edge functions, Postgres performance. Installed via `npx skills add supabase/agent-skills`.
- `flutter-tester` and `owasp-mobile-security-checker` — Flutter testing patterns (incl. Riverpod) and OWASP Mobile Top 10 audit. From `Harishwarrior/flutter-claude-skills` at `.claude/skills/flutter-claude-skills/`.
- `frontend-design` — anti-AI-slop UI patterns. From `anthropics/skills`.
- `interface-design` — persisted design system across sessions. From `Dammyjay93/interface-design`.
- `vibesec` — IDOR / XSS / SQL injection / SSRF / auth weakness checks. At `.claude/skills/vibesec/`.
- `gemini-api-dev` — Gemini API best practices. From `google-gemini/`.

**Project-custom skills** (in this repo at `.claude/skills/`):
- `money-handling` — IQD-as-bigint rules, locale-aware currency formatting, fee/escrow math.
- `i18n-rtl` — 4-language (en/ar/ku/tr) handling, RTL layout, the Turkish dotted/dotless `i` bug class, font stacks.
- `auto-update` — backend min-version gate, Shorebird code push, in-app update prompts.

## Repository layout

```
/
├── CLAUDE.md                    ← this file
├── docs/
│   ├── architecture.md          ← the spec
│   ├── decisions.md             ← ADRs
│   └── runbook.md               ← ops procedures
├── .claude/
│   └── skills/                  ← project-discoverable skills
│       ├── money-handling/
│       ├── i18n-rtl/
│       ├── auto-update/
│       ├── flutter-claude-skills/      (cloned)
│       └── vibesec/                    (cloned)
├── app/                         ← Flutter app
│   ├── lib/
│   │   ├── features/            ← feature-first (auth, listings, bidding, orders, …)
│   │   └── core/                ← design tokens, i18n, money, network, widgets
│   └── test/
├── supabase/
│   ├── migrations/              ← timestamped SQL files
│   ├── functions/               ← Edge Functions
│   └── seed.sql
├── admin/                       ← Next.js admin console
└── justfile                     ← all dev commands
```

## Universal non-negotiables

These rules must never break. If a task appears to require breaking one of them, **stop and surface the conflict before proceeding**.

### Money

- **All IQD amounts are `bigint`. Never `float`, `double`, `number`, or `decimal`.**
- Format only via `formatIQD()` from `core/money`. Never inline.
- Server re-validates every amount. Client values are display-only.
- See `.claude/skills/money-handling/SKILL.md`.

### Security

- All mutations go through Postgres RPCs (`security definer`) that validate `auth.uid()`.
- RLS is default-deny on every table. New table = new policies in the same migration.
- Secrets only via environment variables. Never commit `.env`, never hardcode keys.
- All file uploads through signed URLs with mime + size validation.
- Rate limit OTP (3/hour, 10/day per phone) and bids (10/minute per user).
- See `vibesec`, `supabase`, and `owasp-mobile-security-checker` skills.

### Internationalization (4 languages)

- Supported: `en` (LTR Latin), `ar` (RTL Arabic), `ku` (RTL Sorani Kurdish), `tr` (LTR Latin Turkish).
- Every user-visible string goes through `intl` ARB files. **No hardcoded text.**
- UGC fields are JSONB `{en, ar, ku, tr}`.
- **Turkish bug class**: standard `.toLowerCase()` / `.toUpperCase()` are wrong in Turkish (dotted/dotless `i`). System-level case ops are pinned to `en_US`. See `.claude/skills/i18n-rtl/SKILL.md`.
- Every new screen tested in all 4 locales. Chevrons and back arrows mirror in RTL.

### Design

- Use design tokens from `core/design`. **Never inline** colors, spacing, or font sizes.
- Every screen specifies loading, empty, error, and success states.
- `interface-design` skill saves choices to `.interface-design/system.md` — apply consistently across sessions.

### Auto-update / version gating

- Every Supabase Edge Function checks the `App-Version` header against `min_supported_version` in the `app_versions` table. Returns 426 if too old.
- The Flutter app HTTP interceptor catches 426 and shows the blocking force-update screen.
- See `.claude/skills/auto-update/SKILL.md`.

### Tests

- The `place_bid` RPC has integration tests for 50 concurrent bidders. **Never merge changes to it without those tests passing.**
- Money math has unit tests. Fee, escrow release, buyer premium, COD float deduction.
- Use the `flutter-tester` skill for widget/integration test patterns.

## Coding conventions

### Dart / Flutter

- File names: `snake_case.dart`. Class names: `PascalCase`. Vars/functions: `camelCase`.
- One public class per file.
- Feature-first organization (`features/bidding/...`), not layer-first.
- Riverpod providers: prefer code-gen for complex ones; `final fooProvider = Provider(...)` for trivial.
- Async: `async/await` over `.then()`.
- No `print()`. Use the logger in `core/observability`.
- No `setState` outside very local widget state. Lift to Riverpod.

### SQL / Postgres

- Migration filenames: `YYYYMMDDHHMMSS_short_description.sql` (UTC).
- Never edit a migration that has been applied to production. Add a new one.
- Every new table includes RLS policies in the same migration.
- All mutations through RPCs marked `security definer` with `auth.uid()` checks.
- Use `bigint` for money, `uuid` for IDs, `timestamptz` for times.
- Lowercase SQL keywords. Heavy comments on destructive operations.

### Edge Functions (Deno/TypeScript)

- Idempotent where possible (use request idempotency keys for payments).
- Always check the `App-Version` header — see `auto-update` skill.
- Structured logging only (`console.log(JSON.stringify({event, ...}))`).
- No secrets in code. Read from `Deno.env`.

## Working preferences for Claude Code

- **Edit, don't rewrite.** Use `str_replace` over full-file rewrites. Saves tokens, reduces diff noise.
- **Don't add comments unless asked.** Code should be self-explanatory; comments rot.
- **Don't generate stub tests "to be implemented".** They pollute context.
- **Reference docs instead of restating.** "See architecture.md §6.1" beats reciting the bid flow.
- **One concern per file.** Small files load cheaper and reason easier.
- **Extract on second use.** Same pattern appears twice → extract to a util in the same change.
- **Ask before adding dependencies.** Every new package is a security surface. Confirm and add to `decisions.md`.
- **No "while we're here" refactors.** Stay scoped. Note refactor ideas as TODOs in `decisions.md`.
- **When unsure, ask.** Especially about money flows, RLS, KYC, and Turkish text. Cost of guessing wrong is high.

## Branching & commits

- Branch names: `phase-N-feature-name` or `fix/short-description`.
- Conventional commits: `feat(bidding): add proxy bid trigger`, `fix(rls): tighten listings update policy`.
- Each phase is its own PR. Don't merge phases lacking acceptance criteria from `architecture.md`.

## How to start a task

1. Read this file.
2. Skim `docs/architecture.md` for the relevant phase/section.
3. Check `docs/decisions.md` for related ADRs.
4. Let the relevant skill auto-load. If you suspect a needed skill isn't loading, name it explicitly.
5. Implement.

If at any point the task seems to require breaking a non-negotiable above, **stop and surface the conflict**.

## Glossary

- **Smart Close** — auction lifecycle: 48h discovery window, then 12h-from-last-bid until close, 14d hard cap.
- **Verified Video** — seller-uploaded watermarked video that passes Gemini Vision verification; trust badge.
- **Group Bazaar** — under-10k IQD listings with tiered group-buy pricing.
- **Tribe Trust** — vouching layer from contact-network signals.
- **Seller Float** — credit balance a seller maintains for COD orders.
- **KYC Tiers**: 0 = browse, 1 = bid/buy up to 100k IQD, 2 = sell + high-value bid.
- **Hammer price** — winning bid amount before fees.
- **Buyer premium** — optional surcharge on top of hammer price (default 0% at launch).
