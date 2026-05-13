# Mazad — Interface Design System

> Persisted source of truth for cross-session design consistency.
> Authoritative tokens live in `app/lib/core/design/`. This file is the
> rationale + reference. **Never inline** colors, spacing, or font sizes —
> always reference tokens from `MazadTokens`.
> Cross-reference: ADR-0005 in `docs/decisions.md`.

---

## Identity

**Name**: Mazad
**Tagline**: *Iraq's most trusted auction marketplace. No snipes. Verified video on every listing. Escrow on every order.*
**Tone**: Trustworthy, calm, premium-but-accessible. Not flashy. Not "souk-stereotype." Not generic-fintech.
**Voice in copy**: Direct, second-person, no hype words ("amazing", "incredible"). Money is mentioned plainly. Time-pressure (closing soon) is stated, not exclaimed.

---

## Palette — "Tigris"

The name nods to the river without leaning on Iraqi-flag tricolor (too touristic) or generic gold-souk (too on-the-nose). Dark-first because:

1. Long bid sessions — dark surface is kinder at night.
2. Photos dominate the listing detail screen — dark surrounds make product images pop.
3. Gold-on-near-black reads "auction house" without being aggressive.

### Dark (default — `ThemeMode.dark`)

| Token | Hex | Use |
|---|---|---|
| `primary` | `#D4A04C` | Gold — CTAs, current high bid, "your turn to bid" |
| `onPrimary` | `#0E1116` | Text on gold surfaces |
| `background` | `#0E1116` | Page background — near-black with a faint blue undertone |
| `surface` | `#171B22` | Cards, sheets, listing tiles |
| `onSurface` | `#EDE6D6` | Body text on surface |
| `onSurfaceMuted` | `#9B9382` | Secondary text, captions, "ends in" labels |
| `outline` | `#2A2F38` | Borders, dividers |
| `success` | `#5BA98F` | Muted teal — "bid accepted", "you're winning" |
| `error` | `#E04E3D` | Warm crimson — "outbid", "bid too low" |
| `info` | `#7DA9D8` | Cool slate blue — neutral notifications |

### Light

| Token | Hex |
|---|---|
| `primary` | `#A87A2C` (darker gold for AA contrast on cream) |
| `onPrimary` | `#FFFBF2` |
| `background` | `#FBF8F2` (warm paper) |
| `surface` | `#FFFFFF` |
| `onSurface` | `#1A1614` |
| `outline` | `#D9D4C7` |

Semantic colors (success / error / info) are identical across themes — emotional signals shouldn't shift with theme.

### Color rules

- **Never** mix gold and crimson in adjacent live-bid signals (color-blind clash). Outbid uses crimson + an icon; "you're winning" uses gold (CTA-style fill) + a check.
- "Bid up" semantics use muted teal (`success`), not green. Green-vs-red is the global Western convention for finance and the brief is to feel calm, not pump-and-dump.
- Gold is a CTA color, not decoration. If it appears outside a button, the user should be able to tap it.

---

## Typography

| Locale | Font | Why |
|---|---|---|
| `en`, `tr` | **Inter** | Strong RTL-neutral neutral grotesque; battle-tested for prices and dense UI |
| `ar`, `ku` | **Vazirmatn** | One of the few free Arabic-script families with **full Sorani glyph coverage** (ێ ۆ ڕ ڵ) |

### Scale (defined in `core/design/typography.dart`)

| Style | Size | Weight | Letter-spacing | Use |
|---|---|---|---|---|
| `displayLarge` | 48 | 700 | -0.02em | Marketing only |
| `displayMedium` | 36 | 700 | -0.02em | Welcome / force-update hero |
| `headlineLarge` | 28 | 700 | -0.02em | Screen titles |
| `headlineMedium` | 24 | 600 | -0.02em | Section heads |
| `headlineSmall` | 20 | 600 | -0.02em | Card titles |
| `titleLarge` | 18 | 600 | 0 | List section headers |
| `titleMedium` | 16 | 600 | — | Strong body |
| `bodyLarge` | 16 | 400 | — | Body copy |
| `bodyMedium` | 14 | 400 | — | Default body |
| `bodySmall` | 12 | 400 | — | Captions, timestamps |
| `labelLarge` | 14 | 600 | — | Button labels |

### Rules

- **Tabular figures everywhere a number can change**: prices, bid amounts, countdowns, watch counts, bid counts. Wrap with `tabularNumeric(textStyle)`. Without this, prices jitter horizontally as digits update — a small thing that destroys polish in a live-bid feed.
- Display sizes have **negative letter-spacing (-0.02em)**. Inter and Vazirmatn both look cramped at default tracking at 24px+.
- Line-height is **1.5 for body**, **1.15 for headlines**. Tight headlines, breathable body.
- Turkish runs ~20% longer than English. Allow two-line button labels rather than truncating; on cards, `maxLines: 2, overflow: TextOverflow.ellipsis`.

---

## Spacing scale

8-point baseline with a 4-point half-step. Defined as `MazadTokens.sp1..sp8`.

| Token | px |
|---|---|
| `sp1` | 4 |
| `sp2` | 8 |
| `sp3` | 12 |
| `sp4` | 16 (default gutter) |
| `sp5` | 24 (screen padding) |
| `sp6` | 32 (section break) |
| `sp7` | 48 |
| `sp8` | 64 |

