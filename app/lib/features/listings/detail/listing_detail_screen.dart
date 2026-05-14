import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/features/listings/data/locale_text.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Read-only listing detail.  Bidding controls land in Phase 3 — this
/// screen renders the listing and surfaces a disabled "bidding opens later"
/// hint so reviewers can see the full flow at Phase 2 acceptance.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(listingByIdProvider(id));

    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.commonGenericError)),
        data: (listing) {
          if (listing == null) {
            return Center(
              child: Text(l10n.listingDetailUnavailable,
                  style: theme.textTheme.bodyLarge),
            );
          }
          return _Body(listing: listing);
        },
      ),
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

    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: MazadTokens.sp6),
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
              _PriceBlock(listing: listing),
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
                ],
              ),
              const SizedBox(height: MazadTokens.sp5),
              if (description.isNotEmpty)
                Text(description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: MazadTokens.sp5),
              // Bidding actions are scoped to Phase 3.  The button is
              // intentionally disabled here so Phase 2 acceptance can show
              // a complete detail screen end-to-end.
              FilledButton(
                onPressed: null,
                child: Text(
                  switch (listing.type) {
                    'fixed' => l10n.listingDetailBuyNow,
                    _ => l10n.listingDetailBidUnavailable,
                  },
                ),
              ),
              const SizedBox(height: MazadTokens.sp2),
              Text(
                l10n.listingDetailBidUnavailable,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final priceLabel = switch (listing.type) {
      'fixed' => l10n.listingDetailBuyNow,
      _ when listing.currentHigh != null => l10n.listingDetailCurrentHigh,
      _ => l10n.listingDetailStartingAt,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(priceLabel,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: MazadTokens.onSurfaceMuted)),
        const SizedBox(height: MazadTokens.sp1),
        Text(
          formatIQD(listing.displayPrice, locale),
          style: tabularNumeric(theme.textTheme.headlineMedium!)
              .copyWith(color: MazadTokens.primary),
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
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusPill),
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
