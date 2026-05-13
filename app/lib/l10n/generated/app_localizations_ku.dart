// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kurdish (`ku`).
class AppLocalizationsKu extends AppLocalizations {
  AppLocalizationsKu([String locale = 'ku']) : super(locale);

  @override
  String get appTitle => 'مەزاد';

  @override
  String get homeWelcome => 'بەخێربێیت بۆ مەزاد';

  @override
  String get homeTagline => 'متمانەپێکراوترین بازاڕی مەزاد لە عێراق.';

  @override
  String get homeSignIn => 'بچۆرە ژوورەوە بۆ دەستپێکردنی مەزایەدە';

  @override
  String get homeOpenDashboard => 'هەژمارەکەم بکەرەوە';

  @override
  String get switchLanguage => 'زمان';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get updateRequiredTitle => 'نوێکردنەوە پێویستە';

  @override
  String get updateRequiredBody =>
      'ئەم وەشانەی مەزاد ئیتر پشتگیری ناکرێت. تکایە نوێی بکەرەوە بۆ بەردەوامبوون.';

  @override
  String get updateNow => 'ئێستا نوێی بکەرەوە';

  @override
  String get authPhoneTitle => 'چوونەژوورەوە';

  @override
  String get authPhoneSubtitle =>
      'ژمارەی مۆبایلەکەت بنووسە. کۆدێکی یەکجارەییت بۆ دەنێرین بە SMS.';

  @override
  String get authPhoneLabel => 'ژمارەی مۆبایل';

  @override
  String get authPhoneHint => '+964 7XX XXX XXXX';

  @override
  String get authPhoneSend => 'کۆد بنێرە';

  @override
  String get authPhoneInvalid => 'ژمارەیەکی دروستی مۆبایلی عێراقی بنووسە.';

  @override
  String get authOtpTitle => 'کۆدەکە بنووسە';

  @override
  String authOtpSubtitle(String phone) {
    return 'کۆدێکی ٦ ژمارەییمان نارد بۆ $phone.';
  }

  @override
  String get authOtpLabel => 'کۆدی ٦ ژمارەیی';

  @override
  String get authOtpVerify => 'پشتڕاستکردنەوە';

  @override
  String get authOtpResend => 'دووبارە کۆد بنێرە';

  @override
  String get authOtpInvalid => 'کۆدەکە دروست نییە. دووبارە هەوڵ بدە.';

  @override
  String get authOtpExpired => 'کاتی کۆدەکە تەواو بووە. کۆدێکی نوێ داوا بکە.';

  @override
  String get authOtpRateLimited => 'هەوڵی زۆر. دواتر هەوڵ بدە.';

  @override
  String get authSignOut => 'چوونەدەرەوە';

  @override
  String get profileSetupTitle => 'ڕێکخستنی پرۆفایل';

  @override
  String get profileSetupSubtitle =>
      'هەر کاتێک دەتوانیت لە ڕێکخستنەکانەوە بیگۆڕیت.';

  @override
  String get profileDisplayNameLabel => 'ناوی پیشاندان';

  @override
  String get profileDisplayNameHint => 'کڕیار و فرۆشیار چۆن دەتبینن';

  @override
  String get profileLocaleLabel => 'زمان';

  @override
  String get profileCityLabel => 'شار';

  @override
  String get profileCityHint => 'نموونە: هەولێر، سلێمانی، بەغداد';

  @override
  String get profileSave => 'پاشەکەوت بکە';

  @override
  String get profileSaved => 'پرۆفایل پاشەکەوت کرا.';

  @override
  String tier1Granted(String limit) {
    return 'پشتڕاستکراوەیت — دەتوانیت مەزایەدە و کڕین بکەیت تا $limit.';
  }

  @override
  String get tier2Granted =>
      'وەک فرۆشیار پشتڕاستکرایت — ئێستا دەتوانیت کاڵا تۆمار بکەیت.';

  @override
  String get tierBadge0 => 'بینەر';

  @override
  String get tierBadge1 => 'کڕیاری پشتڕاستکراو';

  @override
  String get tierBadge2 => 'فرۆشیاری پشتڕاستکراو';

  @override
  String get kycIntroTitle => 'دەست بە فرۆش بکە لە مەزاد';

  @override
  String get kycIntroSubtitle =>
      'ناسنامەکەت پشتڕاست بکەرەوە بۆ تۆمارکردنی کاڵا. نزیکەی سێ خولەک دەخایەنێت.';

  @override
  String get kycIntroStep1 => 'وێنەی ناسنامەکەت بگرە';

  @override
  String get kycIntroStep2 => 'ناونیشانەکەت زیاد بکە';

  @override
  String get kycIntroStep3 => 'شێوازی وەرگرتنی پارە هەڵبژێرە';

  @override
  String get kycIntroBegin => 'دەست بە پشتڕاستکردنەوە بکە';

  @override
  String get kycIntroCancel => 'ئێستا نا';

  @override
  String get kycIdTitle => 'وێنەی ناسنامەکەت بگرە';

  @override
  String get kycIdSubtitle =>
      'ناسنامەی نیشتمانی عێراقی، پاسپۆرت یان کارتی نیشتەجێبوون. دڵنیابە لە دەرکەوتنی هەر چوار گۆشە.';

  @override
  String get kycIdPickFromCamera => 'کامێرا بەکار بهێنە';

  @override
  String get kycIdPickFromGallery => 'لە وێنەکانەوە هەڵبژێرە';

