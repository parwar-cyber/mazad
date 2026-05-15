import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/design/theme.dart';
import 'package:mazad/core/i18n/ku_localization_delegates.dart';
import 'package:mazad/core/i18n/locale_provider.dart';
import 'package:mazad/core/router/app_router.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class MazadApp extends ConsumerWidget {
  const MazadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);
    final lang = locale.languageCode;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Sorani Kurdish proxies. Must come BEFORE the Global* delegates so
        // ku locales match these first; everything else falls through to
        // the bundled translations. See ku_localization_delegates.dart.
        KuMaterialLocalizationsDelegate(),
        KuCupertinoLocalizationsDelegate(),
        KuWidgetsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.dark,
      theme: buildMazadTheme(lang: lang, brightness: Brightness.light),
      darkTheme: buildMazadTheme(lang: lang, brightness: Brightness.dark),
    );
  }
}
