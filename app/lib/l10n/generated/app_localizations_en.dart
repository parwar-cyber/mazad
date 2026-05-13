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
  String get homeSignIn => 'Sign in to start bidding';

  @override
  String get homeOpenDashboard => 'Open My Mazad';

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

  @override
  String get authPhoneTitle => 'Sign in';

  @override
  String get authPhoneSubtitle =>
      'Enter your Iraqi mobile number. We\'ll send a one-time code by SMS.';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneHint => '+964 7XX XXX XXXX';

  @override
  String get authPhoneSend => 'Send code';

  @override
  String get authPhoneInvalid => 'Enter a valid Iraqi mobile number.';

  @override
  String get authOtpTitle => 'Enter the code';

  @override
  String authOtpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get authOtpLabel => '6-digit code';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String get authOtpInvalid => 'That code didn\'t match. Try again.';

  @override
  String get authOtpExpired => 'Code expired. Request a new one.';

  @override
  String get authOtpRateLimited => 'Too many attempts. Try again later.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileSetupSubtitle =>
      'You can change these any time in settings.';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileDisplayNameHint => 'How buyers and sellers see you';

  @override
  String get profileLocaleLabel => 'Language';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileCityHint => 'e.g. Baghdad, Erbil, Basra';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String tier1Granted(String limit) {
    return 'You\'re verified — bid and buy up to $limit.';
  }

  @override
  String get tier2Granted => 'Seller verified — you can list items now.';

  @override
  String get tierBadge0 => 'Browser';

  @override
  String get tierBadge1 => 'Verified buyer';

  @override
  String get tierBadge2 => 'Verified seller';

  @override
  String get kycIntroTitle => 'Start selling on Mazad';

  @override
  String get kycIntroSubtitle =>
      'Verify your identity to list items. Takes about three minutes.';

  @override
  String get kycIntroStep1 => 'Photograph your ID';

  @override
  String get kycIntroStep2 => 'Add your address';

  @override
  String get kycIntroStep3 => 'Choose how you\'ll get paid';

  @override
  String get kycIntroBegin => 'Begin verification';

  @override
  String get kycIntroCancel => 'Not now';

  @override
  String get kycIdTitle => 'Photograph your ID';

  @override
  String get kycIdSubtitle =>
      'Iraqi national ID, passport, or residence card. Make sure all four corners are visible.';

  @override
  String get kycIdPickFromCamera => 'Use camera';

  @override
  String get kycIdPickFromGallery => 'Choose from photos';

  @override
  String get kycIdReplace => 'Replace photo';

  @override
  String get kycIdContinue => 'Continue';

  @override
  String get kycIdMissing => 'Please add a photo of your ID.';

  @override
  String get kycIdUploading => 'Uploading…';

  @override
  String get kycIdUploadFailed =>
      'Upload failed. Check your connection and try again.';

  @override
  String get kycAddressTitle => 'Where are you based?';

  @override
  String get kycAddressSubtitle =>
      'We use this to match you with local buyers and arrange delivery.';

  @override
  String get kycAddressLine1Label => 'Street and building';

  @override
  String get kycAddressLine2Label => 'Apartment, suite (optional)';

  @override
  String get kycAddressCityLabel => 'City';

  @override
  String get kycAddressGovernorateLabel => 'Governorate';

  @override
  String get kycAddressContinue => 'Continue';

  @override
  String get kycAddressMissing => 'Street and city are required.';

  @override
  String get kycPayoutTitle => 'How would you like to get paid?';

  @override
  String get kycPayoutSubtitle =>
      'We hold buyer payments in escrow and release them to you after delivery.';

  @override
  String get kycPayoutZainCash => 'ZainCash wallet';

  @override
  String get kycPayoutFastPay => 'FastPay wallet';

  @override
  String get kycPayoutBank => 'Bank transfer';

  @override
  String get kycPayoutCod => 'Cash on delivery only';

  @override
  String get kycPayoutAccountLabel => 'Wallet number or account';

  @override
  String get kycPayoutAccountHint =>
      'Enter the number associated with the chosen method';

  @override
  String get kycPayoutContinue => 'Continue';

  @override
  String get kycReviewTitle => 'Review and submit';

  @override
  String get kycReviewBusinessNameLabel => 'Business or seller name';

  @override
  String get kycReviewBusinessNameHint => 'Shown to buyers on your listings';

  @override
  String get kycReviewSubmit => 'Submit verification';

  @override
  String get kycReviewSubmitting => 'Submitting…';

  @override
  String get kycReviewSubmitted =>
      'Verification submitted. You can list items now.';

  @override
  String get kycReviewSubmitFailed =>
      'We couldn\'t submit your verification. Please try again.';

  @override
  String get dashboardTitle => 'My Mazad';

  @override
  String get dashboardTabBids => 'Bids';

  @override
  String get dashboardTabWatchlist => 'Watchlist';

  @override
  String get dashboardTabWins => 'Wins';

  @override
  String get dashboardTabListings => 'Listings';

  @override
  String get dashboardTabOrders => 'Orders';

  @override
  String get dashboardTabWallet => 'Wallet';

  @override
  String get dashboardTabRatings => 'Ratings';

  @override
  String get dashboardEmptyBids =>
      'No active bids yet. Browse listings to get started.';

  @override
  String get dashboardEmptyWatchlist =>
      'Nothing on your watchlist. Tap the heart on any listing to save it.';

  @override
  String get dashboardEmptyWins =>
      'No wins yet. Place your first bid to compete.';

  @override
  String get dashboardEmptyListings => 'You haven\'t listed anything yet.';

  @override
  String get dashboardStartSelling => 'Start selling';

  @override
  String get dashboardEmptyOrders => 'No orders yet.';

  @override
  String get dashboardEmptyWallet => 'Your wallet activity will appear here.';

  @override
  String get dashboardEmptyRatings =>
      'Ratings will appear here after your first completed order.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';
}