  @override
  String get kycIdReplace => 'وێنە بگۆڕە';

  @override
  String get kycIdContinue => 'بەردەوام بە';

  @override
  String get kycIdMissing => 'تکایە وێنەیەکی ناسنامە زیاد بکە.';

  @override
  String get kycIdUploading => 'بارکردن…';

  @override
  String get kycIdUploadFailed =>
      'بارکردن سەرکەوتوو نەبوو. پەیوەندیت بپشکنە و دووبارە هەوڵ بدە.';

  @override
  String get kycAddressTitle => 'لە کوێ نیشتەجێیت؟';

  @override
  String get kycAddressSubtitle =>
      'ئەم زانیاریە بۆ پەیوەندی بە کڕیارانی ناوخۆیی و ڕێکخستنی گەیاندن بەکار دەبەین.';

  @override
  String get kycAddressLine1Label => 'شەقام و بینا';

  @override
  String get kycAddressLine2Label => 'شوقە، نهۆم (ئارەزوومەندانە)';

  @override
  String get kycAddressCityLabel => 'شار';

  @override
  String get kycAddressGovernorateLabel => 'پارێزگا';

  @override
  String get kycAddressContinue => 'بەردەوام بە';

  @override
  String get kycAddressMissing => 'شەقام و شار پێویستن.';

  @override
  String get kycPayoutTitle => 'چۆن دەتەوێت پارە وەربگریت؟';

  @override
  String get kycPayoutSubtitle =>
      'پارەی کڕیار لە ئامانەتدا دەهێڵینەوە و دوای گەیاندن بۆتی دەنێرین.';

  @override
  String get kycPayoutZainCash => 'جزدانی زینکاش';

  @override
  String get kycPayoutFastPay => 'جزدانی فاستپەی';

  @override
  String get kycPayoutBank => 'گواستنەوەی بانک';

  @override
  String get kycPayoutCod => 'تەنها پارەدان لە کاتی گەیاندن';

  @override
  String get kycPayoutAccountLabel => 'ژمارەی جزدان یان هەژمار';

  @override
  String get kycPayoutAccountHint =>
      'ژمارەکەی پەیوەست بە شێوازی هەڵبژێردراو بنووسە';

  @override
  String get kycPayoutContinue => 'بەردەوام بە';

  @override
  String get kycReviewTitle => 'پێداچوونەوە و ناردن';

  @override
  String get kycReviewBusinessNameLabel => 'ناوی بازرگانی یان فرۆشیار';

  @override
  String get kycReviewBusinessNameHint =>
      'بۆ کڕیار لە ڕیکلامەکانتدا پیشان دەدرێت';

  @override
  String get kycReviewSubmit => 'پشتڕاستکردنەوە بنێرە';

  @override
  String get kycReviewSubmitting => 'ناردن…';

  @override
  String get kycReviewSubmitted =>
      'پشتڕاستکردنەوە نێردرا. ئێستا دەتوانیت کاڵا تۆمار بکەیت.';

  @override
  String get kycReviewSubmitFailed =>
      'نەمانتوانی پشتڕاستکردنەوەکەت بنێرین. دووبارە هەوڵ بدە.';

  @override
  String get dashboardTitle => 'هەژمارم لە مەزاد';

  @override
  String get dashboardTabBids => 'مەزایەدەکان';

  @override
  String get dashboardTabWatchlist => 'دڵخوازەکان';

  @override
  String get dashboardTabWins => 'براوەکان';

  @override
  String get dashboardTabListings => 'ڕیکلامەکانم';

  @override
  String get dashboardTabOrders => 'داواکارییەکان';

  @override
  String get dashboardTabWallet => 'جزدان';

  @override
  String get dashboardTabRatings => 'نرخاندنەکان';

  @override
  String get dashboardEmptyBids =>
      'هیچ مەزایەدەیەکی چالاک نییە. ڕیکلامەکان بگەڕێ بۆ دەستپێکردن.';

  @override
  String get dashboardEmptyWatchlist =>
      'هیچ شت لە دڵخوازەکاندا نییە. لە هەر ڕیکلامێک دڵەکە بکێشە بۆ پاشەکەوت.';

  @override
  String get dashboardEmptyWins => 'هێشتا براوە نیت. یەکەم مەزایەدەت بکە.';

  @override
  String get dashboardEmptyListings => 'هێشتا هیچ ڕیکلامێکت تۆمار نەکردووە.';

  @override
  String get dashboardStartSelling => 'دەست بە فرۆش بکە';

  @override
  String get dashboardEmptyOrders => 'هێشتا هیچ داواکارییەک نییە.';

  @override
  String get dashboardEmptyWallet => 'چالاکی جزدانەکەت لێرە دەردەکەوێت.';

  @override
  String get dashboardEmptyRatings =>
      'نرخاندنەکان دوای یەکەم داواکاری تەواو بوو لێرە دەردەکەون.';

  @override
  String get commonCancel => 'هەڵوەشاندنەوە';

  @override
  String get commonBack => 'گەڕانەوە';

  @override
  String get commonRetry => 'دووبارە هەوڵ بدە';

  @override
  String get commonContinue => 'بەردەوام بە';

  @override
  String get commonRequired => 'پێویستە';

  @override
  String get commonGenericError => 'هەڵەیەک ڕوویدا. تکایە دووبارە هەوڵ بدە.';
}
