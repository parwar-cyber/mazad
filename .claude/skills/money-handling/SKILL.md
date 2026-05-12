---
name: money-handling
description: Use whenever working with money values — IQD amounts, prices, bids, fees, escrow, payouts, buyer premiums, COD seller float, refunds — or currency formatting and display. Enforces bigint-only money handling, prevents float-precision bugs, and provides correct locale-aware formatting for English, Arabic, Sorani Kurdish, and Turkish. Applies to Flutter (Dart), Postgres (SQL), and Edge Functions (TypeScript/Deno).
---

# Money Handling

This codebase handles real money in Iraqi Dinar (IQD). A floating-point bug in production destroys trust permanently. These rules are non-negotiable.

## The single most important rule

**All money values are integers (`bigint` in Postgres, `int` in Dart, `bigint` in TypeScript).**

Never use `float`, `double`, `decimal`, JavaScript `Number`, or Dart `num` for money. Never. Not for display calculation, not for "small" amounts, not for percentages applied to money.

## Unit

- 1 IQD = 1 IQD. We do not store fils (sub-dinar units). The Iraqi Dinar is not transacted in fractions in practice.
- All amounts stored as IQD as integer.
- Example: 25,000 IQD is stored as `25000`, not `25000.00`, not `2500000` (cents).

## Database (Postgres)

```sql
-- Correct
amount bigint not null check (amount >= 0)
fee bigint not null default 0
float_balance bigint not null default 0  -- can be negative for COD overdraft

-- Wrong — never do these
amount numeric(10,2)   -- floating decimal
amount real            -- IEEE 754
amount money           -- locale-dependent, deprecated
```

Use `bigint` not `int` because IQD amounts get large (1 million IQD = `1000000`, well within int range, but bid totals across many lots can exceed it).

## Dart

```dart
// Correct
class Bid {
  final int amount;        // IQD
  final int? maxAmount;    // proxy bid ceiling
  Bid({required this.amount, this.maxAmount});
}

// Wrong
class Bid {
  final double amount;     // NO
  final num amount;        // NO
}
```

Dart's `int` is arbitrary precision on the VM and 64-bit on web — both are safe for IQD amounts.

## TypeScript (Edge Functions)

JavaScript's `Number` is IEEE 754 float and **loses precision above 2^53**. Use `bigint` for money:

```typescript
// Correct
const amount: bigint = 25000n;
const fee: bigint = (amount * 7n) / 100n;  // 7% fee, integer division

// Wrong
const amount: number = 25000;          // float — fine for small, dangerous at scale
const fee = amount * 0.07;             // float multiplication — precision loss
```

When reading from Supabase, bigint columns arrive as strings in JS. Always coerce:

```typescript
const { data } = await supabase.from('listings').select('current_high');
const high = BigInt(data.current_high);  // never Number()
```

## Calculations

### Percentages (fees, buyer premiums)

Always multiply before dividing, using integer math:

```dart
// 7% platform fee on hammer price
int calculateFee(int hammerPrice) {
  return (hammerPrice * 7) ~/ 100;   // integer division
}

// 5% buyer premium
int calculateBuyerPremium(int hammerPrice) {
  return (hammerPrice * 5) ~/ 100;
}
```

```sql
-- Same pattern in SQL
select (hammer_price * 7) / 100 as platform_fee
```

```typescript
// And in TypeScript
const fee = (hammerPrice * 7n) / 100n;  // bigint, integer division
```

### Minimum bid increment

```dart
int minimumIncrement(int currentHigh) {
  // 5% of current, with 1000 IQD floor
  final fivePercent = (currentHigh * 5) ~/ 100;
  return fivePercent < 1000 ? 1000 : fivePercent;
}
```

### Order total

```dart
int orderTotal({
  required int hammerPrice,
  required int buyerPremium,
  required int platformFee,
  required int deliveryFee,
}) {
  return hammerPrice + buyerPremium + platformFee + deliveryFee;
}
```

Each component is bigint, sum is bigint. No floats anywhere.

### Escrow release

```dart
int escrowReleaseToSeller({
  required int orderTotal,
  required int platformFee,
  required int buyerPremium,  // collected on top — goes to platform, not seller
  required int deliveryFee,
}) {
  return orderTotal - platformFee - buyerPremium - deliveryFee;
}
```

### COD seller float deduction

```dart
int updatedFloat({
  required int currentFloat,
  required int orderHammerPrice,
  required int platformFee,
  required int deliveryFee,
}) {
  // seller collects hammer from buyer; owes platform the fees
  return currentFloat - platformFee - deliveryFee;
}
```

## Server validation (every time)

