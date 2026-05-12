---
name: i18n-rtl
description: Use whenever working with user-visible strings, translations, locale-aware formatting (currency, dates, numbers), RTL/LTR layout, font selection, search across translations, or any case-insensitive comparison. Covers English, Arabic, Sorani Kurdish, and Turkish — including the Turkish dotted/dotless `i` bug class that breaks `.toLowerCase()` / `.toUpperCase()` in the standard library. Applies to Flutter (Dart), Postgres (SQL), and Edge Functions (TypeScript/Deno).
---

# Internationalization & RTL

This app ships in four languages from day one. Every screen, notification, invoice, and AI-generated listing renders in all four. The biggest risks are silent: hardcoded strings that escape translation, layout that breaks in RTL, and the Turkish case-conversion bug.

## Language matrix

| Language | Code | Script | Direction | Numerals | Notes |
|---|---|---|---|---|---|
| English | `en` | Latin | LTR | Western (1,2,3) | Reference locale |
| Arabic | `ar` | Arabic | RTL | Western default; Eastern Arabic (١,٢,٣) optional | Modern Standard with Iraqi-Levantine register for UGC |
| Kurdish (Sorani) | `ku` | Arabic | RTL | Western | Kurmanji is NOT supported |
| Turkish | `tr` | Latin | LTR | Western | Diacritics required: ç ğ ı İ ö ş ü |

## ⚠️ The Turkish dotted/dotless `i` rule (CRITICAL)

Turkish has **four `i` characters**, not two:

| Lowercase | Uppercase | Name |
|---|---|---|
| `i` | **`İ`** (U+0130) | dotted i |
| **`ı`** (U+0131) | `I` | dotless i |

In Turkish locale:
- `'I'.toLowerCase()` → `'ı'` (not `'i'`)
- `'i'.toUpperCase()` → `'İ'` (not `'I'`)

This means **standard `.toLowerCase()` and `.toUpperCase()` produce wrong results in Turkish locale**. Any case-insensitive comparison (search, username uniqueness, tag matching, slug generation, URL routing) breaks.

### The rule

- **System-level case operations** (slugs, usernames, DB keys, search normalization, route matching): always pin to `en_US`.
- **Display-level case operations** (visual styling like ALL CAPS labels): use the user's locale.

### Dart

```dart
// CORRECT — system operation pinned to en_US
String slugify(String input) {
  return input.toLowerCase()           // Dart's default is locale-insensitive (Unicode lowercase), safe
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

// CORRECT — display-level uses user locale
Text(label.toUpperCase(), style: titleStyle)   // OK for display; if locale-sensitive caps matter,
                                                // use intl's toBeginningOfSentenceCase

// WRONG — comparing user-entered tag with stored tag without locale pin
if (userInput.toLowerCase() == storedTag.toLowerCase()) { ... }
// Fix: normalize both to a non-Turkish locale, or use exact-byte comparison
```

> **Note**: Dart's `String.toLowerCase()` and `.toUpperCase()` are Unicode default (locale-insensitive) — but `intl` library has locale-aware variants. The rule is: **don't use locale-aware case ops for system fields**.

### TypeScript (Deno / Edge Functions)

JavaScript IS locale-aware by default for `.toLocaleLowerCase()`. Be explicit:

```typescript
// CORRECT — system normalization
const normalized = userInput.toLocaleLowerCase('en-US');

// WRONG — uses runtime locale
const normalized = userInput.toLowerCase();        // mostly OK but inconsistent
const normalized = userInput.toLocaleLowerCase();  // uses default — may be Turkish on Turkish user's device
```

### Postgres

```sql
-- WRONG: locale-dependent
where lower(tag) = lower(input)

-- CORRECT: collation-pinned
where lower(tag collate "en_US") = lower(input collate "en_US")

-- Or use citext for case-insensitive columns
create extension if not exists citext;
alter table tags alter column name type citext;
-- Then: where name = input  -- works correctly
```

### When this matters in our codebase

Audit these places for Turkish safety:
- Username uniqueness check
- Tag matching and category slugs
- Search query normalization
- Email lookup (`alice@example.com` vs `ALICE@example.com`)
- Hashtag matching in listings
- URL slug generation for listings
- Coupon code matching (if added later)
- Filename matching for uploads

## Translation files (ARB)

Static UI strings live in ARB files under `app/lib/l10n/`:

```
app/lib/l10n/
├── app_en.arb     ← canonical
├── app_ar.arb
├── app_ku.arb
└── app_tr.arb
```

Every string has a key, a placeholder description, and an entry in all four files. Example:

