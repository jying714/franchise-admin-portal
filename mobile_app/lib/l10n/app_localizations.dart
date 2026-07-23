import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addFavorite;

  /// No description provided for @addMoreItems.
  ///
  /// In en, this message translates to:
  /// **'Add More Items'**
  String get addMoreItems;

  /// No description provided for @addScheduledOrder.
  ///
  /// In en, this message translates to:
  /// **'Add Scheduled Order'**
  String get addScheduledOrder;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @addToFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesTooltip;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressAdded.
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// No description provided for @addressRemoved.
  ///
  /// In en, this message translates to:
  /// **'Address removed'**
  String get addressRemoved;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @appleSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple (coming soon)'**
  String get appleSignInComingSoon;

  /// No description provided for @applyPromo.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo'**
  String get applyPromo;

  /// No description provided for @applyPromoCta.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo'**
  String get applyPromoCta;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenu;

  /// No description provided for @bannerCtaText.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get bannerCtaText;

  /// No description provided for @brandLogo.
  ///
  /// In en, this message translates to:
  /// **'Doughboys Pizzeria Logo'**
  String get brandLogo;

  /// No description provided for @browseCategoryCta.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseCategoryCta;

  /// No description provided for @businessHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get businessHours;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get cartIsEmpty;

  /// No description provided for @cartTooltip.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get cartTooltip;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoryAppetizers.
  ///
  /// In en, this message translates to:
  /// **'Appetizers'**
  String get categoryAppetizers;

  /// No description provided for @categoryCalzones.
  ///
  /// In en, this message translates to:
  /// **'Calzones'**
  String get categoryCalzones;

  /// No description provided for @categoryDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get categoryDesserts;

  /// No description provided for @categoryDinners.
  ///
  /// In en, this message translates to:
  /// **'Dinners'**
  String get categoryDinners;

  /// No description provided for @categoryDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get categoryDrinks;

  /// No description provided for @categoryFoodQuality.
  ///
  /// In en, this message translates to:
  /// **'Food Quality'**
  String get categoryFoodQuality;

  /// No description provided for @categoryOrderAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Order Accuracy'**
  String get categoryOrderAccuracy;

  /// No description provided for @categoryPizzas.
  ///
  /// In en, this message translates to:
  /// **'Pizzas'**
  String get categoryPizzas;

  /// No description provided for @categorySalads.
  ///
  /// In en, this message translates to:
  /// **'Salads'**
  String get categorySalads;

  /// No description provided for @categoryService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get categoryService;

  /// No description provided for @categorySubs.
  ///
  /// In en, this message translates to:
  /// **'Subs'**
  String get categorySubs;

  /// No description provided for @categoryDeliverySpeed.
  ///
  /// In en, this message translates to:
  /// **'Delivery Speed'**
  String get categoryDeliverySpeed;

  /// No description provided for @chatSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Support'**
  String get chatSupportTitle;

  /// No description provided for @chatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Chat with Us'**
  String get chatWithUs;

  /// No description provided for @checkBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for more promotions.'**
  String get checkBackSoon;

  /// No description provided for @checkConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionAndTryAgain;

  /// No description provided for @checkConnectionToReload.
  ///
  /// In en, this message translates to:
  /// **'Check your connection to reload.'**
  String get checkConnectionToReload;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @chooseDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Choose Delivery Time'**
  String get chooseDeliveryTime;

  /// No description provided for @choosePickupTime.
  ///
  /// In en, this message translates to:
  /// **'Choose Pickup Time'**
  String get choosePickupTime;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get confirmDeleteAccount;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @continueAsGuestButton.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuestButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch URL'**
  String get couldNotLaunchUrl;

  /// No description provided for @couldNotLoadPromotions.
  ///
  /// In en, this message translates to:
  /// **'Could not load promotions.'**
  String get couldNotLoadPromotions;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get creditDebitCard;

  /// No description provided for @currencyFormat.
  ///
  /// In en, this message translates to:
  /// **'\${value}'**
  String currencyFormat(Object value);

  /// No description provided for @customizationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Customization options coming soon!'**
  String get customizationComingSoon;

  /// No description provided for @customizationPrice.
  ///
  /// In en, this message translates to:
  /// **'Option Price'**
  String get customizationPrice;

  /// No description provided for @customizations.
  ///
  /// In en, this message translates to:
  /// **'Customizations'**
  String get customizations;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @customizeAndAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Customize & Add to Cart'**
  String get customizeAndAddToCart;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @defaultBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get defaultBannerCta;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryAddresses.
  ///
  /// In en, this message translates to:
  /// **'Delivery Addresses'**
  String get deliveryAddresses;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryType;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @editScheduledOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit Scheduled Order'**
  String get editScheduledOrder;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Empty Cart'**
  String get emptyCart;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'There’s nothing here yet!'**
  String get emptyStateMessage;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get enterName;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLoadingCart.
  ///
  /// In en, this message translates to:
  /// **'Error loading cart.'**
  String get errorLoadingCart;

  /// Shows items in favorite order
  ///
  /// In en, this message translates to:
  /// **'Items: {items}'**
  String favoriteOrderItems(Object items);

  /// No description provided for @favoriteOrders.
  ///
  /// In en, this message translates to:
  /// **'Favorite Orders'**
  String get favoriteOrders;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackBackToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get feedbackBackToMenu;

  /// No description provided for @feedbackCommentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional comments (optional)'**
  String get feedbackCommentsLabel;

  /// No description provided for @feedbackOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Feedback queued and will be submitted when online.'**
  String get feedbackOfflineBody;

  /// No description provided for @feedbackOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get feedbackOfflineTitle;

  /// No description provided for @feedbackPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your order?'**
  String get feedbackPromptTitle;

  /// No description provided for @feedbackScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Feedback'**
  String get feedbackScreenTitle;

  /// No description provided for @feedbackStarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, one {# star} other {# stars}}'**
  String feedbackStarTooltip(num stars);

  /// No description provided for @feedbackSubmitAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Submit anonymously'**
  String get feedbackSubmitAnonymous;

  /// No description provided for @feedbackSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get feedbackSubmitButton;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted. Thank you!'**
  String get feedbackSubmitted;

  /// No description provided for @feedbackThankYouBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been submitted.'**
  String get feedbackThankYouBody;

  /// No description provided for @feedbackThankYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get feedbackThankYouTitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @googlePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get googlePay;

  /// No description provided for @guestCheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get guestCheckout;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide Password'**
  String get hidePassword;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password.'**
  String get invalidPassword;

  /// No description provided for @invalidPromo.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code.'**
  String get invalidPromo;

  /// No description provided for @invalidZip.
  ///
  /// In en, this message translates to:
  /// **'Invalid ZIP code'**
  String get invalidZip;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Menu item added.'**
  String get itemAdded;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// No description provided for @itemRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart'**
  String get itemRemovedFromCart;

  /// No description provided for @itemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Item is unavailable.'**
  String get itemUnavailable;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get items;

  /// No description provided for @labelExample.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g., Home)'**
  String get labelExample;

  /// No description provided for @labelRequired.
  ///
  /// In en, this message translates to:
  /// **'Label is required'**
  String get labelRequired;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to {lang}'**
  String languageSetTo(Object lang);

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @leaveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get leaveFeedback;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data.'**
  String get loadingError;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @loyaltyAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Loyalty & Rewards'**
  String get loyaltyAndRewards;

  /// No description provided for @loyaltyErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading loyalty data.'**
  String get loyaltyErrorLoading;

  /// No description provided for @loyaltyLastRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Last redeemed:'**
  String get loyaltyLastRedeemed;

  /// No description provided for @loyaltyLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String loyaltyLevel(Object level);

  /// No description provided for @loyaltyNoActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order more to start earning points and rewards.'**
  String get loyaltyNoActivitySubtitle;

  /// No description provided for @loyaltyNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No loyalty activity yet!'**
  String get loyaltyNoActivityTitle;

  /// No description provided for @loyaltyNextReward.
  ///
  /// In en, this message translates to:
  /// **'Next reward in {points} pts'**
  String loyaltyNextReward(Object points);

  /// No description provided for @loyaltyOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get loyaltyOrderNow;

  /// No description provided for @loyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String loyaltyPoints(Object points);

  /// No description provided for @loyaltyRankLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get loyaltyRankLegend;

  /// No description provided for @loyaltyRankNewbie.
  ///
  /// In en, this message translates to:
  /// **'Newbie'**
  String get loyaltyRankNewbie;

  /// No description provided for @loyaltyRankPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get loyaltyRankPro;

  /// No description provided for @loyaltyRankRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get loyaltyRankRegular;

  /// No description provided for @loyaltyYourRewards.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get loyaltyYourRewards;

  /// No description provided for @mainMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenuTitle;

  /// No description provided for @menuBeingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Our menu is being updated. Please check back soon.'**
  String get menuBeingUpdated;

  /// Label for menu category used by screen readers for accessibility
  ///
  /// In en, this message translates to:
  /// **'Menu category: {categoryName}'**
  String menuCategoryLabel(Object categoryName);

  /// No description provided for @menuItems.
  ///
  /// In en, this message translates to:
  /// **'Menu Items'**
  String get menuItems;

  /// No description provided for @menuLoadError.
  ///
  /// In en, this message translates to:
  /// **'Menu could not be loaded.'**
  String get menuLoadError;

  /// No description provided for @menuUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Menu unavailable. Check your connection.'**
  String get menuUnavailable;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms & Privacy Policy to continue.'**
  String get mustAcceptTerms;

  /// No description provided for @mustSignInForAddresses.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to manage addresses.'**
  String get mustSignInForAddresses;

  /// No description provided for @mustSignInForCart.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to view your cart.'**
  String get mustSignInForCart;

  /// No description provided for @mustSignInForChat.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to use chat support.'**
  String get mustSignInForChat;

  /// No description provided for @mustSignInForFavorites.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to view favorites.'**
  String get mustSignInForFavorites;

  /// No description provided for @mustSignInForScheduledOrders.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to view scheduled orders.'**
  String get mustSignInForScheduledOrders;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @newScheduledOrder.
  ///
  /// In en, this message translates to:
  /// **'New Scheduled Order'**
  String get newScheduledOrder;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextRunDate.
  ///
  /// In en, this message translates to:
  /// **'Next Run Date'**
  String get nextRunDate;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAddressesSaved.
  ///
  /// In en, this message translates to:
  /// **'No addresses saved'**
  String get noAddressesSaved;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available.'**
  String get noCategories;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available.'**
  String get noCategoriesAvailable;

  /// No description provided for @noFavoriteMenuItems.
  ///
  /// In en, this message translates to:
  /// **'No favorite menu items'**
  String get noFavoriteMenuItems;

  /// No description provided for @noFavoriteOrdersSaved.
  ///
  /// In en, this message translates to:
  /// **'No favorite orders saved'**
  String get noFavoriteOrdersSaved;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessages;

  /// No description provided for @noPastOrders.
  ///
  /// In en, this message translates to:
  /// **'No past orders'**
  String get noPastOrders;

  /// No description provided for @noPromotions.
  ///
  /// In en, this message translates to:
  /// **'No current promotions.'**
  String get noPromotions;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @noScheduledOrders.
  ///
  /// In en, this message translates to:
  /// **'No scheduled orders'**
  String get noScheduledOrders;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Info'**
  String get nutrition;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @offlineMenu.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Menu unavailable.'**
  String get offlineMenu;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get orderCancelled;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed!'**
  String get orderConfirmed;

  /// Order date and total, e.g. '2024-06-01 - $22.99'
  ///
  /// In en, this message translates to:
  /// **'{date} - \${total}'**
  String orderDateAndTotal(Object date, Object total);

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Order failed'**
  String get orderFailed;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @orderNowCta.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNowCta;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// Order number with ID shown in order lists/cards
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumberWithId(Object id);

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlaced;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed. Try again later.'**
  String get passwordResetFailed;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pauseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pause schedule'**
  String get pauseSchedule;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed.'**
  String get paymentFailed;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick Time'**
  String get pickTime;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @pleaseSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time.'**
  String get pleaseSelectTime;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @posSystem.
  ///
  /// In en, this message translates to:
  /// **'POS System (Mock/API Demo)'**
  String get posSystem;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by Dough Boys Tech'**
  String get poweredBy;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @promo.
  ///
  /// In en, this message translates to:
  /// **'Promo'**
  String get promo;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo applied!'**
  String get promoApplied;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promoCode;

  /// No description provided for @promoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo Discount'**
  String get promoDiscount;

  /// No description provided for @promotionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load promotions.'**
  String get promotionsLoadError;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1.'**
  String get quantityAtLeastOne;

  /// No description provided for @ratingRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a star rating.'**
  String get ratingRequiredError;

  /// No description provided for @redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFavorite;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromCart;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review Order'**
  String get reviewOrder;

  /// No description provided for @rewardAvailableSemantic.
  ///
  /// In en, this message translates to:
  /// **'Reward available'**
  String get rewardAvailableSemantic;

  /// No description provided for @rewardClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get rewardClaim;

  /// No description provided for @rewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get rewardClaimed;

  /// No description provided for @rewardClaimedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed'**
  String get rewardClaimedSemantic;

  /// No description provided for @rewardClaimedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward successfully claimed!'**
  String get rewardClaimedSuccess;

  /// No description provided for @rewardRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed!'**
  String get rewardRedeemed;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @reorderNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Reorder not implemented'**
  String get reorderNotImplemented;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnToHome;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Subtitle for scheduled orders in the list
  ///
  /// In en, this message translates to:
  /// **'Frequency: {frequency}, Next: {nextRun}\\nItems: {items}'**
  String scheduledOrderSubtitle(Object frequency, Object nextRun, Object items);

  /// No description provided for @scheduledOrders.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Orders'**
  String get scheduledOrders;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchMenu.
  ///
  /// In en, this message translates to:
  /// **'Search Menu...'**
  String get searchMenu;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get seeLess;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items:'**
  String get selectItems;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get shopNow;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show Password'**
  String get showPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please check your credentials.'**
  String get signInFailed;

  /// No description provided for @signInNow.
  ///
  /// In en, this message translates to:
  /// **'Sign in now'**
  String get signInNow;

  /// No description provided for @signInProfileError.
  ///
  /// In en, this message translates to:
  /// **'Sign in succeeded but could not load profile. Try again.'**
  String get signInProfileError;

  /// No description provided for @signInToFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign in to favorite'**
  String get signInToFavoriteTooltip;

  /// No description provided for @signInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Log in to place your order.'**
  String get signInToOrder;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Try a different email.'**
  String get signUpFailed;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get signUpNow;

  /// No description provided for @signUpNowButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Now'**
  String get signUpNowButton;

  /// No description provided for @signUpProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up succeeded but profile setup failed. Try again.'**
  String get signUpProfileFailed;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShopping;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @stateRequired.
  ///
  /// In en, this message translates to:
  /// **'State is required'**
  String get stateRequired;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @streetRequired.
  ///
  /// In en, this message translates to:
  /// **'Street is required'**
  String get streetRequired;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Support chat is online with dynamic franchise name
  ///
  /// In en, this message translates to:
  /// **'{franchiseName} support is online'**
  String supportIsOnline(Object franchiseName);

  /// Support chat offline message with dynamic franchise name
  ///
  /// In en, this message translates to:
  /// **'{franchiseName} support will reply soon'**
  String supportWillReplySoon(Object franchiseName);

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @termsAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms & Privacy Policy.'**
  String get termsAndPrivacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @thankYouForYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order!'**
  String get thankYouForYourOrder;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get tryAgainLater;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @viewMenu.
  ///
  /// In en, this message translates to:
  /// **'View Menu'**
  String get viewMenu;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order your favorite pizza or sign in for a full experience.'**
  String get welcomeSubtitle;

  /// Welcome headline with dynamic franchise name
  ///
  /// In en, this message translates to:
  /// **'Welcome to {franchiseName}'**
  String welcomeTitle(Object franchiseName);

  /// No description provided for @welcomeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Welcome headline with dynamic franchise name'**
  String get welcomeTitleHint;

  /// Personalized welcome message for signed-in user
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeUser(Object name);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get yourCartIsEmpty;

  /// No description provided for @yourOrderIdIs.
  ///
  /// In en, this message translates to:
  /// **'Your order ID is:'**
  String get yourOrderIdIs;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get zipCode;

  /// No description provided for @zipRequired.
  ///
  /// In en, this message translates to:
  /// **'ZIP is required'**
  String get zipRequired;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get iAgreeToThe;

  /// No description provided for @sortByPopularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get sortByPopularity;

  /// No description provided for @sortByPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortByPrice;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @logInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Log in to place your order.'**
  String get logInToOrder;

  /// No description provided for @addedToCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart!'**
  String get addedToCartMessage;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearCartConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your cart?'**
  String get clearCartConfirmation;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @selectedTimeOutsideBusinessHours.
  ///
  /// In en, this message translates to:
  /// **'Selected time is outside business hours.'**
  String get selectedTimeOutsideBusinessHours;

  /// No description provided for @orderType.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get orderType;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash (Pay at Pickup/Delivery)'**
  String get cashPayment;

  /// No description provided for @logoErrorTooltip.
  ///
  /// In en, this message translates to:
  /// **'App logo unavailable'**
  String get logoErrorTooltip;

  /// Shows when the loyalty reward was claimed
  ///
  /// In en, this message translates to:
  /// **'Claimed on {date}'**
  String loyaltyRewardClaimedOn(Object date);

  /// Number of points required for reward
  ///
  /// In en, this message translates to:
  /// **'{points} pts required'**
  String loyaltyRewardRequiredPoints(Object points);

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @addCategoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding a new category.'**
  String get addCategoryPrompt;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get categoryDescription;

  /// No description provided for @categoryImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL or Asset Path (optional)'**
  String get categoryImageUrl;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Try again.'**
  String get saveFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete. Try again.'**
  String get deleteFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories.'**
  String get loadFailed;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete category \"{name}\"? This cannot be undone.'**
  String deleteCategoryConfirm(Object name);

  /// No description provided for @categorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved.'**
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted.'**
  String get categoryDeleted;

  /// No description provided for @bulkUpload.
  ///
  /// In en, this message translates to:
  /// **'Bulk Upload'**
  String get bulkUpload;

  /// No description provided for @bulkUploadCategories.
  ///
  /// In en, this message translates to:
  /// **'Bulk Upload Categories'**
  String get bulkUploadCategories;

  /// No description provided for @bulkUploadInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste a CSV (name,image,description) with one category per line below. First line is header.'**
  String get bulkUploadInstructions;

  /// No description provided for @bulkUploadPasteCsv.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV data here'**
  String get bulkUploadPasteCsv;

  /// No description provided for @bulkUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Categories uploaded successfully.'**
  String get bulkUploadSuccess;

  /// No description provided for @bulkUploadError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading categories.'**
  String get bulkUploadError;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @adminCategoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get adminCategoryManagement;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get noCategoriesFound;

  /// No description provided for @noCategoriesAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Start by adding a new category or using bulk upload.'**
  String get noCategoriesAdminHint;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories.'**
  String get loadError;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get adminSearchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @categoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully.'**
  String get categoryAdded;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully.'**
  String get categoryUpdated;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories.'**
  String get errorLoadingCategories;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseTryAgain;

  /// No description provided for @noCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Add your first category to get started.'**
  String get noCategoriesMessage;

  /// No description provided for @menuEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Editor'**
  String get menuEditorTitle;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @bulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get bulkDelete;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Menu item updated.'**
  String get itemUpdated;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Menu item deleted.'**
  String get itemDeleted;

  /// No description provided for @customizationsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customizations updated successfully.'**
  String get customizationsUpdated;

  /// No description provided for @exportMenu.
  ///
  /// In en, this message translates to:
  /// **'Export Menu Data'**
  String get exportMenu;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Menu export generated.'**
  String get exportStarted;

  /// No description provided for @bulkImport.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import'**
  String get bulkImport;

  /// No description provided for @bulkImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bulk menu import complete.'**
  String get bulkImportSuccess;

  /// No description provided for @deleteItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Menu Items'**
  String get deleteItemsTitle;

  /// No description provided for @deleteItemsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} menu items?'**
  String deleteItemsPrompt(Object count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @searchMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Search menu items, SKU, or category...'**
  String get searchMenuHint;

  /// No description provided for @colImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get colImage;

  /// No description provided for @colName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get colName;

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get colCategory;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get colPrice;

  /// No description provided for @colAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get colAvailable;

  /// No description provided for @colSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get colSKU;

  /// No description provided for @colDietary.
  ///
  /// In en, this message translates to:
  /// **'Dietary'**
  String get colDietary;

  /// No description provided for @colAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get colAllergens;

  /// No description provided for @colActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get colActions;

  /// No description provided for @bulkActionsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bulkActionsSelected(Object count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @errorLoadingMenu.
  ///
  /// In en, this message translates to:
  /// **'Error loading menu items'**
  String get errorLoadingMenu;

  /// No description provided for @noCategoriesMsg.
  ///
  /// In en, this message translates to:
  /// **'Create at least one category before adding menu items.'**
  String get noCategoriesMsg;

  /// No description provided for @noMenuItems.
  ///
  /// In en, this message translates to:
  /// **'No menu items yet'**
  String get noMenuItems;

  /// No description provided for @noMenuItemsMsg.
  ///
  /// In en, this message translates to:
  /// **'Add your first menu item.'**
  String get noMenuItemsMsg;

  /// No description provided for @addCustomization.
  ///
  /// In en, this message translates to:
  /// **'Add Customization'**
  String get addCustomization;

  /// No description provided for @editCustomization.
  ///
  /// In en, this message translates to:
  /// **'Edit Customization'**
  String get editCustomization;

  /// No description provided for @deleteCustomization.
  ///
  /// In en, this message translates to:
  /// **'Delete Customization'**
  String get deleteCustomization;

  /// No description provided for @customizationName.
  ///
  /// In en, this message translates to:
  /// **'Option Name'**
  String get customizationName;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @bulkEdit.
  ///
  /// In en, this message translates to:
  /// **'Bulk Edit'**
  String get bulkEdit;

  /// No description provided for @bulkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Bulk Update'**
  String get bulkUpdate;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLog;

  /// No description provided for @auditLogEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get auditLogEntry;

  /// No description provided for @auditAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditAction;

  /// No description provided for @auditUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get auditUser;

  /// No description provided for @auditTargetType.
  ///
  /// In en, this message translates to:
  /// **'Target Type'**
  String get auditTargetType;

  /// No description provided for @auditTargetId.
  ///
  /// In en, this message translates to:
  /// **'Target ID'**
  String get auditTargetId;

  /// No description provided for @auditTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get auditTimestamp;

  /// No description provided for @auditDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get auditDetails;

  /// No description provided for @auditIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get auditIpAddress;

  /// No description provided for @auditLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit log entries yet.'**
  String get auditLogEmpty;

  /// No description provided for @auditLogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load audit log.'**
  String get auditLogLoadError;

  /// No description provided for @auditLogFilterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by target type'**
  String get auditLogFilterByType;

  /// No description provided for @auditLogFilterByUser.
  ///
  /// In en, this message translates to:
  /// **'Filter by user'**
  String get auditLogFilterByUser;

  /// No description provided for @auditLogSearch.
  ///
  /// In en, this message translates to:
  /// **'Search audit log...'**
  String get auditLogSearch;

  /// No description provided for @auditLogViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get auditLogViewDetails;

  /// No description provided for @exportMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Menu to CSV'**
  String get exportMenuTitle;

  /// No description provided for @exportMenuInstructions.
  ///
  /// In en, this message translates to:
  /// **'Export all menu items and categories to a CSV file for backup or audit.'**
  String get exportMenuInstructions;

  /// No description provided for @exportMenuSuccess.
  ///
  /// In en, this message translates to:
  /// **'Menu exported successfully.'**
  String get exportMenuSuccess;

  /// No description provided for @exportMenuFailed.
  ///
  /// In en, this message translates to:
  /// **'Menu export failed.'**
  String get exportMenuFailed;

  /// No description provided for @downloadCsv.
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get downloadCsv;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @singleSelect.
  ///
  /// In en, this message translates to:
  /// **'Single Select'**
  String get singleSelect;

  /// No description provided for @multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi Select'**
  String get multiSelect;

  /// No description provided for @quantitySelect.
  ///
  /// In en, this message translates to:
  /// **'Quantity Select'**
  String get quantitySelect;

  /// No description provided for @minSelect.
  ///
  /// In en, this message translates to:
  /// **'Min Select'**
  String get minSelect;

  /// No description provided for @maxSelect.
  ///
  /// In en, this message translates to:
  /// **'Max Select'**
  String get maxSelect;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @noCustomizations.
  ///
  /// In en, this message translates to:
  /// **'No customization groups added.'**
  String get noCustomizations;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @bulkUploadNoData.
  ///
  /// In en, this message translates to:
  /// **'No data detected.'**
  String get bulkUploadNoData;

  /// No description provided for @bulkUploadPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview ({count} items):'**
  String bulkUploadPreview(Object count);

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @unauthorizedAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access the admin dashboard.'**
  String get unauthorizedAccess;

  /// No description provided for @categoryManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagementTitle;

  /// No description provided for @inventoryManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventoryManagementTitle;

  /// No description provided for @orderAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Analytics'**
  String get orderAnalyticsTitle;

  /// No description provided for @feedbackManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Management'**
  String get feedbackManagementTitle;

  /// No description provided for @promoManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo Management'**
  String get promoManagementTitle;

  /// No description provided for @staffAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Access'**
  String get staffAccessTitle;

  /// No description provided for @featureSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Settings'**
  String get featureSettingsTitle;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @addInventory.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory'**
  String get addInventory;

  /// No description provided for @editInventory.
  ///
  /// In en, this message translates to:
  /// **'Edit Inventory'**
  String get editInventory;

  /// No description provided for @deleteInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Inventory Item'**
  String get deleteInventoryTitle;

  /// No description provided for @deleteInventoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteInventoryPrompt(Object name);

  /// No description provided for @inventoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Inventory item added.'**
  String get inventoryAdded;

  /// No description provided for @inventoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Inventory item updated.'**
  String get inventoryUpdated;

  /// No description provided for @inventoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Inventory item deleted.'**
  String get inventoryDeleted;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error loading inventory.'**
  String get errorLoadingInventory;

  /// No description provided for @noInventory.
  ///
  /// In en, this message translates to:
  /// **'No Inventory'**
  String get noInventory;

  /// No description provided for @noInventoryMsg.
  ///
  /// In en, this message translates to:
  /// **'No inventory items found.'**
  String get noInventoryMsg;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search inventory...'**
  String get inventorySearchHint;

  /// No description provided for @adminChatManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Management'**
  String get adminChatManagementTitle;

  /// No description provided for @adminFeatureSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Settings'**
  String get adminFeatureSettingsTitle;

  /// No description provided for @adminFeedbackManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Management'**
  String get adminFeedbackManagementTitle;

  /// No description provided for @adminAnalyticsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get adminAnalyticsDashboardTitle;

  /// No description provided for @adminPromoManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo Management'**
  String get adminPromoManagementTitle;

  /// No description provided for @adminBulkUploadPromo.
  ///
  /// In en, this message translates to:
  /// **'Bulk Upload Promos'**
  String get adminBulkUploadPromo;

  /// No description provided for @adminExportPromo.
  ///
  /// In en, this message translates to:
  /// **'Export Promos'**
  String get adminExportPromo;

  /// No description provided for @adminCreatePromo.
  ///
  /// In en, this message translates to:
  /// **'Create Promo'**
  String get adminCreatePromo;

  /// No description provided for @adminEditPromo.
  ///
  /// In en, this message translates to:
  /// **'Edit Promo'**
  String get adminEditPromo;

  /// No description provided for @adminExportAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Export Analytics'**
  String get adminExportAnalytics;

  /// No description provided for @adminFeedbackDetail.
  ///
  /// In en, this message translates to:
  /// **'Feedback Details'**
  String get adminFeedbackDetail;

  /// No description provided for @adminFeatureToggle.
  ///
  /// In en, this message translates to:
  /// **'Feature Toggles'**
  String get adminFeatureToggle;

  /// No description provided for @adminReplyChat.
  ///
  /// In en, this message translates to:
  /// **'Reply to Chat'**
  String get adminReplyChat;

  /// No description provided for @adminUploadAll.
  ///
  /// In en, this message translates to:
  /// **'Upload All'**
  String get adminUploadAll;

  /// No description provided for @adminChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File (JSON/CSV)'**
  String get adminChooseFile;

  /// No description provided for @adminNoFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback submitted yet.'**
  String get adminNoFeedback;

  /// No description provided for @adminNoChats.
  ///
  /// In en, this message translates to:
  /// **'No support chats yet.'**
  String get adminNoChats;

  /// No description provided for @adminNoPromos.
  ///
  /// In en, this message translates to:
  /// **'No promotions yet.'**
  String get adminNoPromos;

  /// No description provided for @adminNoFeatures.
  ///
  /// In en, this message translates to:
  /// **'No features found.'**
  String get adminNoFeatures;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminSave;

  /// No description provided for @adminSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get adminSend;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get adminClose;

  /// No description provided for @adminExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get adminExport;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActive;

  /// No description provided for @adminStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get adminStartDate;

  /// No description provided for @adminEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get adminEndDate;

  /// No description provided for @adminMaxUses.
  ///
  /// In en, this message translates to:
  /// **'Max Uses'**
  String get adminMaxUses;

  /// No description provided for @adminMaxUsesType.
  ///
  /// In en, this message translates to:
  /// **'Max Uses Type'**
  String get adminMaxUsesType;

  /// No description provided for @adminDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get adminDiscount;

  /// No description provided for @adminType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminType;

  /// No description provided for @adminMinOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Min Order Value'**
  String get adminMinOrderValue;

  /// No description provided for @adminPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminPromoTitle;

  /// No description provided for @adminPromoDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminPromoDescription;

  /// No description provided for @adminPromoItems.
  ///
  /// In en, this message translates to:
  /// **'Applicable Items'**
  String get adminPromoItems;

  /// No description provided for @adminDeletePromoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this promotion?'**
  String get adminDeletePromoConfirm;

  /// No description provided for @adminDeleteChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat thread?'**
  String get adminDeleteChatConfirm;

  /// No description provided for @adminDeleteFeedbackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback?'**
  String get adminDeleteFeedbackConfirm;

  /// No description provided for @adminPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminPreview;

  /// No description provided for @adminExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to: {path}'**
  String adminExportedTo(Object path);

  /// No description provided for @adminExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get adminExporting;

  /// No description provided for @adminUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse file: {error}'**
  String adminUploadFailed(Object error);

  /// No description provided for @adminUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo upload complete.'**
  String get adminUploadSuccess;

  /// No description provided for @adminPromoExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promos exported successfully.'**
  String get adminPromoExportSuccess;

  /// No description provided for @adminAnalyticsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Analytics exported successfully.'**
  String get adminAnalyticsExportSuccess;

  /// No description provided for @adminFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get adminFieldRequired;

  /// No description provided for @adminPromoBulkUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'Import multiple promos from a JSON or CSV file.'**
  String get adminPromoBulkUploadDesc;

  /// No description provided for @adminPromoExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all active promos to CSV.'**
  String get adminPromoExportDesc;

  /// No description provided for @adminAnalyticsExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export summary analytics to CSV.'**
  String get adminAnalyticsExportDesc;

  /// No description provided for @adminFeedbackDetailCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get adminFeedbackDetailCategories;

  /// No description provided for @adminFeedbackDetailRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get adminFeedbackDetailRating;

  /// No description provided for @adminFeedbackDetailComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get adminFeedbackDetailComment;

  /// No description provided for @adminFeedbackDetailTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get adminFeedbackDetailTimestamp;

  /// No description provided for @adminFeedbackDetailUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get adminFeedbackDetailUserId;

  /// No description provided for @adminFeedbackDetailOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get adminFeedbackDetailOrderId;

  /// No description provided for @adminFeedbackDetailAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get adminFeedbackDetailAnonymous;

  /// No description provided for @adminSendReply.
  ///
  /// In en, this message translates to:
  /// **'Send Reply'**
  String get adminSendReply;

  /// No description provided for @adminReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent.'**
  String get adminReplySent;

  /// No description provided for @adminReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reply.'**
  String get adminReplyFailed;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Threshold'**
  String get threshold;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @staffAddStaffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get staffAddStaffTooltip;

  /// No description provided for @staffNoStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'No Staff'**
  String get staffNoStaffTitle;

  /// No description provided for @staffNoStaffMessage.
  ///
  /// In en, this message translates to:
  /// **'No staff members have been added yet.'**
  String get staffNoStaffMessage;

  /// No description provided for @staffAddStaffDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Staff Member'**
  String get staffAddStaffDialogTitle;

  /// No description provided for @staffNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffNameLabel;

  /// No description provided for @staffEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get staffEmailLabel;

  /// No description provided for @staffRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRoleLabel;

  /// No description provided for @staffRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get staffRoleOwner;

  /// No description provided for @staffRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get staffRoleManager;

  /// No description provided for @staffRoleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffRoleStaff;

  /// No description provided for @staffAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get staffAddButton;

  /// No description provided for @staffRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get staffRemoveTooltip;

  /// No description provided for @staffRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff'**
  String get staffRemoveDialogTitle;

  /// No description provided for @staffRemoveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this staff member?'**
  String get staffRemoveDialogBody;

  /// No description provided for @staffRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get staffRemoveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @staffNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get staffNameRequired;

  /// No description provided for @staffEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get staffEmailRequired;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminPanelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go to Admin Dashboard'**
  String get adminPanelTooltip;

  /// No description provided for @unauthorizedAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized — You do not have permission to access this page.'**
  String get unauthorizedAdminMessage;

  /// No description provided for @returnToHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnToHomeButton;

  /// No description provided for @pleaseSelectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select required options'**
  String get pleaseSelectRequired;

  /// No description provided for @pleaseSelectAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Please select at least {num} options for {name}.'**
  String pleaseSelectAtLeast(Object name, Object num);

  /// No description provided for @tooManySelected.
  ///
  /// In en, this message translates to:
  /// **'You have selected too many options for {name}. Maximum allowed is {max}.'**
  String tooManySelected(Object max, Object name);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @outOfStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStockLabel;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get cartEmpty;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Please review and update your name and phone number before continuing. You only need to do this once.'**
  String get completeProfileMessage;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get invalidPhoneNumber;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @includedIngredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Ingredients'**
  String get includedIngredientsLabel;

  /// No description provided for @chooseCrustTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Crust Type'**
  String get chooseCrustTypeLabel;

  /// No description provided for @chooseCookTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cook Type'**
  String get chooseCookTypeLabel;

  /// No description provided for @chooseCutStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cut Style'**
  String get chooseCutStyleLabel;

  /// No description provided for @chooseDressingLabel.
  ///
  /// In en, this message translates to:
  /// **'Dressing'**
  String get chooseDressingLabel;

  /// No description provided for @chooseSideLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Side'**
  String get chooseSideLabel;

  /// No description provided for @portionWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole'**
  String get portionWhole;

  /// No description provided for @portionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left Side'**
  String get portionLeft;

  /// No description provided for @portionRight.
  ///
  /// In en, this message translates to:
  /// **'Right Side'**
  String get portionRight;

  /// No description provided for @extraLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extraLabel;

  /// No description provided for @doubleLabel.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get doubleLabel;

  /// No description provided for @addToppingLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'First {count} toppings included'**
  String addToppingLimitNotice(Object count);

  /// No description provided for @additionalDressingNotice.
  ///
  /// In en, this message translates to:
  /// **'Additional dressings: {price} each'**
  String additionalDressingNotice(Object price);

  /// No description provided for @currentIngredients.
  ///
  /// In en, this message translates to:
  /// **'Current Ingredients'**
  String get currentIngredients;

  /// No description provided for @meatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Meats'**
  String get meatsLabel;

  /// No description provided for @vegetablesLabel.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetablesLabel;

  /// No description provided for @cheesesLabel.
  ///
  /// In en, this message translates to:
  /// **'Cheeses'**
  String get cheesesLabel;

  /// No description provided for @saucesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sauces'**
  String get saucesLabel;

  /// No description provided for @crustTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Crust Type'**
  String get crustTypeLabel;

  /// No description provided for @cookTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cook Type'**
  String get cookTypeLabel;

  /// No description provided for @cutStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cut Style'**
  String get cutStyleLabel;

  /// No description provided for @extra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extra;

  /// No description provided for @double.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get double;

  /// No description provided for @addChipHint.
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String addChipHint(Object label);

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsLabel;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinLabel;

  /// No description provided for @unauthorizedPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized — Please log in.'**
  String get unauthorizedPleaseLogin;

  /// No description provided for @unauthorizedNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized — You do not have permission to access this page.'**
  String get unauthorizedNoPermission;

  /// No description provided for @noFeaturesFound.
  ///
  /// In en, this message translates to:
  /// **'No features found.'**
  String get noFeaturesFound;

  /// No description provided for @unauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorizedTitle;

  /// No description provided for @unauthorizedFeatureChange.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action. This attempt has been logged.'**
  String get unauthorizedFeatureChange;

  /// No description provided for @featureDisplayName.
  ///
  /// In en, this message translates to:
  /// **'{key, select, loyaltyEnabled{Loyalty} inventoryEnabled{Inventory} statusEnabled{Order Status} segmentationEnabled{Segmentation} dynamicPricingEnabled{Dynamic Pricing} nutritionEnabled{Nutrition} recurrenceEnabled{Recurring Orders} languageEnabled{Multi-language} supportEnabled{Support} trackOrderEnabled{Order Tracking} enableGuestMode{Guest Mode} enableDemoMode{Demo Mode} forceLogin{Force Login} googleAuthEnabled{Google Auth} facebookAuthEnabled{Facebook Auth} appleAuthEnabled{Apple Auth} phoneAuthEnabled{Phone Auth} adminDashboardEnabled{Admin Dashboard} bannerPromoManagementEnabled{Banner & Promo Management} feedbackManagementEnabled{Feedback Management} analyticsDashboardEnabled{Analytics Dashboard} staffAccessEnabled{Staff Access} featureToggleUIEnabled{Feature Toggle UI} chatManagementEnabled{Chat Management} promoBulkUploadEnabled{Promo Bulk Upload} promoExportEnabled{Promo Export} analyticsExportEnabled{Analytics Export} other{{key}}}'**
  String featureDisplayName(String key);

  /// No description provided for @signInToOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add items to your cart.'**
  String get signInToOrderMessage;

  /// No description provided for @cartAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item to cart. Please try again.'**
  String get cartAddError;

  /// No description provided for @includedToppings.
  ///
  /// In en, this message translates to:
  /// **'Included: '**
  String get includedToppings;

  /// No description provided for @whole.
  ///
  /// In en, this message translates to:
  /// **'Whole'**
  String get whole;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @doubleTopping.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get doubleTopping;

  /// No description provided for @firstNFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'First N Free'**
  String get firstNFreeLabel;

  /// No description provided for @firstNFree.
  ///
  /// In en, this message translates to:
  /// **'First N Free'**
  String get firstNFree;

  /// No description provided for @groupUpcharge.
  ///
  /// In en, this message translates to:
  /// **'Group Upcharge'**
  String get groupUpcharge;

  /// No description provided for @groupTag.
  ///
  /// In en, this message translates to:
  /// **'Group Tag'**
  String get groupTag;

  /// No description provided for @allowExtra.
  ///
  /// In en, this message translates to:
  /// **'Allow Extra'**
  String get allowExtra;

  /// No description provided for @allowSide.
  ///
  /// In en, this message translates to:
  /// **'Allow Side'**
  String get allowSide;

  /// No description provided for @upchargePerSize.
  ///
  /// In en, this message translates to:
  /// **'Upcharge Per Size'**
  String get upchargePerSize;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @portion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portion;

  /// No description provided for @cannotBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Cannot be removed'**
  String get cannotBeRemoved;

  /// No description provided for @optionalAddOnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional Add-Ons'**
  String get optionalAddOnsLabel;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @itemsInCartCouldContain.
  ///
  /// In en, this message translates to:
  /// **'Items in cart could contain the following allergens: {allergens}'**
  String itemsInCartCouldContain(Object allergens);

  /// No description provided for @leftSide.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get leftSide;

  /// No description provided for @rightSide.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get rightSide;

  /// No description provided for @currentIngredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Ingredients'**
  String get currentIngredientsLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @sizeLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Select the size for your item'**
  String get sizeLabelHint;

  /// No description provided for @additionalToppingCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional topping cost:'**
  String get additionalToppingCostLabel;

  /// No description provided for @chooseFlavorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Flavors'**
  String get chooseFlavorsLabel;

  /// No description provided for @ingredientRemovedLabel.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get ingredientRemovedLabel;

  /// No description provided for @notImplemented.
  ///
  /// In en, this message translates to:
  /// **'This feature is not yet implemented.'**
  String get notImplemented;

  /// No description provided for @noPromotionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No promotions are currently available.'**
  String get noPromotionsAvailable;

  /// No description provided for @pleaseSignInToAccessProfile.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access your profile.'**
  String get pleaseSignInToAccessProfile;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @couldNotRetrieveProfile.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t retrieve your profile data.'**
  String get couldNotRetrieveProfile;

  /// No description provided for @signOutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmationMessage;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone Number'**
  String get editPhoneNumber;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized — You do not have permission to access this page.'**
  String get unauthorizedMessage;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnHome;

  /// No description provided for @colColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get colColumns;

  /// No description provided for @importCSV.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCSV;

  /// No description provided for @showDeleted.
  ///
  /// In en, this message translates to:
  /// **'Show Deleted'**
  String get showDeleted;

  /// No description provided for @exportCSV.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCSV;

  /// No description provided for @resetTemplate.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTemplate;

  /// No description provided for @importCSVPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'File picker not implemented yet.'**
  String get importCSVPlaceholder;

  /// No description provided for @unauthorizedDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action. This attempt has been logged.'**
  String get unauthorizedDialogMessage;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV download completed.'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to download CSV.'**
  String get exportError;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Failed to share file.'**
  String get shareError;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @addMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Menu Item'**
  String get addMenuItem;

  /// No description provided for @lockedCustomizationGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'This customization group is enforced by your restaurant’s menu template.'**
  String get lockedCustomizationGroupTooltip;

  /// No description provided for @requiredCustomizationGroupMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing required group: {groupLabel}'**
  String requiredCustomizationGroupMissing(Object groupLabel);

  /// No description provided for @templateCustomizationResolved.
  ///
  /// In en, this message translates to:
  /// **'Customization group loaded from template.'**
  String get templateCustomizationResolved;

  /// No description provided for @customizationGroupLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked Group'**
  String get customizationGroupLocked;

  /// No description provided for @customizationTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'This group follows a preset customization template.'**
  String get customizationTemplateHint;

  /// No description provided for @sauces.
  ///
  /// In en, this message translates to:
  /// **'Sauces'**
  String get sauces;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @pleaseSelectBothHalves.
  ///
  /// In en, this message translates to:
  /// **'Please select both halves or none!'**
  String get pleaseSelectBothHalves;

  /// No description provided for @orderingFeedbackPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your ordering experience?'**
  String get orderingFeedbackPromptTitle;

  /// No description provided for @orderingFeedbackInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the app, checkout, or anything confusing or helpful!'**
  String get orderingFeedbackInstructions;

  /// No description provided for @categoryEaseOfUse.
  ///
  /// In en, this message translates to:
  /// **'Ease of use'**
  String get categoryEaseOfUse;

  /// No description provided for @categoryCheckoutProcess.
  ///
  /// In en, this message translates to:
  /// **'Checkout process'**
  String get categoryCheckoutProcess;

  /// No description provided for @categoryFindingItems.
  ///
  /// In en, this message translates to:
  /// **'Finding items'**
  String get categoryFindingItems;

  /// No description provided for @categoryPaymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment options'**
  String get categoryPaymentOptions;

  /// No description provided for @feedbackAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted – thank you!'**
  String get feedbackAlreadySubmitted;

  /// No description provided for @feedbackAlreadySubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted'**
  String get feedbackAlreadySubmittedTitle;

  /// No description provided for @feedbackAlreadySubmittedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get feedbackAlreadySubmittedSubtitle;

  /// No description provided for @feedbackManagement.
  ///
  /// In en, this message translates to:
  /// **'Feedback Management'**
  String get feedbackManagement;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @filterAppFeedback.
  ///
  /// In en, this message translates to:
  /// **'App Feedback'**
  String get filterAppFeedback;

  /// No description provided for @filterOrderFeedback.
  ///
  /// In en, this message translates to:
  /// **'Order Feedback'**
  String get filterOrderFeedback;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get sortRecent;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest Rating'**
  String get sortLowest;

  /// No description provided for @sortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest Rating'**
  String get sortHighest;

  /// No description provided for @searchFeedback.
  ///
  /// In en, this message translates to:
  /// **'Search feedback…'**
  String get searchFeedback;

  /// No description provided for @noFeedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No feedback submitted yet.'**
  String get noFeedbackSubmitted;

  /// No description provided for @deleteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback'**
  String get deleteFeedback;

  /// No description provided for @deleteFeedbackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback?'**
  String get deleteFeedbackConfirm;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get noMessage;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @feedbackAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get feedbackAnonymous;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Title for franchise selector screen
  ///
  /// In en, this message translates to:
  /// **'Switch Restaurant'**
  String get switchRestaurant;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
