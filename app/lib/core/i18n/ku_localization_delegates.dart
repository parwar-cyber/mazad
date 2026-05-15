import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Sorani Kurdish (`ku`) isn't shipped in `flutter_localizations`, so
/// `MaterialLocalizations.of(context)` throws as soon as the user switches
/// to ku and any Material widget (Drawer, BottomSheet, ListTile semantics,
/// etc.) tries to read framework strings.
///
/// We proxy the three framework delegates to their Arabic (`ar`)
/// implementations.  Arabic and Sorani share the same script and the same
/// RTL direction, so the Arabic strings are the closest off-the-shelf fit
/// for framework-level UI (cut/copy/paste menus, time pickers, dialog
/// buttons).  Our own ARB-based [AppLocalizations] already has a real `ku`
/// translation — those are unaffected.
///
/// Place these delegates BEFORE `GlobalMaterialLocalizations.delegate` in
/// the `MaterialApp.localizationsDelegates` list.  Flutter walks the list
/// and picks the first delegate whose [isSupported] returns true, so the
/// ku-only proxy fires for ku and the global delegates handle everything
/// else.
///
/// Reference: Flutter docs, "Internationalizing Flutter apps" §"Custom
/// locale plugin".

class KuMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuMaterialLocalizationsDelegate old) => false;
}

class KuCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KuCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuCupertinoLocalizationsDelegate old) => false;
}

class KuWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const KuWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuWidgetsLocalizationsDelegate old) => false;
}
