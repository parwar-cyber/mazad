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

  @override
  String get createListingTitle => 'Ürün listele';

  @override
  String get createListingChooseType => 'Ne satıyorsunuz?';

  @override
  String get createListingTypeAuction => 'Açık artırma';

  @override
  String get createListingTypeAuctionDesc =>
      'Başlangıç fiyatı belirleyin, alıcılar teklif versin.';

  @override
  String get createListingTypeFixed => 'Hemen al';

  @override
  String get createListingTypeFixedDesc => 'Tek fiyat. İlk alıcı kazanır.';

  @override
  String get createListingTypeBazaar => 'Grup pazarı';

  @override
  String get createListingTypeBazaarDesc =>
      '10.000 IQD altında. Daha çok alıcı katıldıkça fiyat düşer.';

  @override
  String get createListingAuctionLocked =>
      'Açık artırma için Seviye 2 doğrulama gerekir.';

  @override
  String get createListingTier1Locked =>
      'Listelemeden önce telefonunuzu doğrulayın.';

  @override
  String get createListingPhotosTitle => 'Fotoğraf ekle';

  @override
  String get createListingPhotosSubtitle =>
      'Üç ile beş net fotoğraf. Bunları kullanarak ilanı dört dilde hazırlarız.';

  @override
  String get createListingPhotoFromCamera => 'Kamera';

  @override
  String get createListingPhotoFromGallery => 'Galeri';

  @override
  String get createListingPhotoMinError => 'En az üç fotoğraf ekleyin.';

  @override
  String get createListingPhotosUploading => 'Yükleniyor…';

  @override
  String get createListingPhotosFailed =>
      'Bazı fotoğraflar yüklenemedi. Tekrar deneyin.';

  @override
  String get createListingPhotosContinue => 'Devam et';

  @override
  String createListingPhotosCount(int count) {
    return '$count / 10';
  }

  @override
  String get createListingAiTitle => 'Yapay zekâ asistanı';

  @override
  String get createListingAiSubtitle =>
      'Fotoğraflarınızı okuyup dört dilli bir ilan taslağı oluştururuz. Sonra düzenleyebilirsiniz.';

  @override
  String get createListingAiRun => 'Taslak oluştur';

  @override
  String get createListingAiRunning => 'Fotoğraflarınız okunuyor…';

  @override
  String get createListingAiFailed =>
      'Taslak oluşturamadık. Alanları elle doldurun.';

  @override
  String get createListingAiRedFlagsTitle => 'Dikkat';

  @override
  String get createListingAiSkip => 'Elle doldur';

  @override
  String get createListingAiContinue => 'İncelemeye geç';

  @override
  String get createListingReviewTitle => 'İncele ve yayınla';

  @override
  String get createListingReviewSubtitle =>
      'Alıcılar tam olarak burada gördüğünüzü görür. Yanlış olan her şeyi düzenleyin.';

  @override
  String get createListingFieldTitle => 'Başlık';

  @override
  String get createListingFieldDescription => 'Açıklama';

  @override
  String get createListingFieldCategory => 'Kategori';

  @override
  String get createListingFieldCondition => 'Durum';

  @override
  String get createListingFieldStartingPrice => 'Başlangıç fiyatı (IQD)';

  @override
  String get createListingFieldBuyNowPrice => 'Hemen al fiyatı (IQD)';

  @override
  String get createListingFieldReservePrice =>
      'Rezerv fiyatı (isteğe bağlı, IQD)';

  @override
  String get createListingLocaleEn => 'EN';

  @override
  String get createListingLocaleAr => 'AR';

  @override
  String get createListingLocaleKu => 'KU';

  @override
  String get createListingLocaleTr => 'TR';

  @override
  String get createListingConditionNew => 'Sıfır';

  @override
  String get createListingConditionLikeNew => 'Sıfır gibi';

  @override
  String get createListingConditionGood => 'İyi';

  @override
  String get createListingConditionFair => 'Orta';

  @override
  String get createListingConditionForParts => 'Parçası için';

  @override
  String get createListingPublish => 'İlanı yayınla';

  @override
  String get createListingPublishing => 'Yayınlanıyor…';

  @override
  String get createListingPublished => 'İlanınız yayında.';

  @override
  String createListingPublishFailed(String reason) {
    return 'Yayınlama başarısız: $reason';
  }

  @override
  String get createListingDiscard => 'Taslağı sil';

  @override
  String get createListingMissingTitle => 'Başlık dört dilde de gerekli.';

  @override
  String get createListingMissingDescription =>
      'Açıklama dört dilde de gerekli.';

  @override
  String get createListingMissingCategory => 'Bir kategori seçin.';

  @override
  String get createListingMissingCondition => 'Bir durum seçin.';

  @override
  String get createListingMissingStartingPrice =>
      'Sıfırdan büyük bir başlangıç fiyatı belirleyin.';

  @override
  String get createListingMissingBuyNowPrice =>
      'Sıfırdan büyük bir hemen al fiyatı belirleyin.';

  @override
  String get createListingBazaarCap =>
      'Grup pazarı ilanları en fazla 10.000 IQD olur.';

  @override
  String get listingTypeAuction => 'Açık artırma';

  @override
  String get listingTypeFixed => 'Hemen al';

  @override
  String get listingTypeBazaar => 'Grup pazarı';

  @override
  String get listingDetailVerifiedVideo => 'Doğrulanmış video';

  @override
  String get listingDetailStartingAt => 'Başlangıç';

  @override
  String get listingDetailCurrentHigh => 'En yüksek teklif';

  @override
  String get listingDetailBuyNow => 'Hemen al';

  @override
  String get listingDetailBidUnavailable =>
      'Teklif verme bir sonraki sürümde açılır.';

  @override
  String get listingDetailSellerLabel => 'Satıcı';

  @override
  String listingDetailViews(int count) {
    return '$count görüntüleme';
  }

  @override
  String get listingDetailDraftBadge => 'Taslak';

  @override
  String get listingDetailCancelledBadge => 'İptal edildi';

  @override
  String get listingDetailUnavailable => 'Bu ilan kullanılamıyor.';

  @override
  String get browseTitle => 'Keşfet';

  @override
  String get browseSearchHint => 'İlanlarda ara';

  @override
  String get browseEmpty => 'Eşleşen ilan yok.';

  @override
  String get browseFilterAll => 'Tümü';

  @override
  String get browseFilterAuction => 'Açık artırmalar';

  @override
  String get browseFilterFixed => 'Hemen al';

  @override
  String get browseFilterBazaar => 'Pazar';

  @override
  String get browseResultsTitle => 'Sonuçlar';

  @override
  String get homeSectionEndingSoon => 'Yakında bitiyor';

  @override
  String get homeSectionHot => 'Popüler';

  @override
  String get homeSectionBazaar => 'Grup pazarı';

  @override
  String get homeSectionCategories => 'Kategoriler';

  @override
  String get homeSeeAll => 'Tümünü gör';

  @override
  String get homeFabSell => 'Sat';
}
