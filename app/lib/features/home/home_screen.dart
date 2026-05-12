import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/core/i18n/locale_provider.dart';
import 'package:mazad/features/system/force_update_notifier.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Phase 0 placeholder. Exists to demonstrate:
///   1. ARB strings render in the selected locale.
///   2. RTL flips correctly for ar/ku.
///   3. Locale switcher works end-to-end.
///   4. A debug button can trigger the force-update flow.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
                  _LocaleSwitcher(current: currentLocale),
                ],
              ),
              const SizedBox(height: MazadTokens.sp6),
              Text(l10n.homeWelcome, style: theme.textTheme.displayMedium),
              const SizedBox(height: MazadTokens.sp3),
              Text(
                l10n.homeTagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: MazadTokens.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              // Debug-only: simulate a 426 from the backend so reviewers can
              // see the force-update screen without a real server.
              OutlinedButton(
                onPressed: () => ForceUpdateNotifier.instance.trigger(
                  minVersion: '1.4.3',
                  storeUrl: 'https://play.google.com/store/apps/details?id=com.mazad.app',
                  releaseNotes: const {
                    'en': 'Critical bid-engine fix.',
                    'ar': 'إصلاح حرج في محرك المزايدات.',
                    'ku': 'چاککردنەوەی گرنگ لە سیستەمی مەزاد.',
                    'tr': 'Kritik teklif motoru düzeltmesi.',
                  },
                ),
                child: Text(
                  'Trigger force-update (dev)',
                  style: tabularNumeric(theme.textTheme.labelLarge!),
                ),
              ),
            ],
          ),
        ),
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
    return DropdownButton<Locale>(
      value: current,
      underline: const SizedBox.shrink(),
      onChanged: (l) {
        if (l != null) ref.read(localeProvider.notifier).state = l;
      },
      items: [
        DropdownMenuItem(value: const Locale('en'), child: Text(l10n.languageEnglish)),
        DropdownMenuItem(value: const Locale('ar'), child: Text(l10n.languageArabic)),
        DropdownMenuItem(value: const Locale('ku'), child: Text(l10n.languageKurdish)),
        DropdownMenuItem(value: const Locale('tr'), child: Text(l10n.languageTurkish)),
      ],
    );
  }
}
