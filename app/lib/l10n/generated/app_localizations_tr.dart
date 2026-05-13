// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Mazad';

  @override
  String get homeWelcome => 'Mazad\'a hoş geldiniz';

  @override
  String get homeTagline => 'Irak\'ın en güvenilir açık artırma pazaryeri.';

  @override
  String get switchLanguage => 'Dil';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get updateRequiredTitle => 'Güncelleme gerekli';

  @override
  String get updateRequiredBody =>
      'Mazad\'ın bu sürümü artık desteklenmiyor. Devam etmek için lütfen güncelleyin.';

  @override
  String get updateNow => 'Şimdi güncelle';
}