The server **never trusts a client-sent amount**. The `place_bid` RPC re-derives `min_increment` and `current_high + min_increment` from the database row inside a locked transaction. The client display can be wrong; the database cannot.

```sql
create or replace function place_bid(p_listing_id uuid, p_amount bigint)
returns bids as $$
declare
  v_listing listings%rowtype;
  v_min_increment bigint;
begin
  select * into v_listing from listings where id = p_listing_id for update;
  -- server re-computes — never trusts client to send increment-valid amount
  v_min_increment := greatest(1000, (coalesce(v_listing.current_high, v_listing.starting_price) * 5) / 100);
  if p_amount < coalesce(v_listing.current_high, v_listing.starting_price) + v_min_increment then
    raise exception 'bid_too_low';
  end if;
  -- ... insert and update
end;
$$ language plpgsql security definer;
```

## Locale-aware formatting

**Never inline format strings.** Always use `formatIQD()` from `core/money/money_format.dart`.

```dart
// app/lib/core/money/money_format.dart
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';

String formatIQD(int amount, Locale locale) {
  final lang = locale.languageCode;

  // Locale-specific number formatter
  final formatter = NumberFormat.decimalPattern(_intlLocale(lang));
  final number = formatter.format(amount);

  switch (lang) {
    case 'en':
      return '$number IQD';
    case 'ar':
      return '$number د.ع';
    case 'ku':
      return '$number IQD';   // Sorani convention; align with KRI government standard
    case 'tr':
      return '$number IQD';   // Turkish: 25.000 IQD (period as thousands sep)
    default:
      return '$number IQD';
  }
}

String _intlLocale(String lang) {
  switch (lang) {
    case 'ar': return 'ar';
    case 'ku': return 'ar';   // Sorani uses Arabic-script number formatting conventions
    case 'tr': return 'tr';
    default:   return 'en_US';
  }
}
```

Expected output by locale for `25000`:

| Locale | Output |
|---|---|
| `en` | `25,000 IQD` |
| `ar` | `25,000 د.ع` (or `٢٥٬٠٠٠ د.ع` if user opted into Eastern Arabic numerals) |
| `ku` | `25,000 IQD` |
| `tr` | `25.000 IQD` ← note the period |

The Turkish thousands separator (`.`) is the single most likely formatting bug. Always test Turkish locale.

## What to test (unit tests, required)

Test file: `app/test/core/money_test.dart`

- `formatIQD(25000, en) == '25,000 IQD'`
- `formatIQD(25000, tr) == '25.000 IQD'` (period, not comma)
- `formatIQD(0, en) == '0 IQD'`
- `formatIQD(1000000, en) == '1,000,000 IQD'`
- `calculateFee(100000) == 7000` (7% of 100k)
- `calculateFee(33333) == 2333` (integer truncation, not rounding)
- `minimumIncrement(0) == 1000` (floor)
- `minimumIncrement(10000) == 1000` (5% would be 500, floor applies)
- `minimumIncrement(100000) == 5000` (5%)
- `orderTotal(hammer: 100000, premium: 0, fee: 7000, delivery: 5000) == 112000`

For the bid RPC concurrency test, see the `flutter-tester` skill and `architecture.md` §6.1.

## Common bug patterns to refuse

When generating or reviewing code, refuse these patterns:

```dart
// REFUSE: float anywhere in money path
double price = 25000.0;
final fee = price * 0.07;

// REFUSE: silent precision loss via num
num amount = json['amount'];

// REFUSE: locale-naive formatting
final display = '$amount IQD';   // missing thousands separator, missing locale

// REFUSE: client-computed amounts sent to server as authoritative
final minNextBid = currentHigh + (currentHigh * 0.05);   // float + float
await supabase.rpc('place_bid', params: {'amount': minNextBid});
```

```typescript
// REFUSE: Number used for money
const amount: number = parseFloat(input);
const fee = amount * 0.07;

// REFUSE: implicit float when reading bigint
const high = data.current_high;   // arrives as string; needs BigInt() coercion
```

## Display vs. arithmetic separation

- **Arithmetic**: always integer (bigint). Server-side authoritative.
- **Display**: `formatIQD(amount, locale)` — never inline strings.
- The two paths never mix. Display never feeds back into arithmetic.

## Quick checklist before merging a PR that touches money

- [ ] No `double` / `float` / `num` / `decimal` / `numeric` in the money path.
- [ ] No bare `Number()` coercion of money values in TypeScript.
- [ ] All formatting goes through `formatIQD()`.
- [ ] Turkish locale output verified (period as thousands separator).
- [ ] Server re-validates the amount; client values are display-only.
- [ ] Unit tests cover the money math.
- [ ] Integer division is intentional — truncation behavior is documented if it affects user-visible amounts.