**Always** `EdgeInsetsDirectional` and `AlignmentDirectional` — never `EdgeInsets.only(left/right)` or `Alignment.centerLeft`. RTL correctness depends on this.

---

## Radius

| Token | px | Use |
|---|---|---|
| `radiusSm` | 6 | Inputs, chips |
| `radiusMd` | 12 | Buttons, cards |
| `radiusLg` | 20 | Sheets, modals |
| `radiusPill` | 999 | Status badges, "Verified Video" pill |

---

## Motion

| Token | Duration | Use |
|---|---|---|
| `motionFast` | 120ms | Tap feedback, icon swaps |
| `motionMed` | 240ms | Page transitions, sheet sliding |
| `motionSlow` | 400ms | Hero transitions on listing detail |

Slide-direction is locale-aware: `Offset(isRtl ? -1 : 1, 0)`.

---

## Components — Phase 0 baseline

### Buttons

- Default: `FilledButton`, 52pt minimum height, `radiusMd`, `labelLarge` text.
- Outlined for secondary / "dev-only" actions.
- Never use a `TextButton` for a primary CTA — too easy to miss in a dense listing card.

### Cards (defined in Phase 2)

- `surface` background, `outline` 1px border, `radiusMd`.
- Always show: hero image (16:9), title (`bodyLarge`, max 2 lines), price (`titleMedium`, **tabular**), close-time hint (`bodySmall`, `onSurfaceMuted`).
- Verified Video pill goes top-end (RTL-aware) overlaid on the hero.

### Force-update screen (Phase 0 reference)

The single shipped screen at Phase 0. Treat as the canon for tone:

- Glyph badge: 88px circle, `primary` 12% alpha fill, 2px `primary` border, `system_update_alt_rounded` icon at 40px.
- Headline: `headlineLarge`, centered, single line.
- Body: `bodyLarge`, `onSurfaceMuted`, centered, max 3 lines.
- Release notes (if present): card on `surface`, `radiusMd`, `outline` border, `bodyMedium`.
- CTA: `FilledButton`, full-width, `labelLarge` with tabular figures (some locales include version numbers in CTAs).
- `PopScope(canPop: false)` — never dismissible.

---

## i18n & RTL invariants

(Cross-reference: `.claude/skills/i18n-rtl/SKILL.md`)

- Every visible string sourced from ARB (`app/lib/l10n/app_{en,ar,ku,tr}.arb`).
- UGC stored as JSONB `{en, ar, ku, tr}`. Fallback chain on read: user locale → `en` → `ar` → `ku` → `tr` → any non-empty.
- `ar` + `ku` flip RTL automatically when `MaterialApp.locale` is set; do not manually invert.
- **Mirror in RTL**: back arrows, forward chevrons, slider thumbs, slide-in animations.
- **Don't mirror**: phone receiver, search magnifying glass, media play button, logos, currency symbols.
- Case operations on system fields (slugs, usernames, search keys) pinned to `en_US` to avoid the Turkish dotted/dotless `i` bug.

---

## Money display invariants

(Cross-reference: `.claude/skills/money-handling/SKILL.md`)

- IQD is `int` (Dart) / `bigint` (SQL). No floats.
- Format **only** via `formatIQD(amount, locale)` from `core/money/money_format.dart`.
- Expected per-locale (`25000`):
  - `en` → `25,000 IQD`
  - `ar` → `25,000 د.ع`
  - `ku` → `25,000 IQD`
  - `tr` → `25.000 IQD` ← period thousands separator (TR-specific bug class)
- Display values never feed back into arithmetic.

---

## What to refuse (review checklist)

When reviewing a Mazad UI PR, refuse:

- Inlined hex colors instead of `MazadTokens.*`.
- Hardcoded font sizes outside the theme's `TextTheme`.
- `EdgeInsets.only(left:, right:)` — must be `EdgeInsetsDirectional`.
- Currency formatted via string interpolation instead of `formatIQD()`.
- Bid amounts or prices rendered without `tabularNumeric()`.
- Hardcoded user-visible strings instead of ARB keys.
- Pure red / pure green for bid-up / outbid (use `success` / `error` tokens).
- A second copy of the gold or near-black hex anywhere — extract to a token.

---

## Open design TODOs (not blocking Phase 0)

- Bundle Inter + Vazirmatn as repo assets (currently `google_fonts` runtime fetch). Cuts cold-start, removes external boot dependency. Phase 9 polish.
- System / light / dark theme toggle. Currently dark-only. Wire to `profiles.theme_mode` in Phase 1.
- Eastern Arabic numerals (`١٢٣`) opt-in for `ar`. Schema bit is there (`feature_flags.eastern_arabic_numerals` + per-user preference). Phase 9 polish.
- High-contrast variant for accessibility audit (WCAG AAA). Phase 9.

---

## Phase history

| Phase | Date | Change |
|---|---|---|
| 0 | 2026-05-12 | Initial "Tigris" palette, Inter+Vazirmatn pairing, 8pt spacing scale, tabular figures rule, ForceUpdateScreen canon. |
