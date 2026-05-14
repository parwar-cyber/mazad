import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/features/listings/widgets/listing_grid.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Browse / search screen.  Composes search_listings with filters and a
/// debounced query input.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, this.initialCategoryId, this.initialType});

  final String? initialCategoryId;
  final String? initialType;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late final TextEditingController _query;
  Timer? _debounce;
  String? _category;
  String? _type;
  List<Listing> _results = const <Listing>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _category = widget.initialCategoryId;
    _type = widget.initialType;
    _runSearch();
  }

  @override
  void dispose() {
    _query.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(listingRepositoryProvider).search(
            query: _query.text,
            categoryId: _category,
            type: _type,
          );
      if (!mounted) return;
      setState(() => _results = res);
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = AppLocalizations.of(context).commonGenericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.browseTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  MazadTokens.sp5, MazadTokens.sp4, MazadTokens.sp5, MazadTokens.sp2),
              child: TextField(
                controller: _query,
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _runSearch(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.browseSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                ),
              ),
            ),
            _TypeFilterRow(
              active: _type,
              onChanged: (t) {
                setState(() => _type = t);
                _runSearch();
              },
            ),
            categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) => _CategoryFilterRow(
                categories: cats,
                active: _category,
                onChanged: (id) {
                  setState(() => _category = id);
                  _runSearch();
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding:
                    const EdgeInsetsDirectional.all(MazadTokens.sp3),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: MazadTokens.error),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? _EmptyResults(message: l10n.browseEmpty)
                      : ListingGrid(listings: _results),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({required this.active, required this.onChanged});
  final String? active;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <(String?, String)>[
      (null, l10n.browseFilterAll),
      ('auction', l10n.browseFilterAuction),
      ('fixed', l10n.browseFilterFixed),
      ('bazaar', l10n.browseFilterBazaar),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp5,
        vertical: MazadTokens.sp2,
      ),
      child: Row(
        children: [
          for (final t in tabs) ...[
            ChoiceChip(
              label: Text(t.$2),
              selected: active == t.$1,
              onSelected: (_) => onChanged(t.$1),
            ),
            const SizedBox(width: MazadTokens.sp2),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.active,
    required this.onChanged,
  });
  final List<ListingCategory> categories;
  final String? active;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp5,
        vertical: MazadTokens.sp1,
      ),
      child: Row(
        children: [
          for (final c in categories) ...[
            FilterChip(
              label: Text(c.localizedName(lang)),
              selected: active == c.id,
              onSelected: (sel) => onChanged(sel ? c.id : null),
            ),
            const SizedBox(width: MazadTokens.sp2),
          ],
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MazadTokens.sp6),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: MazadTokens.onSurfaceMuted),
        ),
      ),
    );
  }
}
