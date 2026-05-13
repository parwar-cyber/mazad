// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مزاد';

  @override
  String get homeWelcome => 'مرحبًا بك في مزاد';

  @override
  String get homeTagline => 'منصة المزادات الأكثر موثوقية في العراق.';

  @override
  String get switchLanguage => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get updateRequiredTitle => 'التحديث مطلوب';

  @override
  String get updateRequiredBody =>
      'هذه النسخة من مزاد لم تعد مدعومة. يرجى التحديث للمتابعة.';

  @override
  String get updateNow => 'حدّث الآن';
}
