import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing_draft.dart';
import 'package:mazad/features/listings/data/listing_providers.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Step 3 — run analyze_item, show the suggestion, let the user accept or
/// skip to manual entry.
class ListingAiScreen extends ConsumerStatefulWidget {
  const ListingAiScreen({super.key});

  @override
  ConsumerState<ListingAiScreen> createState() => _ListingAiScreenState();
}

class _ListingAiScreenState extends ConsumerState<ListingAiScreen> {
  bool _running = false;
  String? _error;

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(listingDraftProvider);
    final id = draft.serverListing?.id;
    if (id == null) {
      setState(() => _error = l10n.commonGenericError);
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      // Force a fresh run.  The provider is family-keyed by listing_id, so
      // invalidating then awaiting `.future` re-invokes the Edge Function.
      ref.invalidate(analyzeItemProvider(id));
      final value = await ref.read(analyzeItemProvider(id).future);
      final cats =
          ref.read(categoriesProvider).value ?? const <ListingCategory>[];
      String? matchedCategoryId;
      for (final c in cats) {
        if (c.slug == value.categorySlug) {
          matchedCategoryId = c.id;
          break;
        }
      }
      ref
          .read(listingDraftProvider.notifier)
          .applySuggestion(value, categoryId: matchedCategoryId);
      if (!mounted) return;
      context.push('/sell/review');
    } catch (_) {
      setState(() => _error = l10n.createListingAiFailed);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _skip() => context.push('/sell/review');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(listingDraftProvider);
    final hasSuggestion = draft.suggestion != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createListingAiTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createListingAiSubtitle,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
              const SizedBox(height: MazadTokens.sp5),
              if (_running)
                _AssistantBusy(label: l10n.createListingAiRunning)
              else if (hasSuggestion)
                Expanded(child: _SuggestionPreview(draft: draft))
              else
                const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: MazadTokens.error),
                ),
                const SizedBox(height: MazadTokens.sp2),
              ],
              if (hasSuggestion)
                FilledButton(
                  onPressed: () => context.push('/sell/review'),
                  child: Text(l10n.createListingAiContinue),
                )
              else
                FilledButton(
                  onPressed: _running ? null : _run,
                  child: Text(l10n.createListingAiRun),
                ),
              const SizedBox(height: MazadTokens.sp2),
              TextButton(
                onPressed: _running ? null : _skip,
                child: Text(l10n.createListingAiSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantBusy extends StatelessWidget {
  const _AssistantBusy({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: MazadTokens.sp4),
            Text(label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: MazadTokens.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

class _SuggestionPreview extends StatelessWidget {
  const _SuggestionPreview({required this.draft});
  final ListingDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = draft.suggestion!;
    return ListView(
      children: [
        _Row(label: l10n.createListingFieldTitle, value: s.title['en'] ?? ''),
        _Row(
            label: l10n.createListingFieldDescription,
            value: (s.description['en'] ?? '').replaceAll('\n', ' ')),
        _Row(
            label: l10n.createListingFieldCondition,
            value: s.condition),
        if (s.redFlags.isNotEmpty) ...[
          const SizedBox(height: MazadTokens.sp4),
          Container(
            padding: const EdgeInsetsDirectional.all(MazadTokens.sp3),
            decoration: BoxDecoration(
              color: MazadTokens.error.withValues(alpha: 0.08),
              border: Border.all(color: MazadTokens.error),
              borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.createListingAiRedFlagsTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: MazadTokens.error)),
                const SizedBox(height: MazadTokens.sp2),
                ...s.redFlags.map((f) => Padding(
                      padding:
                          const EdgeInsetsDirectional.only(top: MazadTokens.sp1),
                      child: Text('• $f', style: theme.textTheme.bodyMedium),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: MazadTokens.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: MazadTokens.onSurfaceMuted)),
          const SizedBox(height: MazadTokens.sp1),
          Text(value.isEmpty ? '—' : value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
