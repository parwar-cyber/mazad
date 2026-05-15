import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazad/core/i18n/ku_localization_delegates.dart';

/// These tests are the regression guard for the "No MaterialLocalizations
/// found" exception that fires when the app is in Sorani Kurdish (`ku`)
/// because `flutter_localizations` doesn't ship ku translations. The fix
/// proxies ku to the Arabic implementations of the three framework
/// localizations delegates.

void main() {
  const delegates = <LocalizationsDelegate<dynamic>>[
    KuMaterialLocalizationsDelegate(),
    KuCupertinoLocalizationsDelegate(),
    KuWidgetsLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  testWidgets('ku locale resolves MaterialLocalizations without throwing',
      (tester) async {
    MaterialLocalizations? captured;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ku'),
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('ku'),
          Locale('tr'),
        ],
        localizationsDelegates: delegates,
        home: Builder(
          builder: (context) {
            captured = MaterialLocalizations.of(context);
            return const Scaffold(body: Text('ok'));
          },
        ),
      ),
    );

    expect(captured, isNotNull);
    // Proxy returned the Arabic implementation: the OK label must NOT be
    // the English "OK", and must contain Arabic-script characters.
    expect(captured!.okButtonLabel, isNot('OK'));
    expect(RegExp(r'[؀-ۿ]').hasMatch(captured!.okButtonLabel), isTrue,
        reason: 'Arabic OK label should contain Arabic-script characters');
  });

  testWidgets('ku locale resolves CupertinoLocalizations without throwing',
      (tester) async {
    CupertinoLocalizations? captured;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ku'),
        supportedLocales: const [Locale('en'), Locale('ku')],
        localizationsDelegates: delegates,
        home: Builder(
          builder: (context) {
            captured = CupertinoLocalizations.of(context);
            return const Scaffold(body: Text('ok'));
          },
        ),
      ),
    );

    expect(captured, isNotNull);
  });

  testWidgets('ku locale picks RTL TextDirection via the widgets proxy',
      (tester) async {
    TextDirection? dir;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ku'),
        supportedLocales: const [Locale('en'), Locale('ku')],
        localizationsDelegates: delegates,
        home: Builder(
          builder: (context) {
            dir = Directionality.of(context);
            return const Scaffold(body: Text('ok'));
          },
        ),
      ),
    );

    expect(dir, TextDirection.rtl,
        reason: 'ku must flow RTL, matching the Arabic proxy implementation');
  });

  testWidgets('non-ku locales still fall through to the global delegates',
      (tester) async {
    String? okLabel;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ku')],
        localizationsDelegates: delegates,
        home: Builder(
          builder: (context) {
            okLabel = MaterialLocalizations.of(context).okButtonLabel;
            return const Scaffold(body: Text('ok'));
          },
        ),
      ),
    );

    // English uses the standard "OK" — proves our ku-only proxies didn't
    // accidentally hijack other locales.
    expect(okLabel, 'OK');
  });
}