```json
// app_en.arb
{
  "@@locale": "en",
  "appTitle": "Mazad",
  "@appTitle": { "description": "App display name" },
  "placeBid": "Place bid",
  "@placeBid": { "description": "Button label on listing detail" }
}
```

```json
// app_tr.arb
{
  "@@locale": "tr",
  "appTitle": "Mazad",
  "placeBid": "Teklif ver"
}
```

### Hardcoded strings — never

```dart
// WRONG
Text('Place bid')

// CORRECT
Text(AppLocalizations.of(context).placeBid)
```

If you find a hardcoded string while editing a screen, fix it in the same change. Don't leave a TODO.

## UGC (user-generated content) translations

Database fields that hold user-generated text are JSONB with four keys:

```sql
title_translations jsonb not null,
description_translations jsonb not null
```

Shape:
```json
{
  "en": "Samsung Galaxy S22, 128GB",
  "ar": "سامسونج جالاكسي إس22، 128 جيجابايت",
  "ku": "سامسۆنگ گالاکسی S22، 128 گیگابایت",
  "tr": "Samsung Galaxy S22, 128GB"
}
```

At least one locale must be non-null (enforced by CHECK constraint). The AI Listing Co-pilot fills missing locales via Gemini.

### Reading UGC with fallback

```dart
String localizedTitle(Map<String, dynamic> titleTranslations, Locale userLocale) {
  final lang = userLocale.languageCode;
  // Try user's locale first
  if (titleTranslations[lang] != null && (titleTranslations[lang] as String).isNotEmpty) {
    return titleTranslations[lang];
  }
  // Fallback order: en → ar → ku → tr → any non-empty
  for (final fallback in ['en', 'ar', 'ku', 'tr']) {
    final value = titleTranslations[fallback];
    if (value != null && (value as String).isNotEmpty) return value;
  }
  return '';
}
```

## Numerals

- All four locales default to Western Arabic numerals (1, 2, 3) for prices, counts, and dates.
- Users with Arabic locale can opt into Eastern Arabic numerals (١, ٢, ٣) in their profile settings.
- The opt-in only affects Arabic locale display. Never opt-in for `en`, `ku`, or `tr`.

## Currency formatting

See `money-handling` skill. Quick reference for `25000` IQD:

| Locale | Output |
|---|---|
| `en` | `25,000 IQD` |
| `ar` | `25,000 د.ع` |
| `ku` | `25,000 IQD` |
| `tr` | `25.000 IQD` ← period as thousands separator |

## Date formatting

Never hardcode date format strings. Always use `intl.DateFormat`:

```dart
// CORRECT
final formatted = DateFormat.yMMMMd(locale.toString()).format(date);
// en: "May 12, 2026"
// ar: "12 مايو 2026"
// ku: similar Arabic-script format
// tr: "12 Mayıs 2026"

// WRONG
final formatted = '${date.day}/${date.month}/${date.year}';
```

## RTL layout

Arabic and Kurdish are RTL. The layout engine handles this automatically when the app's `MaterialApp.locale` is set correctly. But you must:

- Use `Directionality.of(context)` to check direction, never hardcode `TextDirection.ltr`.
- **Mirror these icons in RTL**: back arrows, forward chevrons, next/prev arrows, slider thumbs.
- **Don't mirror these**: phone receiver icons, search magnifying glass, media play buttons, logos, currency icons.
- Use `EdgeInsetsDirectional.only(start: ..., end: ...)` instead of `left/right`.
- Use `AlignmentDirectional.centerStart` instead of `centerLeft`.

```dart
// CORRECT
padding: EdgeInsetsDirectional.only(start: 16),

// WRONG
padding: EdgeInsets.only(left: 16),   // flips wrong way in RTL
```

### Animation direction

Slide animations need direction awareness:

```dart
final isRtl = Directionality.of(context) == TextDirection.rtl;
final slideBegin = isRtl ? const Offset(-1, 0) : const Offset(1, 0);
```

## Fonts

```dart
// app/lib/core/design/typography.dart
TextStyle baseStyleForLocale(String lang) {
  switch (lang) {
    case 'ar':
    case 'ku':
      return GoogleFonts.vazirmatn();   // or Noto Sans Arabic — must have Sorani glyphs
    case 'tr':
    case 'en':
    default:
      return GoogleFonts.inter();
  }
}
```

**Verify before shipping**:
- Sorani-specific glyphs render correctly: `ێ ۆ ڕ ڵ ﺋ ە`
- Turkish diacritics render correctly: `ç ğ ı İ ö ş ü Ç Ğ Ö Ş Ü`
- No tofu boxes (□) anywhere in any locale
- Test on physical iOS and Android devices, not just emulators

