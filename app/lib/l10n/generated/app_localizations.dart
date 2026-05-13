import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ku'),
    Locale('tr')
  ];

  /// App display name
  ///
  /// In en, this message translates to:
  /// **'Mazad'**
  String get appTitle;

  /// Greeting on the home screen placeholder
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mazad'**
  String get homeWelcome;

  /// Sub-headline under the welcome message
  ///
  /// In en, this message translates to:
  /// **'Iraq\'s most trusted auction marketplace.'**
  String get homeTagline;

  /// CTA on the home screen for unauthenticated visitors
  ///
  /// In en, this message translates to:
  /// **'Sign in to start bidding'**
  String get homeSignIn;

  /// CTA on the home screen for signed-in users
  ///
  /// In en, this message translates to:
  /// **'Open My Mazad'**
  String get homeOpenDashboard;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get switchLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageKurdish.
  ///
  /// In en, this message translates to:
  /// **'کوردی'**
  String get languageKurdish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of Mazad is no longer supported. Please update to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Phone-OTP signup screen title
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your Iraqi mobile number. We\'ll send a one-time code by SMS.'**
  String get authPhoneSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+964 7XX XXX XXXX'**
  String get authPhoneHint;

  /// No description provided for @authPhoneSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authPhoneSend;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Iraqi mobile number.'**
  String get authPhoneInvalid;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get authOtpTitle;

  /// OTP verify subtitle
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String authOtpSubtitle(String phone);

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get authOtpLabel;

  /// No description provided for @authOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t match. Try again.'**
  String get authOtpInvalid;

  /// No description provided for @authOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Request a new one.'**
  String get authOtpExpired;

  /// No description provided for @authOtpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authOtpRateLimited;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these any time in settings.'**
  String get profileSetupSubtitle;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How buyers and sellers see you'**
  String get profileDisplayNameHint;

  /// No description provided for @profileLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLocaleLabel;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Baghdad, Erbil, Basra'**
  String get profileCityHint;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// Tier 1 confirmation banner
  ///
  /// In en, this message translates to:
  /// **'You\'re verified — bid and buy up to {limit}.'**
  String tier1Granted(String limit);

  /// No description provided for @tier2Granted.
  ///
  /// In en, this message translates to:
  /// **'Seller verified — you can list items now.'**
  String get tier2Granted;

  /// No description provided for @tierBadge0.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get tierBadge0;

  /// No description provided for @tierBadge1.
  ///
  /// In en, this message translates to:
  /// **'Verified buyer'**
  String get tierBadge1;

  /// No description provided for @tierBadge2.
  ///
  /// In en, this message translates to:
  /// **'Verified seller'**
  String get tierBadge2;

  /// No description provided for @kycIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Start selling on Mazad'**
  String get kycIntroTitle;

  /// No description provided for @kycIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to list items. Takes about three minutes.'**
  String get kycIntroSubtitle;

  /// No description provided for @kycIntroStep1.
  ///
  /// In en, this message translates to:
  /// **'Photograph your ID'**
  String get kycIntroStep1;

  /// No description provided for @kycIntroStep2.
  ///
  /// In en, this message translates to:
  /// **'Add your address'**
  String get kycIntroStep2;

  /// No description provided for @kycIntroStep3.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'ll get paid'**
  String get kycIntroStep3;

  /// No description provided for @kycIntroBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin verification'**
  String get kycIntroBegin;

  /// No description provided for @kycIntroCancel.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get kycIntroCancel;

  /// No description provided for @kycIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph your ID'**
  String get kycIdTitle;

  /// No description provided for @kycIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Iraqi national ID, passport, or residence card. Make sure all four corners are visible.'**
  String get kycIdSubtitle;

  /// No description provided for @kycIdPickFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get kycIdPickFromCamera;

  /// No description provided for @kycIdPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get kycIdPickFromGallery;

  /// No description provided for @kycIdReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get kycIdReplace;

  /// No description provided for @kycIdContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get kycIdContinue;

  /// No description provided for @kycIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Please add a photo of your ID.'**
  String get kycIdMissing;

  /// No description provided for @kycIdUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get kycIdUploading;

  /// No description provided for @kycIdUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get kycIdUploadFailed;

  /// No description provided for @kycAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you based?'**
  String get kycAddressTitle;

  /// No description provided for @kycAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use this to match you with local buyers and arrange delivery.'**
  String get kycAddressSubtitle;

  /// No description provided for @kycAddressLine1Label.
  ///
  /// In en, this message translates to:
  /// **'Street and building'**
  String get kycAddressLine1Label;

  /// No description provided for @kycAddressLine2Label.
  ///
  /// In en, this message translates to:
  /// **'Apartment, suite (optional)'**
  String get kycAddressLine2Label;

  /// No description provided for @kycAddressCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get kycAddressCityLabel;

  /// No description provided for @kycAddressGovernorateLabel.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get kycAddressGovernorateLabel;

  /// No description provided for @kycAddressContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get kycAddressContinue;

  /// No description provided for @kycAddressMissing.
  ///
  /// In en, this message translates to:
  /// **'Street and city are required.'**
  String get kycAddressMissing;

  /// No description provided for @kycPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to get paid?'**
  String get kycPayoutTitle;

  /// No description provided for @kycPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We hold buyer payments in escrow and release them to you after delivery.'**
  String get kycPayoutSubtitle;

  /// No description provided for @kycPayoutZainCash.
  ///
  /// In en, this message translates to:
  /// **'ZainCash wallet'**
  String get kycPayoutZainCash;

  /// No description provided for @kycPayoutFastPay.
  ///
  /// In en, this message translates to:
  /// **'FastPay wallet'**
  String get kycPayoutFastPay;

  /// No description provided for @kycPayoutBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get kycPayoutBank;

  /// No description provided for @kycPayoutCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery only'**
  String get kycPayoutCod;

  /// No description provided for @kycPayoutAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet number or account'**
  String get kycPayoutAccountLabel;

  /// No description provided for @kycPayoutAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the number associated with the chosen method'**
  String get kycPayoutAccountHint;

  /// No description provided for @kycPayoutContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get kycPayoutContinue;

  /// No description provided for @kycReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get kycReviewTitle;

  /// No description provided for @kycReviewBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business or seller name'**
  String get kycReviewBusinessNameLabel;

  /// No description provided for @kycReviewBusinessNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to buyers on your listings'**
  String get kycReviewBusinessNameHint;

  /// No description provided for @kycReviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit verification'**
  String get kycReviewSubmit;

  /// No description provided for @kycReviewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get kycReviewSubmitting;

  /// No description provided for @kycReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Verification submitted. You can list items now.'**
  String get kycReviewSubmitted;

  /// No description provided for @kycReviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your verification. Please try again.'**
  String get kycReviewSubmitFailed;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Mazad'**
  String get dashboardTitle;

  /// No description provided for @dashboardTabBids.
  ///
  /// In en, this message translates to:
  /// **'Bids'**
  String get dashboardTabBids;

  /// No description provided for @dashboardTabWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get dashboardTabWatchlist;

  /// No description provided for @dashboardTabWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get dashboardTabWins;

  /// No description provided for @dashboardTabListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get dashboardTabListings;

  /// No description provided for @dashboardTabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get dashboardTabOrders;

  /// No description provided for @dashboardTabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get dashboardTabWallet;

  /// No description provided for @dashboardTabRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get dashboardTabRatings;

  /// No description provided for @dashboardEmptyBids.
  ///
  /// In en, this message translates to:
  /// **'No active bids yet. Browse listings to get started.'**
  String get dashboardEmptyBids;

  /// No description provided for @dashboardEmptyWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Nothing on your watchlist. Tap the heart on any listing to save it.'**
  String get dashboardEmptyWatchlist;

  /// No description provided for @dashboardEmptyWins.
  ///
  /// In en, this message translates to:
  /// **'No wins yet. Place your first bid to compete.'**
  String get dashboardEmptyWins;

  /// No description provided for @dashboardEmptyListings.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t listed anything yet.'**
  String get dashboardEmptyListings;

  /// No description provided for @dashboardStartSelling.
  ///
  /// In en, this message translates to:
  /// **'Start selling'**
  String get dashboardStartSelling;

  /// No description provided for @dashboardEmptyOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get dashboardEmptyOrders;

  /// No description provided for @dashboardEmptyWallet.
  ///
  /// In en, this message translates to:
  /// **'Your wallet activity will appear here.'**
  String get dashboardEmptyWallet;

  /// No description provided for @dashboardEmptyRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings will appear here after your first completed order.'**
  String get dashboardEmptyRatings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonGenericError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ku', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ku':
      return AppLocalizationsKu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
