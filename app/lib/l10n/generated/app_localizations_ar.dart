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
  String get homeSignIn => 'سجّل الدخول للبدء بالمزايدة';

  @override
  String get homeOpenDashboard => 'افتح حسابي';

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

  @override
  String get authPhoneTitle => 'تسجيل الدخول';

  @override
  String get authPhoneSubtitle =>
      'أدخل رقم هاتفك العراقي. سنرسل رمزًا لمرة واحدة عبر رسالة نصية.';

  @override
  String get authPhoneLabel => 'رقم الهاتف';

  @override
  String get authPhoneHint => '+964 7XX XXX XXXX';

  @override
  String get authPhoneSend => 'إرسال الرمز';

  @override
  String get authPhoneInvalid => 'أدخل رقم هاتف عراقي صحيح.';

  @override
  String get authOtpTitle => 'أدخل الرمز';

  @override
  String authOtpSubtitle(String phone) {
    return 'أرسلنا رمزًا مكونًا من 6 أرقام إلى $phone.';
  }

  @override
  String get authOtpLabel => 'الرمز المكوّن من 6 أرقام';

  @override
  String get authOtpVerify => 'تحقّق';

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String get authOtpInvalid => 'الرمز غير صحيح. حاول مرة أخرى.';

  @override
  String get authOtpExpired => 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.';

  @override
  String get authOtpRateLimited => 'محاولات كثيرة. حاول لاحقًا.';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get profileSetupTitle => 'إعداد الملف الشخصي';

  @override
  String get profileSetupSubtitle => 'يمكنك تغيير ذلك في الإعدادات في أي وقت.';

  @override
  String get profileDisplayNameLabel => 'الاسم المعروض';

  @override
  String get profileDisplayNameHint => 'كيف يراك المشترون والبائعون';

  @override
  String get profileLocaleLabel => 'اللغة';

  @override
  String get profileCityLabel => 'المدينة';

  @override
  String get profileCityHint => 'مثلاً: بغداد، أربيل، البصرة';

  @override
  String get profileSave => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي.';

  @override
  String tier1Granted(String limit) {
    return 'تم التحقّق منك — يمكنك المزايدة والشراء حتى $limit.';
  }

  @override
  String get tier2Granted => 'تم التحقّق منك كبائع — يمكنك إدراج منتجاتك الآن.';

  @override
  String get tierBadge0 => 'زائر';

  @override
  String get tierBadge1 => 'مشترٍ موثّق';

  @override
  String get tierBadge2 => 'بائع موثّق';

  @override
  String get kycIntroTitle => 'ابدأ البيع على مزاد';

  @override
  String get kycIntroSubtitle =>
      'تحقّق من هويتك لإدراج منتجاتك. يستغرق الأمر حوالي ثلاث دقائق.';

  @override
  String get kycIntroStep1 => 'صوّر هويتك';

  @override
  String get kycIntroStep2 => 'أضف عنوانك';

  @override
  String get kycIntroStep3 => 'اختر طريقة استلام الأموال';

  @override
  String get kycIntroBegin => 'ابدأ التحقّق';

  @override
  String get kycIntroCancel => 'ليس الآن';

  @override
  String get kycIdTitle => 'صوّر هويتك';

  @override
  String get kycIdSubtitle =>
      'هوية وطنية عراقية أو جواز سفر أو بطاقة إقامة. تأكّد من ظهور الزوايا الأربع.';

  @override
  String get kycIdPickFromCamera => 'استخدم الكاميرا';

  @override
  String get kycIdPickFromGallery => 'اختر من الصور';

  @override
  String get kycIdReplace => 'استبدال الصورة';

  @override
  String get kycIdContinue => 'متابعة';

  @override
  String get kycIdMissing => 'يُرجى إضافة صورة لهويتك.';

  @override
  String get kycIdUploading => 'جارٍ الرفع…';

  @override
  String get kycIdUploadFailed => 'فشل الرفع. تحقّق من الاتصال وحاول مرة أخرى.';

  @override
  String get kycAddressTitle => 'أين تقيم؟';

  @override
  String get kycAddressSubtitle =>
      'نستخدم العنوان لربطك بالمشترين المحليين وترتيب التوصيل.';

  @override
  String get kycAddressLine1Label => 'الشارع والمبنى';

  @override
  String get kycAddressLine2Label => 'شقة، طابق (اختياري)';

  @override
  String get kycAddressCityLabel => 'المدينة';

  @override
  String get kycAddressGovernorateLabel => 'المحافظة';

  @override
  String get kycAddressContinue => 'متابعة';

  @override
  String get kycAddressMissing => 'الشارع والمدينة مطلوبان.';

  @override
  String get kycPayoutTitle => 'كيف تريد استلام أموالك؟';

  @override
  String get kycPayoutSubtitle =>
      'نحتفظ بأموال المشترين في الضمان ونحوّلها إليك بعد التوصيل.';

  @override
  String get kycPayoutZainCash => 'محفظة زين كاش';

  @override
  String get kycPayoutFastPay => 'محفظة فاست باي';

  @override
  String get kycPayoutBank => 'تحويل مصرفي';

  @override
  String get kycPayoutCod => 'الدفع عند الاستلام فقط';

  @override
  String get kycPayoutAccountLabel => 'رقم المحفظة أو الحساب';

  @override
  String get kycPayoutAccountHint => 'أدخل الرقم المرتبط بالطريقة المختارة';

  @override
  String get kycPayoutContinue => 'متابعة';

  @override
  String get kycReviewTitle => 'المراجعة والإرسال';

  @override
  String get kycReviewBusinessNameLabel => 'اسم النشاط أو البائع';

  @override
  String get kycReviewBusinessNameHint => 'يظهر للمشترين على إعلاناتك';

  @override
  String get kycReviewSubmit => 'إرسال التحقّق';

  @override
  String get kycReviewSubmitting => 'جارٍ الإرسال…';

  @override
  String get kycReviewSubmitted =>
      'تم إرسال التحقّق. يمكنك إدراج المنتجات الآن.';

  @override
  String get kycReviewSubmitFailed => 'تعذّر إرسال التحقّق. حاول مرة أخرى.';

  @override
  String get dashboardTitle => 'حسابي في مزاد';

  @override
  String get dashboardTabBids => 'المزايدات';

  @override
  String get dashboardTabWatchlist => 'المفضّلة';

  @override
  String get dashboardTabWins => 'الفائزة';

  @override
  String get dashboardTabListings => 'إعلاناتي';

  @override
  String get dashboardTabOrders => 'الطلبات';

  @override
  String get dashboardTabWallet => 'المحفظة';

  @override
  String get dashboardTabRatings => 'التقييمات';

  @override
  String get dashboardEmptyBids =>
      'لا توجد مزايدات نشطة. تصفّح الإعلانات للبدء.';

  @override
  String get dashboardEmptyWatchlist =>
      'لا شيء في المفضّلة. اضغط على القلب على أي إعلان لحفظه.';

  @override
  String get dashboardEmptyWins => 'لا فوز بعد. ضع أول مزايدة للمنافسة.';

  @override
  String get dashboardEmptyListings => 'لم تُدرج أي إعلان بعد.';

  @override
  String get dashboardStartSelling => 'ابدأ البيع';

  @override
  String get dashboardEmptyOrders => 'لا توجد طلبات بعد.';

  @override
  String get dashboardEmptyWallet => 'ستظهر حركة محفظتك هنا.';

  @override
  String get dashboardEmptyRatings => 'ستظهر التقييمات هنا بعد أول طلب مكتمل.';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonRequired => 'مطلوب';

  @override
  String get commonGenericError => 'حدث خطأ. يُرجى المحاولة مرة أخرى.';
}
