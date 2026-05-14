import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/widgets/horizontal_listing_row.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Reusable home-feed body.  Shows three horizontal sections + the
/// categories row.  Used by HomeScreen on the public landing path.
class HomeFeed extends ConsumerWidget {
  const HomeFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final endingSoon = ref.watch(endingSoonProvider);
    final hot = ref.watch(hotListingsProvider);
    final bazaar = ref.watch(bazaarListingsProvider);
    final cats = ref.watch(categoriesProvider);

    Future<void> refresh() async {
      ref.invalidate(endingSoonProvider);
      ref.invalidate(hotListingsProvider);
      ref.invalidate(bazaarListingsProvider);
      ref.invalidate(categoriesProvider);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: MazadTokens.sp3),
          _Section(
            title: l10n.homeSectionEndingSoon,
            async: endingSoon,
            seeAllPath: '/browse?type=auction',
          ),
          _Section(
            title: l10n.homeSectionHot,
            async: hot,
            seeAllPath: '/browse',
          ),
          _Section(
            title: l10n.homeSectionBazaar,
            async: bazaar,
            seeAllPath: '/browse?type=bazaar',
          ),
          _CategoriesRow(async: cats),
          const SizedBox(height: MazadTokens.sp6),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.async,
    required this.seeAllPath,
  });
  final String title;
  final AsyncValue<List<Listing>> async;
  final String seeAllPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return async.when(
      loading: () => const _LoadingRow(),
      error: (_, __) => const _LoadingRow(),
      data: (listings) => HorizontalListingRow(
        title: title,
        listings: listings,
        seeAllRoute: seeAllPath,
        seeAllLabel: l10n.homeSeeAll,
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.async});
  final AsyncValue<List<ListingCategory>> async;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: MazadTokens.sp5,
            vertical: MazadTokens.sp3,
          ),
          child: Text(l10n.homeSectionCategories,
              style: theme.textTheme.headlineSmall),
        ),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (cats) => Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MazadTokens.sp5),
            child: Wrap(
              spacing: MazadTokens.sp2,
              runSpacing: MazadTokens.sp2,
              children: cats
                  .map(
                    (c) => ActionChip(
                      label: Text(c.localizedName(lang)),
                      onPressed: () =>
                          context.push('/browse?category=${c.id}'),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}
