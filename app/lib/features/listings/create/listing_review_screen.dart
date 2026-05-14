import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing_draft.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/features/listings/widgets/iqd_price_field.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Step 4 — multi-locale editor + category, condition, prices.  Server
/// re-validates everything at publish time.
class ListingReviewScreen extends ConsumerStatefulWidget {
  const ListingReviewScreen({super.key});

  @override
  ConsumerState<ListingReviewScreen> createState() =>
      _ListingReviewScreenState();
}

class _ListingReviewScreenState extends ConsumerState<ListingReviewScreen> {
  bool _publishing = false;
  String? _error;
  String _activeLocale = 'en';

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(listingDraftProvider);
    final listing = draft.serverListing;
    if (listing == null) {
      setState(() => _error = l10n.commonGenericError);
      return;
    }
    // Pre-flight client checks mirror the server.  Server is authoritative.
    if (!draft.allLocalesFilled) {
      // Distinguish title vs description.
      if (draft.titleMap.length != 4) {
        setState(() => _error = l10n.createListingMissingTitle);
      } else {
        setState(() => _error = l10n.createListingMissingDescription);
      }
      return;
    }
    if (draft.categoryId == null) {
      setState(() => _error = l10n.createListingMissingCategory);
      return;
    }
    if (draft.condition == null) {
      setState(() => _error = l10n.createListingMissingCondition);
      return;
    }
    if (draft.type == 'fixed') {
      if ((draft.buyNowPriceIqd ?? 0) <= 0) {
        setState(() => _error = l10n.createListingMissingBuyNowPrice);
        return;
      }
    } else {
      if (draft.startingPriceIqd <= 0) {
        setState(() => _error = l10n.createListingMissingStartingPrice);
        return;
      }
      if (draft.type == 'bazaar' && draft.startingPriceIqd > 10000) {
        setState(() => _error = l10n.createListingBazaarCap);
        return;
      }
    }

    setState(() {
      _publishing = true;
      _error = null;
    });

    try {
      final repo = ref.read(listingRepositoryProvider);
      await persistDraft(repo: repo, draft: draft);
      final published = await repo.publish(listing.id);
      ref.invalidate(myListingsProvider);
      ref.invalidate(endingSoonProvider);
      ref.invalidate(hotListingsProvider);
      ref.invalidate(bazaarListingsProvider);
      ref.read(listingDraftProvider.notifier).reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createListingPublished)),
      );
      context.go('/listings/${published.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.createListingPublishFailed(_humanReason(e)));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _humanReason(Object e) {
    final s = e.toString();
    if (s.contains('title_missing_locale')) return 'title_missing_locale';
    if (s.contains('description_missing_locale')) {
      return 'description_missing_locale';
    }
    if (s.contains('bazaar_price_ceiling_10000_iqd')) {
      return 'bazaar_price_ceiling_10000_iqd';
    }
    if (s.contains('kyc_tier_2_required')) return 'kyc_tier_2_required';
    if (s.contains('kyc_tier_1_required')) return 'kyc_tier_1_required';
    if (s.contains('buy_now_price_required_for_fixed')) {
      return 'buy_now_price_required_for_fixed';
    }
    if (s.contains('starting_price_required')) return 'starting_price_required';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(listingDraftProvider);
    final notifier = ref.read(listingDraftProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createListingReviewTitle),
        actions: [
          TextButton(
            onPressed: _publishing
                ? null
                : () {
                    ref.read(listingDraftProvider.notifier).reset();
                    context.go('/dashboard');
                  },
            child: Text(l10n.createListingDiscard),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          children: [
            Text(
              l10n.createListingReviewSubtitle,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: MazadTokens.onSurfaceMuted),
            ),
            const SizedBox(height: MazadTokens.sp5),
            _LocaleTabs(
              active: _activeLocale,
              onChanged: (l) => setState(() => _activeLocale = l),
            ),
            const SizedBox(height: MazadTokens.sp3),
            _LocaleEditor(
              locale: _activeLocale,
              title: _titleFor(draft, _activeLocale),
              description: _descFor(draft, _activeLocale),
              onTitleChanged: (v) => notifier.setTitle(_activeLocale, v),
              onDescriptionChanged: (v) =>
                  notifier.setDescription(_activeLocale, v),
            ),
            const SizedBox(height: MazadTokens.sp5),
            _CategorySelector(
              async: categoriesAsync,
              selectedId: draft.categoryId,
              onChanged: notifier.setCategory,
            ),
            const SizedBox(height: MazadTokens.sp4),
            _ConditionSelector(
              selected: draft.condition,
              onChanged: notifier.setCondition,
            ),
            const SizedBox(height: MazadTokens.sp5),
            _PriceSection(
              draft: draft,
              notifier: notifier,
            ),
            if (_error != null) ...[
              const SizedBox(height: MazadTokens.sp4),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: MazadTokens.error),
              ),
            ],
            const SizedBox(height: MazadTokens.sp5),
            FilledButton(
              onPressed: _publishing ? null : _publish,
              child: _publishing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: MazadTokens.sp3),
                        Text(l10n.createListingPublishing),
                      ],
                    )
                  : Text(l10n.createListingPublish),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(ListingDraft d, String l) => switch (l) {
        'en' => d.titleEn,
        'ar' => d.titleAr,
        'ku' => d.titleKu,
        'tr' => d.titleTr,
        _ => '',
      };

  String _descFor(ListingDraft d, String l) => switch (l) {
        'en' => d.descEn,
        'ar' => d.descAr,
        'ku' => d.descKu,
        'tr' => d.descTr,
        _ => '',
      };
}