## Search across translations (Postgres)

```sql
create extension if not exists unaccent;

-- Generated tsvector across all 4 locales
alter table listings add column search_vector tsvector
  generated always as (
    setweight(to_tsvector('simple',
      unaccent(
        coalesce(title_translations->>'en','') || ' ' ||
        coalesce(title_translations->>'ar','') || ' ' ||
        coalesce(title_translations->>'ku','') || ' ' ||
        coalesce(title_translations->>'tr','')
      )), 'A') ||
    setweight(to_tsvector('simple',
      unaccent(
        coalesce(description_translations->>'en','') || ' ' ||
        coalesce(description_translations->>'ar','') || ' ' ||
        coalesce(description_translations->>'ku','') || ' ' ||
        coalesce(description_translations->>'tr','')
      )), 'B')
  ) stored;

create index listings_search_idx on listings using gin(search_vector);
```

The search RPC applies `unaccent()` to the user query so Turkish `şarj` matches `sarj`, Arabic with diacritics matches without, etc.

## AI Listing Co-pilot prompt structure

When generating listings via Gemini, the prompt must specify all four target languages and their conventions:

```
Return JSON with title and description in all four languages:
- "en": clean concise English
- "ar": Modern Standard Arabic with natural Iraqi register
- "ku": Sorani (Central Kurdish) in Arabic script, with proper Sorani glyphs (ێ ۆ ڕ ڵ)
- "tr": standard Istanbul Turkish with proper diacritics (ç ğ ı İ ö ş ü)

Each field must be non-empty in all four locales.
```

Validate server-side that all four locales are present and non-empty before saving.

## Layout overflow (especially Turkish)

Turkish runs ~20% longer than English on average due to agglutinative grammar. Button labels and card titles that fit comfortably in English often overflow in Turkish.

- Test every new screen in `tr` at the smallest supported screen size.
- Allow buttons to grow vertically (two-line labels) rather than truncating mid-word.
- For card titles, use `maxLines: 2, overflow: TextOverflow.ellipsis`.

## RTL + 4-language audit checklist (before merging any UI PR)

- [ ] Every visible string sourced from ARB (no hardcoded strings).
- [ ] Screen tested in all 4 locales: `en`, `ar`, `ku`, `tr`.
- [ ] RTL screens have correctly mirrored chevrons, back arrows, slide direction.
- [ ] Turkish-locale text does not overflow buttons or card titles.
- [ ] Turkish diacritics (ç ğ ı İ ö ş ü) render correctly on physical iOS and Android.
- [ ] Sorani-specific glyphs (ێ ۆ ڕ ڵ) render correctly.
- [ ] Numbers use locale-aware formatting (correct thousands separator per locale).
- [ ] Dates use `intl.DateFormat` — no hardcoded patterns.
- [ ] No `.toLowerCase()` / `.toUpperCase()` on system fields without locale pin.
- [ ] Padding uses `EdgeInsetsDirectional`, not `EdgeInsets.only(left/right)`.
- [ ] Alignment uses `AlignmentDirectional`, not `Alignment.centerLeft/Right`.

## What to refuse

When generating code, refuse these patterns:

```dart
// Hardcoded user-facing string
Text('Submit')                                 // REFUSE — use ARB

// Locale-naive case op on system field
final slug = title.toLowerCase().replaceAll(' ', '-');  // REFUSE — Turkish breaks this
                                                          // Use slugify() utility

// Hardcoded left/right
padding: EdgeInsets.only(left: 16, right: 16)  // REFUSE — use symmetric or directional

// Hardcoded date format
Text('${date.year}-${date.month}-${date.day}') // REFUSE — use intl.DateFormat
```

```sql
-- Locale-dependent case comparison
where lower(name) = lower('john')              -- REFUSE — pin collation or use citext
```

## Common bugs this skill prevents

1. Turkish user creates account "İstanbul" — uniqueness check fails because `.toLowerCase()` mangles it differently than the stored slug.
2. Search for "şarj cihazı" returns no results because `unaccent` wasn't applied.
3. Turkish price displays as "25,000 IQD" instead of "25.000 IQD" because formatter used English locale.
4. Arabic listing screen shows back arrow pointing the wrong way because icon wasn't mirrored.
5. Kurdish text renders as tofu boxes because font lacks Sorani glyphs.
6. Card title in Turkish overflows because the layout assumed English-length strings.
