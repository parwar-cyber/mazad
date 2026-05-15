import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/bidding/data/bidding_repository.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// The hero interaction.  One-tap bid quick-actions (+min, +2x min, +5x min)
/// and a "set max bid" surface for proxy bidding.  Tabular figures
/// throughout so price chips don't jitter as the auction state updates.
///
/// Server is authoritative for amounts.  Numbers here are display-only and
/// re-validated by `place_bid()`.
class BidConsole extends ConsumerStatefulWidget {
  const BidConsole({super.key, required this.listing});
  final Listing listing;

  @override
  ConsumerState<BidConsole> createState() => _BidConsoleState();
}

class _BidConsoleState extends ConsumerState<BidConsole> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final listing = widget.listing;
    final me = ref.watch(myProfileProvider).value;
    final isSeller = me?.id == listing.sellerId;
    final tier = me?.kycTier ?? 0;

    final current = listing.currentHigh ?? listing.startingPrice;
    final minInc = minimumBidIncrement(current);
    final nextMin = current + minInc;

    final quickAmounts = <int>[
      nextMin,
      current + minInc * 2,
      current + minInc * 5,
    ];

    return Container(
      padding: const EdgeInsetsDirectional.all(MazadTokens.sp4),
      decoration: BoxDecoration(
        color: MazadTokens.surface,
        border: Border.all(color: MazadTokens.outline),
        borderRadius: BorderRadius.circular(MazadTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Min next bid headline
          Text(
            l10n.biddingConsoleMinNext,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: MazadTokens.onSurfaceMuted),
          ),
          const SizedBox(height: MazadTokens.sp1),
          Text(
            formatIQD(nextMin, locale),
            style: tabularNumeric(theme.textTheme.headlineMedium!)
                .copyWith(color: MazadTokens.primary),
          ),
          const SizedBox(height: MazadTokens.sp4),

          // Quick-bid row.  Three tappable chips.
          if (!isSeller && tier >= 1) ...[
            Wrap(
              spacing: MazadTokens.sp2,
              runSpacing: MazadTokens.sp2,
              children: [
                for (final amt in quickAmounts)
                  _QuickBidChip(
                    amount: amt,
                    disabled: _submitting,
                    onTap: () => _submit(amount: amt),
                  ),
              ],
            ),
            const SizedBox(height: MazadTokens.sp3),
            TextButton.icon(
              onPressed: _submitting ? null : () => _openMaxBidSheet(context),
              icon: const Icon(Icons.bolt_outlined, size: 18),
              label: Text(l10n.biddingConsoleSetMax),
            ),
          ] else if (isSeller)
            Text(
              l10n.biddingConsoleSellerCantBid,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: MazadTokens.onSurfaceMuted),
            )
          else
            // Tier 0 — bidding gated.
            Text(
              l10n.biddingConsoleTier1Required,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: MazadTokens.onSurfaceMuted),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaxBidSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final listing = widget.listing;
    final current = listing.currentHigh ?? listing.startingPrice;
    final minInc = minimumBidIncrement(current);
    final controller =
        TextEditingController(text: (current + minInc).toString());

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MazadTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MazadTokens.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: MazadTokens.sp4,
          right: MazadTokens.sp4,
          top: MazadTokens.sp4,
          bottom: MediaQuery.of(context).viewInsets.bottom + MazadTokens.sp4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.biddingMaxSheetTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: MazadTokens.sp1),
            Text(l10n.biddingMaxSheetSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: MazadTokens.onSurfaceMuted)),
            const SizedBox(height: MazadTokens.sp4),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: tabularNumeric(Theme.of(context).textTheme.titleLarge!),
              decoration: InputDecoration(
                labelText: l10n.biddingMaxSheetLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: MazadTokens.sp4),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                if (v == null || v <= 0) return;
                Navigator.of(context).pop(v);
              },
              child: Text(l10n.biddingMaxSheetConfirm),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    await _submit(amount: current + minInc, maxAmount: result);
  }

  Future<void> _submit({required int amount, int? maxAmount}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(biddingRepositoryProvider);
    try {
      await repo.placeBid(
        listingId: widget.listing.id,
        amount: amount,
        maxAmount: maxAmount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MazadTokens.success,
          content: Text(l10n.biddingPlaced),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MazadTokens.error,
          content: Text(_messageFor(parseBidError(e), l10n)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(String code, AppLocalizations l10n) {
    switch (code) {
      case 'self_bid_forbidden':
        return l10n.biddingErrorSelfBid;
      case 'bid_too_low':
        return l10n.biddingErrorTooLow;
      case 'rate_limited':
        return l10n.biddingErrorRateLimited;
      case 'listing_closed':
        return l10n.biddingErrorClosed;
      case 'kyc_tier_1_required':
        return l10n.biddingErrorTier1;
      case 'bid_exceeds_tier_ceiling':
      case 'max_amount_exceeds_tier_ceiling':
        return l10n.biddingErrorTierCeiling;
      case 'seller_not_reviewed':
        return l10n.biddingErrorSellerUnreviewed;
      case 'listing_not_active':
      case 'listing_not_biddable':
        return l10n.biddingErrorNotActive;
      default:
        return l10n.biddingErrorGeneric;
    }
  }
}

class _QuickBidChip extends StatelessWidget {
  const _QuickBidChip({
    required this.amount,
    required this.onTap,
    required this.disabled,
  });
  final int amount;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: MazadTokens.sp4,
          vertical: MazadTokens.sp3,
        ),
        decoration: BoxDecoration(
          color: disabled
              ? MazadTokens.surface
              : MazadTokens.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: disabled ? MazadTokens.outline : MazadTokens.primary,
          ),
          borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
        ),
        child: Text(
          formatIQD(amount, locale),
          style: tabularNumeric(theme.textTheme.labelLarge!).copyWith(
            color: disabled ? MazadTokens.onSurfaceMuted : MazadTokens.primary,
          ),
        ),
      ),
    );
  }
}
