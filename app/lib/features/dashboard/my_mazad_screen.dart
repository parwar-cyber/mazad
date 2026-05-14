import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/money/money_format.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/auth/data/auth_service.dart';
import 'package:mazad/features/auth/data/profile.dart';
import 'package:mazad/features/listings/dashboard/my_listings_panel.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// "My Mazad" dashboard skeleton — see architecture.md §3.
///
/// Phase 1 scope: routed tabs with placeholder bodies. Each tab's real
/// content lands in a later phase (Bids/Wins/Listings in Phase 3,
/// Watchlist in Phase 5, Orders/Wallet in Phase 7, Ratings in Phase 8).
class MyMazadScreen extends ConsumerWidget {
  const MyMazadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(myProfileProvider);

    final tabs = <_DashboardTab>[
      _DashboardTab(
        icon: Icons.gavel_outlined,
        label: l10n.dashboardTabBids,
        body: _Placeholder(message: l10n.dashboardEmptyBids),
      ),
      _DashboardTab(
        icon: Icons.favorite_outline,
        label: l10n.dashboardTabWatchlist,
        body: _Placeholder(message: l10n.dashboardEmptyWatchlist),
      ),
      _DashboardTab(
        icon: Icons.emoji_events_outlined,
        label: l10n.dashboardTabWins,
        body: _Placeholder(message: l10n.dashboardEmptyWins),
      ),
      _DashboardTab(
        icon: Icons.sell_outlined,
        label: l10n.dashboardTabListings,
        body: profileAsync.when(
          data: (p) => p == null
              ? const _LoadingTab()
              : (p.kycTier >= 1
                  ? const MyListingsPanel()
                  : const _StartSellingCta()),
          loading: () => const _LoadingTab(),
          error: (_, __) => _Placeholder(message: l10n.commonGenericError),
        ),
      ),
      _DashboardTab(
        icon: Icons.receipt_long_outlined,
        label: l10n.dashboardTabOrders,
        body: _Placeholder(message: l10n.dashboardEmptyOrders),
      ),
      _DashboardTab(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.dashboardTabWallet,
        body: _Placeholder(message: l10n.dashboardEmptyWallet),
      ),
      _DashboardTab(
        icon: Icons.star_border,
        label: l10n.dashboardTabRatings,
        body: _Placeholder(message: l10n.dashboardEmptyRatings),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboardTitle),
          actions: [
            IconButton(
              tooltip: l10n.authSignOut,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: MazadTokens.primary,
            tabs: tabs
                .map((t) => Tab(icon: Icon(t.icon), text: t.label))
                .toList(growable: false),
          ),
        ),
        body: Column(
          children: [
            profileAsync.when(
              data: (p) => p == null
                  ? const SizedBox.shrink()
                  : _TierBanner(profile: p),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: TabBarView(
                children: tabs.map((t) => t.body).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.icon,
    required this.label,
    required this.body,
  });
  final IconData icon;
  final String label;
  final Widget body;
}

class _TierBanner extends ConsumerWidget {
  const _TierBanner({required this.profile});
  final MazadProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    final tier = profile.kycTier;
    final label = switch (tier) {
      0 => l10n.tierBadge0,
      1 => l10n.tierBadge1,
      2 => l10n.tierBadge2,
      _ => l10n.tierBadge0,
    };

    // Show the Tier-1 ceiling as a reassurance line for new users.
    final ceilingText = tier == 1
        ? l10n.tier1Granted(formatIQD(KycTierCeiling.tier1, locale))
        : tier == 2
            ? l10n.tier2Granted
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MazadTokens.sp5,
        vertical: MazadTokens.sp3,
      ),
      decoration: BoxDecoration(
        color: MazadTokens.surface,
        border: const BorderDirectional(
          bottom: BorderSide(color: MazadTokens.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined,
                  size: 18, color: MazadTokens.primary),
              const SizedBox(width: MazadTokens.sp2),
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
          if (ceilingText != null) ...[
            const SizedBox(height: MazadTokens.sp1),
            Text(ceilingText,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MazadTokens.onSurfaceMuted)),
          ],
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.message});
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

class _LoadingTab extends StatelessWidget {
  const _LoadingTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _StartSellingCta extends ConsumerWidget {
  const _StartSellingCta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MazadTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.dashboardEmptyListings,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: MazadTokens.onSurfaceMuted),
            ),
            const SizedBox(height: MazadTokens.sp4),
            FilledButton(
              onPressed: () => context.push('/kyc'),
              child: Text(l10n.dashboardStartSelling),
            ),
          ],
        ),
      ),
    );
  }
}
