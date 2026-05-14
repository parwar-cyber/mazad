import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/listings/data/listing_draft.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Step 1 — pick the listing type and create the server draft row.
///
/// Tier gating:
///   * Tier 0 (browse): not even on this screen — the dashboard CTA is
///     hidden.  Router defends in depth by redirecting back to /kyc.
///   * Tier 1: can pick "fixed" or "bazaar".  "auction" is shown disabled
///     with a hint to upgrade.
///   * Tier 2: all three options enabled.
class ListingTypeScreen extends ConsumerWidget {
  const ListingTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createListingTitle)),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.commonGenericError)),
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(l10n.commonGenericError));
            }
            return Padding(
              padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createListingChooseType,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: MazadTokens.sp5),
                  Expanded(
                    child: ListView(
                      children: [
                        _TypeCard(
                          type: 'fixed',
                          title: l10n.createListingTypeFixed,
                          subtitle: l10n.createListingTypeFixedDesc,
                          icon: Icons.local_offer_outlined,
                          enabled: profile.kycTier >= 1,
                          lockedHint: l10n.createListingTier1Locked,
                        ),
                        const SizedBox(height: MazadTokens.sp3),
                        _TypeCard(
                          type: 'auction',
                          title: l10n.createListingTypeAuction,
                          subtitle: l10n.createListingTypeAuctionDesc,
                          icon: Icons.gavel_outlined,
                          enabled: profile.kycTier >= 2,
                          lockedHint: l10n.createListingAuctionLocked,
                        ),
                        const SizedBox(height: MazadTokens.sp3),
                        _TypeCard(
                          type: 'bazaar',
                          title: l10n.createListingTypeBazaar,
                          subtitle: l10n.createListingTypeBazaarDesc,
                          icon: Icons.groups_outlined,
                          enabled: profile.kycTier >= 1,
                          lockedHint: l10n.createListingTier1Locked,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypeCard extends ConsumerStatefulWidget {
  const _TypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.lockedHint,
  });

  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final String lockedHint;

  @override
  ConsumerState<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends ConsumerState<_TypeCard> {
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    if (!widget.enabled) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final listing = await repo.createDraft(widget.type);
      ref.read(listingDraftProvider.notifier)
        ..reset()
        ..setType(widget.type)
        ..setServerListing(listing);
      if (!mounted) return;
      context.push('/sell/photos');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(Object e) {
    final s = e.toString();
    final l10n = AppLocalizations.of(context);
    if (s.contains('kyc_tier_2_required')) return l10n.createListingAuctionLocked;
    if (s.contains('kyc_tier_1_required')) return l10n.createListingTier1Locked;
    return l10n.commonGenericError;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !widget.enabled || _busy;
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _pick,
          borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
          child: Container(
            padding: const EdgeInsetsDirectional.all(MazadTokens.sp4),
            decoration: BoxDecoration(
              color: MazadTokens.surface,
              border: Border.all(color: MazadTokens.outline),
              borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MazadTokens.primary.withValues(alpha: 0.12),
                    border: Border.all(color: MazadTokens.primary),
                  ),
                  child: Icon(widget.icon, color: MazadTokens.primary),
                ),
                const SizedBox(width: MazadTokens.sp4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: MazadTokens.sp1),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: MazadTokens.onSurfaceMuted),
                      ),
                      if (!widget.enabled) ...[
                        const SizedBox(height: MazadTokens.sp2),
                        Text(
                          widget.lockedHint,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: MazadTokens.error),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: MazadTokens.sp2),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: MazadTokens.error),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: MazadTokens.onSurfaceMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

