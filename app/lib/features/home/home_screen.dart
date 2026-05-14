import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/i18n/locale_provider.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/listings/browse/home_feed.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Anonymous + authed landing.  Wraps the public Home Feed (architecture
/// §3 — Live now, Hot, Group Bazaar, Categories) with a header that
/// surfaces auth + dashboard CTAs and the language switcher.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(
            tooltip: l10n.browseTitle,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/browse'),
          ),
          _LocaleSwitcher(current: currentLocale),
          IconButton(
            tooltip: user == null ? l10n.homeSignIn : l10n.homeOpenDashboard,
            icon: Icon(user == null ? Icons.login : Icons.person_outline),
            onPressed: () =>
                user == null ? context.push('/auth') : context.push('/dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MazadTokens.sp5,
                MazadTokens.sp4,
                MazadTokens.sp5,
                MazadTokens.sp2,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.homeTagline,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: MazadTokens.onSurfaceMuted),
                ),
              ),
            ),
            const Expanded(child: HomeFeed()),
          ],
        ),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/sell'),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeFabSell),
            ),
    );
  }
}

class _LocaleSwitcher extends ConsumerWidget {
  const _LocaleSwitcher({required this.current});
  final Locale current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.switchLanguage,
      icon: const Icon(Icons.language_outlined),
      onSelected: (l) => ref.read(localeProvider.notifier).state = l,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(l10n.languageEnglish),
        ),
        PopupMenuItem(
          value: const Locale('ar'),
          child: Text(l10n.languageArabic),
        ),
        PopupMenuItem(
          value: const Locale('ku'),
          child: Text(l10n.languageKurdish),
        ),
        PopupMenuItem(
          value: const Locale('tr'),
          child: Text(l10n.languageTurkish),
        ),
      ],
    );
  }
}
