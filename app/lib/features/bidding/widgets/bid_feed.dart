import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/bidding/data/bid.dart';
import 'package:mazad/features/bidding/data/bidding_providers.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Pseudonymized live activity feed.  Reads `listing_bid_feed` realtime.
/// Public projection — no display names, no phone numbers; only the
/// `bidder_<6hex>` handle and the bidder's city (see ADR-0009).
class BidFeed extends ConsumerWidget {
  const BidFeed({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(bidFeedProvider(listingId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.biddingFeedTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: MazadTokens.sp3),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: MazadTokens.sp4),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) =>
              Text(l10n.commonGenericError, style: theme.textTheme.bodySmall),
          data: (bids) {
            if (bids.isEmpty) {
              return Text(
                l10n.biddingFeedEmpty,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              );
            }
            return Column(
              children: [
                for (final b in bids) _BidRow(bid: b),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({required this.bid});
  final Bid bid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final pseudonym = bid.bidderPseudonym ?? 'bidder_?';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MazadTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pseudonym, style: theme.textTheme.labelMedium),
                    if (bid.isProxy) ...[
                      const SizedBox(width: MazadTokens.sp2),
                      Icon(Icons.bolt_outlined,
                          size: 12, color: MazadTokens.onSurfaceMuted),
                    ],
                  ],
                ),
                Text(
                  [
                    if (bid.bidderCity != null && bid.bidderCity!.isNotEmpty)
                      bid.bidderCity,
                    _relativeTime(context, bid.createdAt),
                  ].whereType<String>().join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: MazadTokens.onSurfaceMuted),
                ),
              ],
            ),
          ),
          Text(
            formatIQD(bid.amount, locale),
            style: tabularNumeric(theme.textTheme.titleMedium!).copyWith(
              color: MazadTokens.success,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(BuildContext context, DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1)
      return AppLocalizations.of(context).biddingFeedJustNow;
    if (diff.inHours < 1) {
      return AppLocalizations.of(context).biddingFeedMinutesAgo(diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return AppLocalizations.of(context).biddingFeedHoursAgo(diff.inHours);
    }
    return intl.DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
        .format(t);
  }
}
