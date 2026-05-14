import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/features/listings/data/locale_text.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Card used in browse, search and home feed sections.
///
/// Layout follows the `interface-design` system: surface background,
/// outline border, 16:9 hero, 2-line title in user's locale (with UGC
/// fallback), tabular price.
class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    final title = localizedUgc(listing.titleTranslations, lang);
    final hero = listing.images.isNotEmpty
        ? ref.read(listingRepositoryProvider).publicUrlFor(listing.images.first)
        : null;

    final priceText = formatIQD(listing.displayPrice, locale);
    final priceLabel = switch (listing.type) {
      'fixed' => l10n.listingDetailBuyNow,
      _ when listing.currentHigh != null => l10n.listingDetailCurrentHigh,
      _ => l10n.listingDetailStartingAt,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: MazadTokens.surface,
            border: Border.all(color: MazadTokens.outline),
            borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(url: hero, badge: _verifiedBadge(l10n)),
              Padding(
                padding: const EdgeInsetsDirectional.all(MazadTokens.sp3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? '—' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: MazadTokens.sp2),
                    Text(
                      priceLabel,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: MazadTokens.onSurfaceMuted),
                    ),
                    const SizedBox(height: MazadTokens.sp1),
                    Text(
                      priceText,
                      style: tabularNumeric(theme.textTheme.titleMedium!)
                          .copyWith(color: MazadTokens.primary),
                    ),
                    const SizedBox(height: MazadTokens.sp2),
                    _TypePill(type: listing.type),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _verifiedBadge(AppLocalizations l10n) =>
      listing.videoVerified ? _VerifiedVideoPill(label: l10n.listingDetailVerifiedVideo) : null;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.url, this.badge});
  final String? url;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(MazadTokens.radiusMd),
              topEnd: Radius.circular(MazadTokens.radiusMd),
            ),
            child: url == null
                ? Container(
                    color: MazadTokens.background,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: MazadTokens.onSurfaceMuted,
                    ),
                  )
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    width: double.infinity,
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
          if (badge != null)
            PositionedDirectional(
              top: MazadTokens.sp2,
              end: MazadTokens.sp2,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

class _VerifiedVideoPill extends StatelessWidget {
  const _VerifiedVideoPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp3,
        vertical: MazadTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: MazadTokens.success.withValues(alpha: 0.16),
        border: Border.all(color: MazadTokens.success, width: 1),
        borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined,
              size: 14, color: MazadTokens.success),
          const SizedBox(width: MazadTokens.sp1),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: MazadTokens.success),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = switch (type) {
      'auction' => l10n.listingTypeAuction,
      'fixed' => l10n.listingTypeFixed,
      'bazaar' => l10n.listingTypeBazaar,
      _ => type,
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: MazadTokens.background,
        border: Border.all(color: MazadTokens.outline),
        borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: MazadTokens.onSurfaceMuted),
      ),
    );
  }
}