class _LocaleTabs extends StatelessWidget {
  const _LocaleTabs({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <(String, String)>[
      ('en', l10n.createListingLocaleEn),
      ('ar', l10n.createListingLocaleAr),
      ('ku', l10n.createListingLocaleKu),
      ('tr', l10n.createListingLocaleTr),
    ];
    return Wrap(
      spacing: MazadTokens.sp2,
      children: tabs.map((t) {
        final selected = t.$1 == active;
        return ChoiceChip(
          label: Text(t.$2),
          selected: selected,
          onSelected: (_) => onChanged(t.$1),
          selectedColor: MazadTokens.primary.withValues(alpha: 0.16),
          side: BorderSide(
            color: selected ? MazadTokens.primary : MazadTokens.outline,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _LocaleEditor extends StatelessWidget {
  const _LocaleEditor({
    required this.locale,
    required this.title,
    required this.description,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  final String locale;
  final String title;
  final String description;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = locale == 'ar' || locale == 'ku';
    // Render this slice in the editor's locale so RTL flips per-locale
    // even when the app locale differs.
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: ValueKey('title-$locale'),
            initialValue: title,
            maxLength: 200,
            onChanged: onTitleChanged,
            decoration: InputDecoration(
              labelText: l10n.createListingFieldTitle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MazadTokens.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: MazadTokens.sp3),
          TextFormField(
            key: ValueKey('desc-$locale'),
            initialValue: description,
            maxLines: 5,
            maxLength: 4000,
            onChanged: onDescriptionChanged,
            decoration: InputDecoration(
              labelText: l10n.createListingFieldDescription,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MazadTokens.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends ConsumerWidget {
  const _CategorySelector({
    required this.async,
    required this.selectedId,
    required this.onChanged,
  });
  final AsyncValue<List<ListingCategory>> async;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.createListingFieldCategory, style: theme.textTheme.titleMedium),
        const SizedBox(height: MazadTokens.sp2),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(l10n.commonGenericError),
          data: (cats) => Wrap(
            spacing: MazadTokens.sp2,
            runSpacing: MazadTokens.sp2,
            children: cats.map((c) {
              final sel = selectedId == c.id;
              return ChoiceChip(
                label: Text(c.localizedName(lang)),
                selected: sel,
                onSelected: (_) => onChanged(sel ? null : c.id),
                selectedColor: MazadTokens.primary.withValues(alpha: 0.16),
                side: BorderSide(
                  color: sel ? MazadTokens.primary : MazadTokens.outline,
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = <(String, String)>[
      ('new', l10n.createListingConditionNew),
      ('like_new', l10n.createListingConditionLikeNew),
      ('good', l10n.createListingConditionGood),
      ('fair', l10n.createListingConditionFair),
      ('for_parts', l10n.createListingConditionForParts),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.createListingFieldCondition,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: MazadTokens.sp2),
        Wrap(
          spacing: MazadTokens.sp2,
          runSpacing: MazadTokens.sp2,
          children: options.map((o) {
            final sel = selected == o.$1;
            return ChoiceChip(
              label: Text(o.$2),
              selected: sel,
              onSelected: (_) => onChanged(o.$1),
              selectedColor: MazadTokens.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: sel ? MazadTokens.primary : MazadTokens.outline,
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.draft, required this.notifier});
  final ListingDraft draft;
  final ListingDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFixed = draft.type == 'fixed';
    final isAuction = draft.type == 'auction';
    final isBazaar = draft.type == 'bazaar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFixed)
          IqdPriceField(
            label: l10n.createListingFieldBuyNowPrice,
            value: draft.buyNowPriceIqd ?? 0,
            onChanged: (v) => notifier.setBuyNowPrice(v == 0 ? null : v),
          )
        else
          IqdPriceField(
            label: l10n.createListingFieldStartingPrice,
            value: draft.startingPriceIqd,
            maxIqd: isBazaar ? 10000 : null,
            onChanged: notifier.setStartingPrice,
          ),
        if (isAuction) ...[
          const SizedBox(height: MazadTokens.sp3),
          IqdPriceField(
            label: l10n.createListingFieldReservePrice,
            value: draft.reservePriceIqd ?? 0,
            onChanged: (v) => notifier.setReservePrice(v == 0 ? null : v),
          ),
        ],
        if (isBazaar) ...[
          const SizedBox(height: MazadTokens.sp2),
          Text(
            l10n.createListingBazaarCap,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: MazadTokens.onSurfaceMuted),
          ),
        ],
      ],
    );
  }
}
