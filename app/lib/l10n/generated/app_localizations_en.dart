// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mazad';

  @override
  String get homeWelcome => 'Welcome to Mazad';

  @override
  String get homeTagline => 'Iraq\'s most trusted auction marketplace.';

  @override
  String get switchLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of Mazad is no longer supported. Please update to continue.';

  @override
  String get updateNow => 'Update now';
}
