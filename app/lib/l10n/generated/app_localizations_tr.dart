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
  String get homeSignIn => 'Teklif vermeye başlamak için giriş yapın';

  @override
  String get homeOpenDashboard => 'Mazad\'ım\'ı aç';

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

  @override
  String get authPhoneTitle => 'Giriş yap';

  @override
  String get authPhoneSubtitle =>
      'Irak cep telefonu numaranızı girin. SMS ile tek seferlik bir kod göndereceğiz.';

  @override
  String get authPhoneLabel => 'Cep telefonu numarası';

  @override
  String get authPhoneHint => '+964 7XX XXX XXXX';

  @override
  String get authPhoneSend => 'Kod gönder';

  @override
  String get authPhoneInvalid =>
      'Geçerli bir Irak cep telefonu numarası girin.';

  @override
  String get authOtpTitle => 'Kodu girin';

  @override
  String authOtpSubtitle(String phone) {
    return '$phone numarasına 6 haneli bir kod gönderdik.';
  }

  @override
  String get authOtpLabel => '6 haneli kod';

  @override
  String get authOtpVerify => 'Doğrula';

  @override
  String get authOtpResend => 'Kodu yeniden gönder';

  @override
  String get authOtpInvalid => 'Kod eşleşmedi. Tekrar deneyin.';

  @override
  String get authOtpExpired => 'Kodun süresi doldu. Yeni bir tane isteyin.';

  @override
  String get authOtpRateLimited =>
      'Çok fazla deneme. Daha sonra tekrar deneyin.';

  @override
  String get authSignOut => 'Çıkış yap';

  @override
  String get profileSetupTitle => 'Profilinizi oluşturun';

  @override
  String get profileSetupSubtitle =>
      'Bunları istediğiniz zaman ayarlardan değiştirebilirsiniz.';

  @override
  String get profileDisplayNameLabel => 'Görünen ad';

  @override
  String get profileDisplayNameHint => 'Alıcı ve satıcılar sizi nasıl görüyor';

  @override
  String get profileLocaleLabel => 'Dil';

  @override
  String get profileCityLabel => 'Şehir';

  @override
  String get profileCityHint => 'örn. Bağdat, Erbil, Basra';

  @override
  String get profileSave => 'Kaydet';

  @override
  String get profileSaved => 'Profil kaydedildi.';

  @override
  String tier1Granted(String limit) {
    return 'Doğrulandınız — $limit tutarına kadar teklif verebilir ve satın alabilirsiniz.';
  }

  @override
  String get tier2Granted =>
      'Satıcı olarak doğrulandınız — artık ürün listeleyebilirsiniz.';

  @override
  String get tierBadge0 => 'Ziyaretçi';

  @override
  String get tierBadge1 => 'Doğrulanmış alıcı';

  @override
  String get tierBadge2 => 'Doğrulanmış satıcı';

  @override
  String get kycIntroTitle => 'Mazad\'da satışa başlayın';

  @override
  String get kycIntroSubtitle =>
      'Ürün listelemek için kimliğinizi doğrulayın. Yaklaşık üç dakika sürer.';

  @override
  String get kycIntroStep1 => 'Kimliğinizi fotoğraflayın';

  @override
  String get kycIntroStep2 => 'Adresinizi ekleyin';

  @override
  String get kycIntroStep3 => 'Ödemeyi nasıl alacağınızı seçin';

  @override
  String get kycIntroBegin => 'Doğrulamaya başla';

  @override
  String get kycIntroCancel => 'Şimdi değil';

  @override
  String get kycIdTitle => 'Kimliğinizi fotoğraflayın';

  @override
  String get kycIdSubtitle =>
      'Irak ulusal kimliği, pasaport veya ikamet kartı. Dört köşenin de göründüğünden emin olun.';

  @override
  String get kycIdPickFromCamera => 'Kamerayı kullan';

  @override
  String get kycIdPickFromGallery => 'Fotoğraflardan seç';

  @override
  String get kycIdReplace => 'Fotoğrafı değiştir';

  @override
  String get kycIdContinue => 'Devam et';

  @override
  String get kycIdMissing => 'Lütfen kimliğinizin bir fotoğrafını ekleyin.';

  @override
  String get kycIdUploading => 'Yükleniyor…';

  @override
  String get kycIdUploadFailed =>
      'Yükleme başarısız oldu. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get kycAddressTitle => 'Nerede yaşıyorsunuz?';

  @override
  String get kycAddressSubtitle =>
      'Bunu yerel alıcılarla eşleşmeniz ve teslimat ayarlamak için kullanırız.';

  @override
  String get kycAddressLine1Label => 'Cadde ve bina';

  @override
  String get kycAddressLine2Label => 'Daire, kat (isteğe bağlı)';

  @override
  String get kycAddressCityLabel => 'Şehir';

  @override
  String get kycAddressGovernorateLabel => 'İl';

  @override
  String get kycAddressContinue => 'Devam et';

  @override
  String get kycAddressMissing => 'Cadde ve şehir gereklidir.';

  @override
  String get kycPayoutTitle => 'Ödemeyi nasıl almak istersiniz?';

  @override
  String get kycPayoutSubtitle =>
      'Alıcı ödemelerini emanette tutar ve teslimat sonrası size aktarırız.';

  @override
  String get kycPayoutZainCash => 'ZainCash cüzdanı';

  @override
  String get kycPayoutFastPay => 'FastPay cüzdanı';

  @override
  String get kycPayoutBank => 'Banka havalesi';

  @override
  String get kycPayoutCod => 'Yalnızca kapıda ödeme';

  @override
  String get kycPayoutAccountLabel => 'Cüzdan numarası veya hesap';

  @override
  String get kycPayoutAccountHint =>
      'Seçtiğiniz yöntemle ilişkili numarayı girin';

  @override
  String get kycPayoutContinue => 'Devam et';

  @override
  String get kycReviewTitle => 'Gözden geçir ve gönder';

  @override
  String get kycReviewBusinessNameLabel => 'İşletme veya satıcı adı';

  @override
  String get kycReviewBusinessNameHint => 'İlanlarınızda alıcılara gösterilir';

  @override
  String get kycReviewSubmit => 'Doğrulamayı gönder';

  @override
  String get kycReviewSubmitting => 'Gönderiliyor…';

  @override
  String get kycReviewSubmitted =>
      'Doğrulama gönderildi. Artık ürün listeleyebilirsiniz.';

  @override
  String get kycReviewSubmitFailed =>
      'Doğrulamanızı gönderemedik. Lütfen tekrar deneyin.';

  @override
  String get dashboardTitle => 'Mazad\'ım';

  @override
  String get dashboardTabBids => 'Teklifler';

  @override
  String get dashboardTabWatchlist => 'Takip listesi';

  @override
  String get dashboardTabWins => 'Kazandıklarım';

  @override
  String get dashboardTabListings => 'İlanlarım';

  @override
  String get dashboardTabOrders => 'Siparişler';

  @override
  String get dashboardTabWallet => 'Cüzdan';

  @override
  String get dashboardTabRatings => 'Değerlendirmeler';

  @override
  String get dashboardEmptyBids =>
      'Henüz aktif teklif yok. Başlamak için ilanlara göz atın.';

  @override
  String get dashboardEmptyWatchlist =>
      'Takip listenizde bir şey yok. Bir ilanı kaydetmek için kalbe dokunun.';

  @override
  String get dashboardEmptyWins =>
      'Henüz kazanılmış öğe yok. Yarışmak için ilk teklifinizi verin.';

  @override
  String get dashboardEmptyListings => 'Henüz hiçbir ilan eklemediniz.';

  @override
  String get dashboardStartSelling => 'Satışa başla';

  @override
  String get dashboardEmptyOrders => 'Henüz sipariş yok.';

  @override
  String get dashboardEmptyWallet => 'Cüzdan hareketleriniz burada görünecek.';

  @override
  String get dashboardEmptyRatings =>
      'Değerlendirmeler ilk tamamlanan siparişten sonra burada görünecek.';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonContinue => 'Devam et';

  @override
  String get commonRequired => 'Gerekli';

  @override
  String get commonGenericError => 'Bir hata oluştu. Lütfen tekrar deneyin.';
}
