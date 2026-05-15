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

  @override
  String get createListingTitle => 'تۆمارکردنی کاڵا';

  @override
  String get createListingChooseType => 'چی دەفرۆشیت؟';

  @override
  String get createListingTypeAuction => 'مەزاد';

  @override
  String get createListingTypeAuctionDesc =>
      'نرخی دەستپێک دیاری بکە و کڕیاران مەزایەدە بکەن.';

  @override
  String get createListingTypeFixed => 'ئێستا بکڕە';

  @override
  String get createListingTypeFixedDesc => 'یەک نرخ. یەکەم کڕیار براوەیە.';

  @override
  String get createListingTypeBazaar => 'بازاڕی گروپی';

  @override
  String get createListingTypeBazaarDesc =>
      'کەمتر لە ١٠٬٠٠٠ دینار. نرخ دادەبەزێت کاتێک کڕیاری زیاتر بەشدار دەبێت.';

  @override
  String get createListingAuctionLocked =>
      'ڕیکلامی مەزاد پێویستی بە پشتڕاستکردنەوەی ئاستی ٢ هەیە.';

  @override
  String get createListingTier1Locked =>
      'پێش تۆمارکردن مۆبایلت پشتڕاست بکەرەوە.';

  @override
  String get createListingPhotosTitle => 'وێنە زیاد بکە';

  @override
  String get createListingPhotosSubtitle =>
      'سێ بۆ پێنج وێنەی ڕوون. بەکاریان دەهێنین بۆ نووسینی ڕیکلامەکەت بە چوار زمان.';

  @override
  String get createListingPhotoFromCamera => 'کامێرا';

  @override
  String get createListingPhotoFromGallery => 'گاڵەری';

  @override
  String get createListingPhotoMinError => 'کەمترین سێ وێنە زیاد بکە.';

  @override
  String get createListingPhotosUploading => 'بارکردن…';

  @override
  String get createListingPhotosFailed =>
      'نەمانتوانی هەندێک وێنە بار بکەین. دووبارە هەوڵ بدە.';

  @override
  String get createListingPhotosContinue => 'بەردەوام بە';

  @override
  String createListingPhotosCount(int count) {
    return '$count لە ١٠';
  }

  @override
  String get createListingAiTitle => 'یاریدەدەری زیرەک';

  @override
  String get createListingAiSubtitle =>
      'وێنەکانت دەخوێنینەوە و ڕیکلامێک بە چوار زمان دەنووسین. دواتر دەتوانیت دەستکاری بکەیت.';

  @override
  String get createListingAiRun => 'نووسینی ڕەشنووس';

  @override
  String get createListingAiRunning => 'وێنەکانت دەخوێنینەوە…';

  @override
  String get createListingAiFailed =>
      'نەمانتوانی ڕەشنووس دروست بکەین. خۆت خانەکان پڕ بکەرەوە.';

  @override
  String get createListingAiRedFlagsTitle => 'ئاگاداربە';

  @override
  String get createListingAiSkip => 'بەدەستی پڕی بکەرەوە';

  @override
  String get createListingAiContinue => 'بەردەوام بە بۆ پێداچوونەوە';

  @override
  String get createListingReviewTitle => 'پێداچوونەوە و بڵاوکردنەوە';

  @override
  String get createListingReviewSubtitle =>
      'کڕیاران بەو شێوەیە دەیبینن. هەرشتێک ناڕاست بوو دەستکاری بکە.';

  @override
  String get createListingFieldTitle => 'ناونیشان';

  @override
  String get createListingFieldDescription => 'وەسف';

  @override
  String get createListingFieldCategory => 'پۆل';

  @override
  String get createListingFieldCondition => 'حاڵەت';

  @override
  String get createListingFieldStartingPrice => 'نرخی دەستپێک (د.ع)';

  @override
  String get createListingFieldBuyNowPrice => 'نرخی کڕینی فۆری (د.ع)';

  @override
  String get createListingFieldReservePrice =>
      'نرخی هاوبەشی (ئارەزوومەندانە، د.ع)';

  @override
  String get createListingLocaleEn => 'EN';

  @override
  String get createListingLocaleAr => 'AR';

  @override
  String get createListingLocaleKu => 'KU';

  @override
  String get createListingLocaleTr => 'TR';

  @override
  String get createListingConditionNew => 'نوێ';

  @override
  String get createListingConditionLikeNew => 'وەکوو نوێ';

  @override
  String get createListingConditionGood => 'باش';

  @override
  String get createListingConditionFair => 'ناوەند';

  @override
  String get createListingConditionForParts => 'بۆ پارچەکان';

  @override
  String get createListingPublish => 'بڵاوکردنەوەی ڕیکلام';

  @override
  String get createListingPublishing => 'بڵاوکردنەوە…';

  @override
  String get createListingPublished => 'ڕیکلامەکەت بڵاوکرایەوە.';

  @override
  String createListingPublishFailed(String reason) {
    return 'بڵاوکردنەوە سەرکەوتوو نەبوو: $reason';
  }

  @override
  String get createListingDiscard => 'ڕەشنووس فڕێبدە';

  @override
  String get createListingMissingTitle => 'ناونیشان بە هەر چوار زمان پێویستە.';

  @override
  String get createListingMissingDescription =>
      'وەسف بە هەر چوار زمان پێویستە.';

  @override
  String get createListingMissingCategory => 'پۆلێک هەڵبژێرە.';

  @override
  String get createListingMissingCondition => 'حاڵەتێک هەڵبژێرە.';

  @override
  String get createListingMissingStartingPrice =>
      'نرخی دەستپێک گەورەتر لە سفر دیاری بکە.';

  @override
  String get createListingMissingBuyNowPrice =>
      'نرخی کڕینی فۆری گەورەتر لە سفر دیاری بکە.';

  @override
  String get createListingBazaarCap => 'بازاڕی گروپی سنووری ١٠٬٠٠٠ دینارە.';

  @override
  String get listingTypeAuction => 'مەزاد';

  @override
  String get listingTypeFixed => 'ئێستا بکڕە';

  @override
  String get listingTypeBazaar => 'بازاڕی گروپی';

  @override
  String get listingDetailVerifiedVideo => 'ڤیدیۆی پشتڕاستکراو';

  @override
  String get listingDetailStartingAt => 'دەستپێک لە';

  @override
  String get listingDetailCurrentHigh => 'بەرزترین مەزایەدە';

  @override
  String get listingDetailBuyNow => 'ئێستا بکڕە';

  @override
  String get listingDetailBidUnavailable =>
      'مەزایەدە لە وەشانی داهاتوو دەکرێتەوە.';

  @override
  String get listingDetailSellerLabel => 'فرۆشیار';

  @override
  String listingDetailViews(int count) {
    return '$count بینین';
  }

  @override
  String get listingDetailDraftBadge => 'ڕەشنووس';

  @override
  String get listingDetailCancelledBadge => 'هەڵوەشێنراوەتەوە';

  @override
  String get listingDetailSoldBadge => 'فرۆشراوە';

  @override
  String get listingDetailExpiredBadge => 'تەواوبووە';

  @override
  String get listingDetailUnavailable => 'ئەم ڕیکلامە بەردەست نییە.';

  @override
  String biddingBidCount(int count) {
    return '$count مەزایەدە';
  }

  @override
  String get biddingCountdownDiscoveryLabel => 'دۆزینەوە کۆتایی دێت لە';

  @override
  String get biddingCountdownSmartCloseLabel =>
      'داخستنی زیرەک: ١٢ سەعات لە دوای دواین مەزایەدە کۆتایی دێت';

  @override
  String get biddingCountdownClosed => 'مەزاد داخراوە';

  @override
  String get biddingConsoleMinNext => 'کەمترین مەزایەدەی داهاتوو';

  @override
  String get biddingConsoleSetMax => 'زۆرترین بڕی مەزایەدە دیاری بکە';

  @override
  String get biddingConsoleSellerCantBid =>
      'ناتوانیت لە ڕیکلامی خۆت مەزایەدە بکەیت.';

  @override
  String get biddingConsoleTier1Required =>
      'ژمارەکەت پشتڕاست بکەرەوە بۆ مەزایەدەکردن.';

  @override
  String get biddingMaxSheetTitle => 'زۆرترین بڕی مەزایەدەکەت دیاری بکە';

  @override
  String get biddingMaxSheetSubtitle =>
      'بە خۆکار لە جێگەی تۆ مەزایەدە دەکەین تا ئەم بڕە، یەک بەرز بەرز.';

  @override
  String get biddingMaxSheetLabel => 'زۆرترین مەزایەدە (IQD)';

  @override
  String get biddingMaxSheetConfirm => 'پشتڕاستکردنەوە';

  @override
  String get biddingPlaced => 'مەزایەدەکە تۆمارکرا.';

  @override
  String get biddingErrorSelfBid => 'ناتوانیت لە ڕیکلامی خۆت مەزایەدە بکەیت.';

  @override
  String get biddingErrorTooLow =>
      'مەزایەدەکە لە کەمترین بڕ کەمترە. ئەم بڕە پێشنیارکراوە تاقی بکەرەوە.';

  @override
  String get biddingErrorRateLimited =>
      'هێواش بکە — مەزایەدە زۆرت کرد لە دەقیقەی ڕابردوودا.';

  @override
  String get biddingErrorClosed => 'ئەم مەزادە تازە داخرا.';

  @override
  String get biddingErrorTier1 => 'ژمارەکەت پشتڕاست بکەرەوە بۆ مەزایەدەکردن.';

  @override
  String get biddingErrorTierCeiling =>
      'ئەم بڕە لە سنووری ئاستی تۆ تێپەڕیوە. KYC بەرز بکەرەوە.';

  @override
  String get biddingErrorSellerUnreviewed =>
      'ئەم فرۆشیارە لە چاوەڕێی پشتڕاستکردنەوەی بەڕێوەبەرە.';

  @override
  String get biddingErrorNotActive => 'ئەم ڕیکلامە کراوە نییە بۆ مەزایەدە.';

  @override
  String get biddingErrorGeneric =>
      'نەمانتوانی مەزایەدەکە تۆمار بکەین. دووبارە هەوڵبدە.';

  @override
  String get biddingFeedTitle => 'مەزایەدە زیندووەکان';

  @override
  String get biddingFeedEmpty => 'یەکەم کەس بە بۆ مەزایەدەکردن.';

  @override
  String get biddingFeedJustNow => 'ئێستا';

  @override
  String biddingFeedMinutesAgo(int m) {
    return '$m د پێش';
  }

  @override
  String biddingFeedHoursAgo(int h) {
    return '$h ک پێش';
  }

  @override
  String get browseTitle => 'بگەڕێ';

  @override
  String get browseSearchHint => 'گەڕان لە ڕیکلامەکان';

  @override
  String get browseEmpty => 'هیچ ڕیکلامێک هاوتا نییە.';

  @override
  String get browseFilterAll => 'هەموو';

  @override
  String get browseFilterAuction => 'مەزادەکان';

  @override
  String get browseFilterFixed => 'ئێستا بکڕە';

  @override
  String get browseFilterBazaar => 'بازاڕ';

  @override
  String get browseResultsTitle => 'ئەنجامەکان';

  @override
  String get homeSectionEndingSoon => 'بەم زووانە کۆتایی دێت';

  @override
  String get homeSectionHot => 'گەرم';

  @override
  String get homeSectionBazaar => 'بازاڕی گروپی';

  @override
  String get homeSectionCategories => 'پۆلەکان';

  @override
  String get homeSeeAll => 'هەمووی ببینە';

  @override
  String get homeFabSell => 'بفرۆشە';
}
