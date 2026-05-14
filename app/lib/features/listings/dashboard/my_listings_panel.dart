import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/data/locale_text.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Body for the "Listings" tab on the My Mazad dashboard.  Tier 0 sees
/// a CTA to verify their phone; tier 1+ sees their own listings (drafts,
/// active, sold) and a primary "Sell" CTA.
class MyListingsPanel extends ConsumerWidget {
  const MyListingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final profile = ref.watch(myProfileProvider).value;
    final async = ref.watch(myListingsProvider);

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profile.kycTier < 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.createListingTier1Locked,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: MazadTokens.sp3),
              FilledButton(
                onPressed: () => context.push('/auth'),
                child: Text(l10n.homeSignIn),
              ),
            ],
          ),
        ),
      );
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(l10n.commonGenericError, style: theme.textTheme.bodyLarge),
      ),
      data: (listings) => Stack(
        children: [
          listings.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding:
                      const EdgeInsetsDirectional.all(MazadTokens.sp4),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: MazadTokens.sp3),
                  itemBuilder: (_, i) {
                    final l = listings[i];
                    final title = localizedUgc(l.titleTranslations, lang);
                    return InkWell(
                      onTap: () => context.push('/listings/${l.id}'),
                      borderRadius:
                          BorderRadius.circular(MazadTokens.radiusMd),
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(
                            MazadTokens.sp3),
                        decoration: BoxDecoration(
                          color: MazadTokens.surface,
                          border: Border.all(color: MazadTokens.outline),
                          borderRadius: BorderRadius.circular(
                              MazadTokens.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? '—' : title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: MazadTokens.sp1),
                                  Text(
                                    formatIQD(l.displayPrice, locale),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            color: MazadTokens.primary),
                                  ),
                                ],
                              ),
                            ),
                            _StatusChip(status: l.status),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          PositionedDirectional(
            bottom: MazadTokens.sp4,
            end: MazadTokens.sp4,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/sell'),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeFabSell),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'draft' => (l10n.listingDetailDraftBadge, MazadTokens.onSurfaceMuted),
      'cancelled' =>
        (l10n.listingDetailCancelledBadge, MazadTokens.error),
      _ => (status, MazadTokens.success),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(MazadTokens.radiusPill),
      ),
      child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MazadTokens.sp6),
        child: Text(
          l10n.dashboardEmptyListings,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: MazadTokens.onSurfaceMuted),
        ),
      ),
    );
  }
}
