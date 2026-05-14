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

  @override
  String get createListingTitle => "List an item";

  @override
  String get createListingChooseType => "What are you selling?";

  @override
  String get createListingTypeAuction => "Auction";

  @override
  String get createListingTypeAuctionDesc => "Set a starting price and let buyers bid.";

  @override
  String get createListingTypeFixed => "Buy now";

  @override
  String get createListingTypeFixedDesc => "One price. First buyer wins.";

  @override
  String get createListingTypeBazaar => "Group bazaar";

  @override
  String get createListingTypeBazaarDesc => "Under 10,000 IQD. Price drops as more buyers join.";

  @override
  String get createListingAuctionLocked => "Auction listings need Tier 2 verification.";

  @override
  String get createListingTier1Locked => "Verify your phone before listing.";

  @override
  String get createListingPhotosTitle => "Add photos";

  @override
  String get createListingPhotosSubtitle => "Three to five clear photos. We'll use them to draft your listing in four languages.";

  @override
  String get createListingPhotoFromCamera => "Camera";

  @override
  String get createListingPhotoFromGallery => "Gallery";

  @override
  String get createListingPhotoMinError => "Add at least three photos.";

  @override
  String get createListingPhotosUploading => "Uploading…";

  @override
  String get createListingPhotosFailed => "We couldn't upload all photos. Try again.";

  @override
  String get createListingPhotosContinue => "Continue";

  @override
  String createListingPhotosCount(int count) {
    return "$count of 10";
  }

  @override
  String get createListingAiTitle => "AI assistant";

  @override
  String get createListingAiSubtitle => "We'll read your photos and draft a four-language listing. You can edit it next.";

  @override
  String get createListingAiRun => "Generate draft";

  @override
  String get createListingAiRunning => "Reading your photos…";

  @override
  String get createListingAiFailed => "We couldn't generate a draft. Fill in the fields manually.";

  @override
  String get createListingAiRedFlagsTitle => "Heads up";

  @override
  String get createListingAiSkip => "Fill manually instead";

  @override
  String get createListingAiContinue => "Continue to review";

  @override
  String get createListingReviewTitle => "Review and publish";

  @override
  String get createListingReviewSubtitle => "Buyers see exactly what's here. Edit anything that's off.";

  @override
  String get createListingFieldTitle => "Title";

  @override
  String get createListingFieldDescription => "Description";

  @override
  String get createListingFieldCategory => "Category";

  @override
  String get createListingFieldCondition => "Condition";

  @override
  String get createListingFieldStartingPrice => "Starting price (IQD)";

  @override
  String get createListingFieldBuyNowPrice => "Buy-now price (IQD)";

  @override
  String get createListingFieldReservePrice => "Reserve price (optional, IQD)";

  @override
  String get createListingLocaleEn => "EN";

  @override
  String get createListingLocaleAr => "AR";

  @override
  String get createListingLocaleKu => "KU";

  @override
  String get createListingLocaleTr => "TR";

  @override
  String get createListingConditionNew => "New";

  @override
  String get createListingConditionLikeNew => "Like new";

  @override
  String get createListingConditionGood => "Good";

  @override
  String get createListingConditionFair => "Fair";

  @override
  String get createListingConditionForParts => "For parts";

  @override
  String get createListingPublish => "Publish listing";

  @override
  String get createListingPublishing => "Publishing…";

  @override
  String get createListingPublished => "Your listing is live.";

  @override
  String createListingPublishFailed(String reason) {
    return "Publish failed: $reason";
  }

  @override
  String get createListingDiscard => "Discard draft";

  @override
  String get createListingMissingTitle => "Title is required in all four languages.";

  @override
  String get createListingMissingDescription => "Description is required in all four languages.";

  @override
  String get createListingMissingCategory => "Pick a category.";

  @override
  String get createListingMissingCondition => "Pick a condition.";

  @override
  String get createListingMissingStartingPrice => "Set a starting price above zero.";

  @override
  String get createListingMissingBuyNowPrice => "Set a buy-now price above zero.";

  @override
  String get createListingBazaarCap => "Group Bazaar listings cap at 10,000 IQD.";

  @override
  String get listingTypeAuction => "Auction";

  @override
  String get listingTypeFixed => "Buy now";

  @override
  String get listingTypeBazaar => "Group Bazaar";

  @override
  String get listingDetailVerifiedVideo => "Verified video";

  @override
  String get listingDetailStartingAt => "Starting at";

  @override
  String get listingDetailCurrentHigh => "Current high";

  @override
  String get listingDetailBuyNow => "Buy now";

  @override
  String get listingDetailBidUnavailable => "Bidding opens in the next release.";

  @override
  String get listingDetailSellerLabel => "Seller";

  @override
  String listingDetailViews(int count) {
    return "$count views";
  }

  @override
  String get listingDetailDraftBadge => "Draft";

  @override
  String get listingDetailCancelledBadge => "Cancelled";

  @override
  String get listingDetailUnavailable => "This listing isn't available.";

  @override
  String get browseTitle => "Browse";

  @override
  String get browseSearchHint => "Search listings";

  @override
  String get browseEmpty => "No listings match.";

  @override
  String get browseFilterAll => "All";

  @override
  String get browseFilterAuction => "Auctions";

  @override
  String get browseFilterFixed => "Buy now";

  @override
  String get browseFilterBazaar => "Bazaar";

  @override
  String get browseResultsTitle => "Results";

  @override
  String get homeSectionEndingSoon => "Ending soon";

  @override
  String get homeSectionHot => "Hot";

  @override
  String get homeSectionBazaar => "Group Bazaar";

  @override
  String get homeSectionCategories => "Categories";

  @override
  String get homeSeeAll => "See all";

  @override
  String get homeFabSell => "Sell";
}
