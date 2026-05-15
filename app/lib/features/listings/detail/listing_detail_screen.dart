import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/bidding/data/bidding_providers.dart';
import 'package:mazad/features/bidding/widgets/bid_console.dart';
import 'package:mazad/features/bidding/widgets/bid_countdown.dart';
import 'package:mazad/features/bidding/widgets/bid_feed.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/features/listings/data/locale_text.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Listing detail with realtime bid console + feed + countdown.  The
/// realtime listing stream (`listingRealtimeProvider`) drives every
/// numeric on this screen so a competing bid lands without a refresh.
/// See architecture.md §6.1 / §6.2.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The async one-shot fetch seeds the screen.  The realtime stream then
    // pushes updates on every UPDATE event.  We prefer the realtime row
    // whenever available.
    final initial = ref.watch(listingByIdProvider(id));
    final live = ref.watch(listingRealtimeProvider(id));
    final listing = live.value ?? initial.value;

    if (initial.isLoading && listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(l10n.listingDetailUnavailable,
              style: theme.textTheme.bodyLarge),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: _Body(listing: listing),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final repo = ref.read(listingRepositoryProvider);

    final title = localizedUgc(listing.titleTranslations, lang);
    final description = localizedUgc(listing.descriptionTranslations, lang);
    final urls = listing.images.map(repo.publicUrlFor).toList(growable: false);
    final canBid = listing.status == 'active' && listing.type != 'fixed';

    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: MazadTokens.sp7),
      children: [
        _Gallery(urls: urls, verified: listing.videoVerified),
        Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.status != 'active')
                _StatusBadge(status: listing.status),
              const SizedBox(height: MazadTokens.sp2),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: MazadTokens.sp3),
              _PriceAndTimerRow(listing: listing),
              const SizedBox(height: MazadTokens.sp4),
              Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined,
                      size: 14, color: MazadTokens.onSurfaceMuted),
                  const SizedBox(width: MazadTokens.sp1),
                  Text(
                    l10n.listingDetailViews(listing.viewCount),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: MazadTokens.onSurfaceMuted),
                  ),
                  const SizedBox(width: MazadTokens.sp4),
                  Icon(Icons.gavel_outlined,
                      size: 14, color: MazadTokens.onSurfaceMuted),
                  const SizedBox(width: MazadTokens.sp1),
                  Text(
                    l10n.biddingBidCount(listing.bidCount),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: MazadTokens.onSurfaceMuted),
                  ),
                ],
              ),
              const SizedBox(height: MazadTokens.sp5),
              if (description.isNotEmpty)
                Text(description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: MazadTokens.sp5),
              if (canBid) BidConsole(listing: listing),
              if (listing.type == 'fixed')
                FilledButton(
                  // Buy-now flow lands in Phase 7.
                  onPressed: null,
                  child: Text(l10n.listingDetailBuyNow),
                ),
              const SizedBox(height: MazadTokens.sp6),
              if (canBid) BidFeed(listingId: listing.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceAndTimerRow extends StatelessWidget {
  const _PriceAndTimerRow({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final showTimer = listing.type != 'fixed' && listing.currentCloseAt != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.type == 'fixed'
                    ? l10n.listingDetailBuyNow
                    : (listing.currentHigh != null
                        ? l10n.listingDetailCurrentHigh
                        : l10n.listingDetailStartingAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
              const SizedBox(height: MazadTokens.sp1),
              Text(
                formatIQD(listing.displayPrice, locale),
                style: tabularNumeric(theme.textTheme.headlineMedium!)
                    .copyWith(color: MazadTokens.primary),
              ),
            ],
          ),
        ),
        if (showTimer)
          BidCountdown(
            currentCloseAt: listing.currentCloseAt!,
            discoveryEndsAt: listing.discoveryEndsAt,
            hardCloseAt: listing.hardCloseAt,
          ),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls, required this.verified});
  final List<String> urls;
  final bool verified;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        height: 240,
        color: MazadTokens.surface,
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 48, color: MazadTokens.onSurfaceMuted),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.urls.length,
            itemBuilder: (_, i) => Image.network(
              widget.urls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: MazadTokens.background,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: MazadTokens.onSurfaceMuted,
                ),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            PositionedDirectional(
              bottom: MazadTokens.sp3,
              start: 0,
              end: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: MazadTokens.sp3,
                    vertical: MazadTokens.sp1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: MazadTokens.onSurface,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = switch (status) {
      'draft' => l10n.listingDetailDraftBadge,
      'cancelled' => l10n.listingDetailCancelledBadge,
      'sold' => l10n.listingDetailSoldBadge,
      'expired' => l10n.listingDetailExpiredBadge,
      _ => status,
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp3,
        vertical: MazadTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: MazadTokens.surface,
        border: Border.all(color: MazadTokens.outline),
        borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}
