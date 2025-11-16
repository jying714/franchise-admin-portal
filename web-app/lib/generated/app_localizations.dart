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
  /// **'Forgot password?'**
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
  /// **'Nutrition'**
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
  /// **'Password required (min 6 chars)'**
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
  /// **'Unauthorized access.'**
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

  /// No description provided for @categorySelected.
  ///
  /// In en, this message translates to:
  /// **'Category selected'**
  String get categorySelected;

  /// No description provided for @adminSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Sign-In'**
  String get adminSignInTitle;

  /// No description provided for @adminSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage orders, staff, and restaurant data.'**
  String get adminSignInDescription;

  /// No description provided for @adminOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This portal is for authorized restaurant administrators only.'**
  String get adminOnlyNotice;

  /// No description provided for @addMenuTab.
  ///
  /// In en, this message translates to:
  /// **'Add Menus'**
  String get addMenuTab;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @selectItemToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select item to edit'**
  String get selectItemToEdit;

  /// No description provided for @helpDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Help and support info goes here.'**
  String get helpDialogContent;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeModeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSettingNote.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language.'**
  String get languageSettingNote;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @chatManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Management'**
  String get chatManagementTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @unauthorizedAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorizedAccessTitle;

  /// No description provided for @unauthorizedAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page.'**
  String get unauthorizedAccessMessage;

  /// No description provided for @errorLogManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Log Management'**
  String get errorLogManagementTitle;

  /// No description provided for @toggleArchivedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show or hide archived error logs'**
  String get toggleArchivedTooltip;

  /// No description provided for @showingArchived.
  ///
  /// In en, this message translates to:
  /// **'Showing Archived'**
  String get showingArchived;

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide Archived'**
  String get hideArchived;

  /// No description provided for @resolvedFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by resolved/unresolved status'**
  String get resolvedFilterTooltip;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @unresolvedOnly.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get unresolvedOnly;

  /// No description provided for @resolvedOnly.
  ///
  /// In en, this message translates to:
  /// **'Resolved Only'**
  String get resolvedOnly;

  /// No description provided for @errorLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Logs'**
  String get errorLoadingTitle;

  /// No description provided for @errorLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'There was a problem loading error logs. Please try again.'**
  String get errorLoadingMessage;

  /// No description provided for @noErrorLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Error Logs'**
  String get noErrorLogsTitle;

  /// No description provided for @noErrorLogsMessage.
  ///
  /// In en, this message translates to:
  /// **'No error logs were found matching your filters.'**
  String get noErrorLogsMessage;

  /// No description provided for @messageTooltip.
  ///
  /// In en, this message translates to:
  /// **'The error message'**
  String get messageTooltip;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @userIdTooltip.
  ///
  /// In en, this message translates to:
  /// **'ID of the user who experienced the error'**
  String get userIdTooltip;

  /// No description provided for @resolvedTooltip.
  ///
  /// In en, this message translates to:
  /// **'This error is marked as resolved'**
  String get resolvedTooltip;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @archivedTooltip.
  ///
  /// In en, this message translates to:
  /// **'This error is archived'**
  String get archivedTooltip;

  /// No description provided for @notArchived.
  ///
  /// In en, this message translates to:
  /// **'Not Archived'**
  String get notArchived;

  /// No description provided for @timeTooltip.
  ///
  /// In en, this message translates to:
  /// **'The time this error log was recorded'**
  String get timeTooltip;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @severityTooltip.
  ///
  /// In en, this message translates to:
  /// **'The severity level of the error'**
  String get severityTooltip;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by error source'**
  String get sourceTooltip;

  /// No description provided for @screen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screen;

  /// No description provided for @screenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by screen name'**
  String get screenTooltip;

  /// No description provided for @errorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Details'**
  String get errorDetailsTitle;

  /// No description provided for @stackTraceSection.
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get stackTraceSection;

  /// No description provided for @contextDataSection.
  ///
  /// In en, this message translates to:
  /// **'Context Data'**
  String get contextDataSection;

  /// No description provided for @deviceInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfoSection;

  /// No description provided for @commentsSection.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsSection;

  /// No description provided for @unresolvedTooltip.
  ///
  /// In en, this message translates to:
  /// **'This error is not resolved'**
  String get unresolvedTooltip;

  /// No description provided for @notArchivedTooltip.
  ///
  /// In en, this message translates to:
  /// **'This error is not archived'**
  String get notArchivedTooltip;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @addCommentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add your comment to this error log'**
  String get addCommentTooltip;

  /// No description provided for @commentAdded.
  ///
  /// In en, this message translates to:
  /// **'Comment added.'**
  String get commentAdded;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copiedJson.
  ///
  /// In en, this message translates to:
  /// **'Copied error JSON!'**
  String get copiedJson;

  /// No description provided for @copyErrorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy error details as JSON'**
  String get copyErrorTooltip;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @unresolve.
  ///
  /// In en, this message translates to:
  /// **'Unresolve'**
  String get unresolve;

  /// No description provided for @resolveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark this error as resolved'**
  String get resolveTooltip;

  /// No description provided for @unresolveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark this error as unresolved'**
  String get unresolveTooltip;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @archiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive this error log'**
  String get archiveTooltip;

  /// No description provided for @unarchiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unarchive this error log'**
  String get unarchiveTooltip;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close this dialog'**
  String get closeTooltip;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @fatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get fatal;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @dateRangeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select a date range for error logs'**
  String get dateRangeTooltip;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @clearDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get clearDateFilter;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search error log messages'**
  String get searchTooltip;

  /// No description provided for @totalErrorsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Total number of errors: {total}'**
  String totalErrorsTooltip(Object total);

  /// No description provided for @criticalErrorsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Number of critical or fatal errors: {count}'**
  String criticalErrorsTooltip(Object count);

  /// No description provided for @warningErrorsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Number of warning-level errors: {count}'**
  String warningErrorsTooltip(Object count);

  /// No description provided for @infoErrorsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Number of info-level errors: {count}'**
  String infoErrorsTooltip(Object count);

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @bulkSelection.
  ///
  /// In en, this message translates to:
  /// **'Bulk selection'**
  String get bulkSelection;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items selected} one{1 item selected} other{{count} items selected}}'**
  String selectedCount(num count);

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @failedToSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save category. Please try again.'**
  String get failedToSaveCategory;

  /// No description provided for @sortByDescription.
  ///
  /// In en, this message translates to:
  /// **'Sort by description'**
  String get sortByDescription;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Sort ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Sort descending'**
  String get sortDescending;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @failedToDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category. Please try again.'**
  String get failedToDeleteCategory;

  /// No description provided for @failedToRestoreCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore category. Please try again.'**
  String get failedToRestoreCategory;

  /// No description provided for @paidFeatureAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'This is a paid feature and can only be toggled by a developer or platform admin.'**
  String get paidFeatureAdminOnly;

  /// No description provided for @toggleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update feature toggle. Please try again.'**
  String get toggleUpdateFailed;

  /// No description provided for @featureToggleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feature toggles.'**
  String get featureToggleLoadError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @ownerTogglesSection.
  ///
  /// In en, this message translates to:
  /// **'Features You Can Control'**
  String get ownerTogglesSection;

  /// No description provided for @devOnlyTogglesSection.
  ///
  /// In en, this message translates to:
  /// **'Developer/Platform Only Features'**
  String get devOnlyTogglesSection;

  /// No description provided for @switchFranchise.
  ///
  /// In en, this message translates to:
  /// **'Switch Franchise'**
  String get switchFranchise;

  /// No description provided for @developerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Dashboard'**
  String get developerDashboardTitle;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @defaultFranchise.
  ///
  /// In en, this message translates to:
  /// **'Default Franchise'**
  String get defaultFranchise;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @futureFeatures.
  ///
  /// In en, this message translates to:
  /// **'Future Features'**
  String get futureFeatures;

  /// No description provided for @staffDirectory.
  ///
  /// In en, this message translates to:
  /// **'Staff Directory'**
  String get staffDirectory;

  /// No description provided for @errorLoadingStaff.
  ///
  /// In en, this message translates to:
  /// **'Error loading staff list.'**
  String get errorLoadingStaff;

  /// No description provided for @noStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No staff members found.'**
  String get noStaffFound;

  /// No description provided for @onboardingChecklist.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Checklist'**
  String get onboardingChecklist;

  /// No description provided for @markAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markAsComplete;

  /// No description provided for @profileCompleted.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed'**
  String get profileCompleted;

  /// No description provided for @menuUploaded.
  ///
  /// In en, this message translates to:
  /// **'Menu Uploaded'**
  String get menuUploaded;

  /// No description provided for @inventoryLoaded.
  ///
  /// In en, this message translates to:
  /// **'Inventory Loaded'**
  String get inventoryLoaded;

  /// No description provided for @staffInvited.
  ///
  /// In en, this message translates to:
  /// **'Staff Invited'**
  String get staffInvited;

  /// No description provided for @testOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Test Order Placed'**
  String get testOrderPlaced;

  /// No description provided for @errorLoadingFranchises.
  ///
  /// In en, this message translates to:
  /// **'Error loading franchises.'**
  String get errorLoadingFranchises;

  /// No description provided for @noFranchisesFound.
  ///
  /// In en, this message translates to:
  /// **'No franchises found.'**
  String get noFranchisesFound;

  /// No description provided for @loadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Loading please wait..'**
  String get loadingPleaseWait;

  /// No description provided for @failedToLoadFranchises.
  ///
  /// In en, this message translates to:
  /// **'Failed to load franchises. Please try again.'**
  String get failedToLoadFranchises;

  /// No description provided for @allFranchisesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Franchises'**
  String get allFranchisesLabel;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardErrorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard statistics.'**
  String get dashboardErrorLoadingStats;

  /// No description provided for @analyticsTrendsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Analytics Trends (Coming Soon)'**
  String get analyticsTrendsComingSoon;

  /// No description provided for @analyticsTrendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Advanced business trends, customer segmentation, and growth predictions coming soon.'**
  String get analyticsTrendsDesc;

  /// No description provided for @aiInsightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI Insights (Coming Soon)'**
  String get aiInsightsComingSoon;

  /// No description provided for @aiInsightsDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered suggestions, anomaly detection, and forecasts will appear here.'**
  String get aiInsightsDesc;

  /// No description provided for @dashboardRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get dashboardRevenue;

  /// No description provided for @dashboardOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get dashboardOrders;

  /// No description provided for @dashboardUniqueCustomers.
  ///
  /// In en, this message translates to:
  /// **'Unique Customers'**
  String get dashboardUniqueCustomers;

  /// No description provided for @dashboardTopSeller.
  ///
  /// In en, this message translates to:
  /// **'Top Seller'**
  String get dashboardTopSeller;

  /// No description provided for @dashboardAvgOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Value'**
  String get dashboardAvgOrderValue;

  /// No description provided for @dashboardAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get dashboardAppVersion;

  /// No description provided for @dashboardHealthGood.
  ///
  /// In en, this message translates to:
  /// **'System Health: Good'**
  String get dashboardHealthGood;

  /// No description provided for @dashboardHealthWarning.
  ///
  /// In en, this message translates to:
  /// **'System Health: Warning'**
  String get dashboardHealthWarning;

  /// No description provided for @dashboardHealthError.
  ///
  /// In en, this message translates to:
  /// **'System Health: Error'**
  String get dashboardHealthError;

  /// No description provided for @dashboardLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get dashboardLastSync;

  /// No description provided for @developerMetricsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Developer Metrics (Coming Soon)'**
  String get developerMetricsComingSoon;

  /// No description provided for @developerMetricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed system metrics and advanced developer tools will be shown here.'**
  String get developerMetricsDesc;

  /// No description provided for @impersonationToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'User Impersonation Tools'**
  String get impersonationToolsTitle;

  /// No description provided for @impersonationToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Search and impersonate users within this franchise for debugging and support. All actions are logged. Impersonation is only available for developer accounts.'**
  String get impersonationToolsDesc;

  /// No description provided for @impersonationToolsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user list.'**
  String get impersonationToolsLoadError;

  /// No description provided for @impersonationToolsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or role...'**
  String get impersonationToolsSearchHint;

  /// No description provided for @impersonationToolsNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found for this franchise.'**
  String get impersonationToolsNoUsersFound;

  /// No description provided for @impersonationToolsRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get impersonationToolsRoleLabel;

  /// No description provided for @impersonationToolsImpersonate.
  ///
  /// In en, this message translates to:
  /// **'Impersonate'**
  String get impersonationToolsImpersonate;

  /// No description provided for @impersonationToolsImpersonating.
  ///
  /// In en, this message translates to:
  /// **'Impersonating'**
  String get impersonationToolsImpersonating;

  /// No description provided for @impersonationToolsRecentImpersonations.
  ///
  /// In en, this message translates to:
  /// **'Recent Impersonations'**
  String get impersonationToolsRecentImpersonations;

  /// No description provided for @impersonationToolsAuditTrailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail (Coming Soon)'**
  String get impersonationToolsAuditTrailComingSoon;

  /// No description provided for @impersonationToolsAuditTrailDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed history of impersonation activity for compliance and monitoring.'**
  String get impersonationToolsAuditTrailDesc;

  /// No description provided for @impersonationToolsRolePreviewComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Role Preview (Coming Soon)'**
  String get impersonationToolsRolePreviewComingSoon;

  /// No description provided for @impersonationToolsRolePreviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Preview data access and permissions for the target user before impersonating.'**
  String get impersonationToolsRolePreviewDesc;

  /// No description provided for @errorLogsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Logs'**
  String get errorLogsSectionTitle;

  /// No description provided for @errorLogsSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Latest and most critical error logs for this franchise. Use filters to focus on specific severity levels. Switch to \'All Franchises\' to review system-wide issues.'**
  String get errorLogsSectionDesc;

  /// No description provided for @errorLogsSectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load error logs.'**
  String get errorLogsSectionError;

  /// No description provided for @errorLogsSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No error logs found for the selected filters.'**
  String get errorLogsSectionEmpty;

  /// No description provided for @errorLogsSectionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get errorLogsSectionViewAll;

  /// No description provided for @errorLogsSectionSeverityFilter.
  ///
  /// In en, this message translates to:
  /// **'Severity:'**
  String get errorLogsSectionSeverityFilter;

  /// No description provided for @errorLogsSectionFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get errorLogsSectionFilterAny;

  /// No description provided for @errorLogsSectionSeverityError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLogsSectionSeverityError;

  /// No description provided for @errorLogsSectionSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get errorLogsSectionSeverityWarning;

  /// No description provided for @errorLogsSectionSeverityFatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get errorLogsSectionSeverityFatal;

  /// No description provided for @errorLogsSectionAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get errorLogsSectionAt;

  /// No description provided for @errorLogsSectionAnalyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Error Analytics (Coming Soon)'**
  String get errorLogsSectionAnalyticsComingSoon;

  /// No description provided for @errorLogsSectionAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Visualizations, charts, and error breakdowns coming soon.'**
  String get errorLogsSectionAnalyticsDesc;

  /// No description provided for @errorLogsSectionAIInsightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI Error Insights (Coming Soon)'**
  String get errorLogsSectionAIInsightsComingSoon;

  /// No description provided for @errorLogsSectionAIInsightsDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered error clustering and root-cause suggestions are on the way.'**
  String get errorLogsSectionAIInsightsDesc;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @featureTogglesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Toggles'**
  String get featureTogglesSectionTitle;

  /// No description provided for @featureTogglesSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage feature flags for this franchise. Only enabled features will be active for staff and users. Switch to \'All Franchises\' to review defaults.'**
  String get featureTogglesSectionDesc;

  /// No description provided for @featureTogglesSectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feature toggles.'**
  String get featureTogglesSectionError;

  /// No description provided for @featureTogglesSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No feature toggles found for this franchise.'**
  String get featureTogglesSectionEmpty;

  /// No description provided for @featureTogglesSectionAuditTrailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail (Coming Soon)'**
  String get featureTogglesSectionAuditTrailComingSoon;

  /// No description provided for @featureTogglesSectionAuditTrailDesc.
  ///
  /// In en, this message translates to:
  /// **'Feature toggle change history for tracking and compliance.'**
  String get featureTogglesSectionAuditTrailDesc;

  /// No description provided for @featureTogglesSectionAIBasedComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI-based Feature Suggestions (Coming Soon)'**
  String get featureTogglesSectionAIBasedComingSoon;

  /// No description provided for @featureTogglesSectionAIBasedDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart, usage-driven suggestions for enabling features.'**
  String get featureTogglesSectionAIBasedDesc;

  /// No description provided for @featureTogglesSectionNoGlobalToggle.
  ///
  /// In en, this message translates to:
  /// **'Cannot toggle features globally. Select a franchise to enable/disable.'**
  String get featureTogglesSectionNoGlobalToggle;

  /// No description provided for @pluginRegistrySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin Registry'**
  String get pluginRegistrySectionTitle;

  /// No description provided for @pluginRegistrySectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage integrations and plugins for this franchise. Enable, disable, or troubleshoot connections. Switch to \'All Franchises\' to view system-wide status.'**
  String get pluginRegistrySectionDesc;

  /// No description provided for @pluginRegistrySectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plugin data.'**
  String get pluginRegistrySectionError;

  /// No description provided for @pluginRegistrySectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plugins registered for this franchise.'**
  String get pluginRegistrySectionEmpty;

  /// No description provided for @pluginRegistrySectionMonitoringComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Plugin Monitoring (Coming Soon)'**
  String get pluginRegistrySectionMonitoringComingSoon;

  /// No description provided for @pluginRegistrySectionMonitoringDesc.
  ///
  /// In en, this message translates to:
  /// **'Realtime plugin logs, uptime and error notifications coming soon.'**
  String get pluginRegistrySectionMonitoringDesc;

  /// No description provided for @pluginRegistrySectionMarketplaceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Plugin Marketplace (Coming Soon)'**
  String get pluginRegistrySectionMarketplaceComingSoon;

  /// No description provided for @pluginRegistrySectionMarketplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover, install, and manage new integrations from a curated plugin marketplace.'**
  String get pluginRegistrySectionMarketplaceDesc;

  /// No description provided for @pluginRegistrySectionNoGlobalToggle.
  ///
  /// In en, this message translates to:
  /// **'Cannot change plugin status globally. Select a franchise to enable/disable.'**
  String get pluginRegistrySectionNoGlobalToggle;

  /// No description provided for @pluginRegistrySectionStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get pluginRegistrySectionStatusConnected;

  /// No description provided for @pluginRegistrySectionStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get pluginRegistrySectionStatusError;

  /// No description provided for @pluginRegistrySectionStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get pluginRegistrySectionStatusDisconnected;

  /// No description provided for @pluginRegistrySectionLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get pluginRegistrySectionLastSync;

  /// No description provided for @schemaBrowserSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Schema Browser'**
  String get schemaBrowserSectionTitle;

  /// No description provided for @schemaBrowserSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse, inspect, and manage menu/category/modifier schemas for this franchise. Select a schema to see version info and details. Switch to \'All Franchises\' to review shared schemas.'**
  String get schemaBrowserSectionDesc;

  /// No description provided for @schemaBrowserSectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load schema metadata.'**
  String get schemaBrowserSectionError;

  /// No description provided for @schemaBrowserSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No schemas found for this franchise.'**
  String get schemaBrowserSectionEmpty;

  /// No description provided for @schemaBrowserSectionSchemaDetails.
  ///
  /// In en, this message translates to:
  /// **'Schema Details'**
  String get schemaBrowserSectionSchemaDetails;

  /// No description provided for @schemaBrowserSectionDetailsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Schema fields, validation state, and JSON preview will appear here.'**
  String get schemaBrowserSectionDetailsPlaceholder;

  /// No description provided for @schemaBrowserSectionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get schemaBrowserSectionStatusActive;

  /// No description provided for @schemaBrowserSectionStatusDeprecated.
  ///
  /// In en, this message translates to:
  /// **'Deprecated'**
  String get schemaBrowserSectionStatusDeprecated;

  /// No description provided for @schemaBrowserSectionDiffsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Schema Diffs (Coming Soon)'**
  String get schemaBrowserSectionDiffsComingSoon;

  /// No description provided for @schemaBrowserSectionDiffsDesc.
  ///
  /// In en, this message translates to:
  /// **'View schema diffs, compare versions, and see breaking changes across deployments.'**
  String get schemaBrowserSectionDiffsDesc;

  /// No description provided for @schemaBrowserSectionValidationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Schema Validation (Coming Soon)'**
  String get schemaBrowserSectionValidationComingSoon;

  /// No description provided for @schemaBrowserSectionValidationDesc.
  ///
  /// In en, this message translates to:
  /// **'Automated validation, problem highlighting, and quick fixes for schemas.'**
  String get schemaBrowserSectionValidationDesc;

  /// No description provided for @schemaBrowserSectionLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get schemaBrowserSectionLastUpdated;

  /// No description provided for @schemaBrowserSectionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get schemaBrowserSectionUpdated;

  /// No description provided for @auditTrailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get auditTrailSectionTitle;

  /// No description provided for @auditTrailSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Timeline of data changes (menu, franchise, settings, users). Filter by action type or user. Select \'All Franchises\' for a global view.'**
  String get auditTrailSectionDesc;

  /// No description provided for @auditTrailSectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load audit trail.'**
  String get auditTrailSectionError;

  /// No description provided for @auditTrailSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit entries found for the selected filters.'**
  String get auditTrailSectionEmpty;

  /// No description provided for @auditTrailSectionTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get auditTrailSectionTypeFilter;

  /// No description provided for @auditTrailSectionActorFilter.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get auditTrailSectionActorFilter;

  /// No description provided for @auditTrailSectionFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get auditTrailSectionFilterAny;

  /// No description provided for @auditTrailSectionAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get auditTrailSectionAt;

  /// No description provided for @auditTrailSectionBy.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get auditTrailSectionBy;

  /// No description provided for @auditTrailSectionRevertComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Revert/Restore (Coming Soon)'**
  String get auditTrailSectionRevertComingSoon;

  /// No description provided for @auditTrailSectionRevertDesc.
  ///
  /// In en, this message translates to:
  /// **'Quickly undo changes or restore previous data states from the audit trail.'**
  String get auditTrailSectionRevertDesc;

  /// No description provided for @auditTrailSectionExplainComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Explain (Coming Soon)'**
  String get auditTrailSectionExplainComingSoon;

  /// No description provided for @auditTrailSectionExplainDesc.
  ///
  /// In en, this message translates to:
  /// **'Explain audit entries, highlight risks, and use AI for impact analysis.'**
  String get auditTrailSectionExplainDesc;

  /// No description provided for @developerErrorLogsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Error Logs'**
  String get developerErrorLogsScreenTitle;

  /// No description provided for @developerErrorLogsScreenError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load error logs.'**
  String get developerErrorLogsScreenError;

  /// No description provided for @developerErrorLogsScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No error logs match the current filters.'**
  String get developerErrorLogsScreenEmpty;

  /// No description provided for @developerErrorLogsScreenFranchise.
  ///
  /// In en, this message translates to:
  /// **'Franchise'**
  String get developerErrorLogsScreenFranchise;

  /// No description provided for @developerErrorLogsScreenSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get developerErrorLogsScreenSeverity;

  /// No description provided for @developerErrorLogsScreenUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get developerErrorLogsScreenUser;

  /// No description provided for @developerErrorLogsScreenDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get developerErrorLogsScreenDevice;

  /// No description provided for @developerErrorLogsScreenAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get developerErrorLogsScreenAt;

  /// No description provided for @developerErrorLogsScreenStackTrace.
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get developerErrorLogsScreenStackTrace;

  /// No description provided for @developerErrorLogsScreenFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get developerErrorLogsScreenFilterAny;

  /// No description provided for @developerErrorLogsScreenDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get developerErrorLogsScreenDateRange;

  /// No description provided for @developerErrorLogsScreenAllDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get developerErrorLogsScreenAllDates;

  /// No description provided for @developerErrorLogsScreenTrendsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Trends & Analytics (Coming Soon)'**
  String get developerErrorLogsScreenTrendsComingSoon;

  /// No description provided for @developerErrorLogsScreenTrendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Error type trends, top failing screens, and system anomaly detection.'**
  String get developerErrorLogsScreenTrendsDesc;

  /// No description provided for @developerErrorLogsScreenAIInsightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI Root Cause Analysis (Coming Soon)'**
  String get developerErrorLogsScreenAIInsightsComingSoon;

  /// No description provided for @developerErrorLogsScreenAIInsightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Cluster similar errors, get likely causes and suggestions powered by AI.'**
  String get developerErrorLogsScreenAIInsightsDesc;

  /// No description provided for @adminErrorLogsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Logs'**
  String get adminErrorLogsScreenTitle;

  /// No description provided for @adminErrorLogsScreenError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load error logs.'**
  String get adminErrorLogsScreenError;

  /// No description provided for @adminErrorLogsScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No error logs for your location in the selected date range.'**
  String get adminErrorLogsScreenEmpty;

  /// No description provided for @adminErrorLogsScreenSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get adminErrorLogsScreenSeverity;

  /// No description provided for @adminErrorLogsScreenAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get adminErrorLogsScreenAt;

  /// No description provided for @adminErrorLogsScreenDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get adminErrorLogsScreenDateRange;

  /// No description provided for @adminErrorLogsScreenAllDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get adminErrorLogsScreenAllDates;

  /// No description provided for @adminErrorLogsScreenFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get adminErrorLogsScreenFilterAny;

  /// No description provided for @adminErrorLogsScreenSupportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Support Actions (Coming Soon)'**
  String get adminErrorLogsScreenSupportComingSoon;

  /// No description provided for @adminErrorLogsScreenSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Contact support, mark as resolved, or escalate issues directly from this screen.'**
  String get adminErrorLogsScreenSupportDesc;

  /// No description provided for @adminErrorLogsScreenTrendsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Trends & Patterns (Coming Soon)'**
  String get adminErrorLogsScreenTrendsComingSoon;

  /// No description provided for @adminErrorLogsScreenTrendsDesc.
  ///
  /// In en, this message translates to:
  /// **'See frequent issues, system health, and actionable tips to reduce problems.'**
  String get adminErrorLogsScreenTrendsDesc;

  /// No description provided for @impersonationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Impersonate User'**
  String get impersonationDialogTitle;

  /// No description provided for @impersonationDialogButton.
  ///
  /// In en, this message translates to:
  /// **'Impersonate'**
  String get impersonationDialogButton;

  /// No description provided for @impersonationDialogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or name...'**
  String get impersonationDialogSearchHint;

  /// No description provided for @impersonationDialogSelectUserFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a user to impersonate.'**
  String get impersonationDialogSelectUserFirst;

  /// No description provided for @impersonationDialogSuccessPrefix.
  ///
  /// In en, this message translates to:
  /// **'Now impersonating'**
  String get impersonationDialogSuccessPrefix;

  /// No description provided for @impersonationDialogError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users.'**
  String get impersonationDialogError;

  /// No description provided for @impersonationDialogNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get impersonationDialogNoUsersFound;

  /// No description provided for @impersonationDialogSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'You are about to impersonate another user. All actions will be logged and audited. Do not share sensitive or personal customer data. Exiting impersonation restores your own access and context.'**
  String get impersonationDialogSecurityNotice;

  /// No description provided for @impersonationDialogAuditTrailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail (Coming Soon)'**
  String get impersonationDialogAuditTrailComingSoon;

  /// No description provided for @impersonationDialogAuditTrailDesc.
  ///
  /// In en, this message translates to:
  /// **'View impersonation history, export logs, and enforce audit controls.'**
  String get impersonationDialogAuditTrailDesc;

  /// No description provided for @impersonationDialogAdvancedToolsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Advanced Tools (Coming Soon)'**
  String get impersonationDialogAdvancedToolsComingSoon;

  /// No description provided for @impersonationDialogAdvancedToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Session timeouts, role-limited impersonation, and support diagnostics.'**
  String get impersonationDialogAdvancedToolsDesc;

  /// No description provided for @closeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButtonLabel;

  /// No description provided for @pluginConfigDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin Config'**
  String get pluginConfigDialogTitle;

  /// No description provided for @pluginConfigDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'View and update configuration for this plugin. Changes will take effect immediately.'**
  String get pluginConfigDialogDesc;

  /// No description provided for @pluginConfigDialogError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load or save plugin configuration.'**
  String get pluginConfigDialogError;

  /// No description provided for @pluginConfigDialogNoFields.
  ///
  /// In en, this message translates to:
  /// **'This plugin has no configurable fields.'**
  String get pluginConfigDialogNoFields;

  /// No description provided for @pluginConfigDialogSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pluginConfigDialogSaveButton;

  /// No description provided for @pluginConfigDialogSaved.
  ///
  /// In en, this message translates to:
  /// **'Plugin configuration saved.'**
  String get pluginConfigDialogSaved;

  /// No description provided for @pluginConfigDialogHistoryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'History (Coming Soon)'**
  String get pluginConfigDialogHistoryComingSoon;

  /// No description provided for @pluginConfigDialogHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'View and restore previous configuration states.'**
  String get pluginConfigDialogHistoryDesc;

  /// No description provided for @pluginConfigDialogValidationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Validation & Test (Coming Soon)'**
  String get pluginConfigDialogValidationComingSoon;

  /// No description provided for @pluginConfigDialogValidationDesc.
  ///
  /// In en, this message translates to:
  /// **'Run plugin-specific validation, test API keys, and get troubleshooting help.'**
  String get pluginConfigDialogValidationDesc;

  /// No description provided for @cancelButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// No description provided for @pluginRegistrySectionConfigureButton.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get pluginRegistrySectionConfigureButton;

  /// No description provided for @ownerHQDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'HQ Owner Dashboard'**
  String get ownerHQDashboardTitle;

  /// No description provided for @franchiseFinancials.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get franchiseFinancials;

  /// No description provided for @multiBrandSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Multi-Brand Overview'**
  String get multiBrandSnapshot;

  /// No description provided for @franchiseAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get franchiseAlerts;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @comingSoonFeatures.
  ///
  /// In en, this message translates to:
  /// **'Future Features'**
  String get comingSoonFeatures;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @pendingRoyalties.
  ///
  /// In en, this message translates to:
  /// **'Pending Royalties'**
  String get pendingRoyalties;

  /// No description provided for @activeStores.
  ///
  /// In en, this message translates to:
  /// **'Stores Reporting'**
  String get activeStores;

  /// No description provided for @overdueFees.
  ///
  /// In en, this message translates to:
  /// **'Overdue Fees'**
  String get overdueFees;

  /// No description provided for @outstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Invoices'**
  String get outstandingInvoices;

  /// No description provided for @openInvoices.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openInvoices;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @viewInvoices.
  ///
  /// In en, this message translates to:
  /// **'View All Invoices'**
  String get viewInvoices;

  /// No description provided for @payoutStatus.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payoutStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @viewPayouts.
  ///
  /// In en, this message translates to:
  /// **'View All Payouts'**
  String get viewPayouts;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get locations;

  /// No description provided for @noBrands.
  ///
  /// In en, this message translates to:
  /// **'No additional brands linked.'**
  String get noBrands;

  /// No description provided for @switchBrand.
  ///
  /// In en, this message translates to:
  /// **'Switch Brand'**
  String get switchBrand;

  /// No description provided for @overduePaymentAlert.
  ///
  /// In en, this message translates to:
  /// **'Overdue franchise payment: Store #101'**
  String get overduePaymentAlert;

  /// No description provided for @complianceAlert.
  ///
  /// In en, this message translates to:
  /// **'Compliance document missing: W-9 required'**
  String get complianceAlert;

  /// No description provided for @storePausedAlert.
  ///
  /// In en, this message translates to:
  /// **'Store #104 is paused for the season'**
  String get storePausedAlert;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts.'**
  String get noAlerts;

  /// No description provided for @alertHistory.
  ///
  /// In en, this message translates to:
  /// **'View Alert History'**
  String get alertHistory;

  /// No description provided for @bankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get bankAccounts;

  /// No description provided for @reporting.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reporting;

  /// No description provided for @billingSupport.
  ///
  /// In en, this message translates to:
  /// **'Billing Support'**
  String get billingSupport;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'HQ Announcements'**
  String get announcements;

  /// No description provided for @announcementsDesc.
  ///
  /// In en, this message translates to:
  /// **'Coming soon: Company-wide bulletins and major updates.'**
  String get announcementsDesc;

  /// No description provided for @taxDocs.
  ///
  /// In en, this message translates to:
  /// **'1099/W-9 Export'**
  String get taxDocs;

  /// No description provided for @taxDocsDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate and export annual payout tax forms for all franchisees.'**
  String get taxDocsDesc;

  /// No description provided for @multiCurrency.
  ///
  /// In en, this message translates to:
  /// **'Multi-Currency'**
  String get multiCurrency;

  /// No description provided for @multiCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable international/multi-currency payment support.'**
  String get multiCurrencyDesc;

  /// No description provided for @bulkOps.
  ///
  /// In en, this message translates to:
  /// **'Bulk Operations'**
  String get bulkOps;

  /// No description provided for @bulkOpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Send invoices, set fees, or pause multiple stores at once.'**
  String get bulkOpsDesc;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Accounting/API Integrations'**
  String get integrations;

  /// No description provided for @integrationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with QuickBooks, Xero, Sage, and more.'**
  String get integrationsDesc;

  /// No description provided for @scheduledReports.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Reports'**
  String get scheduledReports;

  /// No description provided for @scheduledReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule, download, or auto-email custom finance reports.'**
  String get scheduledReportsDesc;

  /// No description provided for @kpiFinancials.
  ///
  /// In en, this message translates to:
  /// **'Financial KPIs'**
  String get kpiFinancials;

  /// No description provided for @kpiRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get kpiRevenue;

  /// No description provided for @kpiOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get kpiOutstanding;

  /// No description provided for @kpiLastPayout.
  ///
  /// In en, this message translates to:
  /// **'Last Payout'**
  String get kpiLastPayout;

  /// No description provided for @kpiAvgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order'**
  String get kpiAvgOrder;

  /// No description provided for @kpiPayoutDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get kpiPayoutDate;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} (coming soon)'**
  String featureComingSoon(Object feature);

  /// No description provided for @errorLoadingKpi.
  ///
  /// In en, this message translates to:
  /// **'Failed to load KPIs.'**
  String get errorLoadingKpi;

  /// No description provided for @errorLoadingSection.
  ///
  /// In en, this message translates to:
  /// **'Error loading section'**
  String get errorLoadingSection;

  /// No description provided for @featureComingSoonCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow Forecast (coming soon)'**
  String get featureComingSoonCashFlow;

  /// No description provided for @featureComingSoonRevenueTrends.
  ///
  /// In en, this message translates to:
  /// **'Per-Location Revenue Trends (coming soon)'**
  String get featureComingSoonRevenueTrends;

  /// No description provided for @noFranchisesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Franchises Available.'**
  String get noFranchisesAvailable;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @projectedInflow.
  ///
  /// In en, this message translates to:
  /// **'Projected Inflow'**
  String get projectedInflow;

  /// No description provided for @projectedOutflow.
  ///
  /// In en, this message translates to:
  /// **'Projected Outflow'**
  String get projectedOutflow;

  /// No description provided for @projectedClosing.
  ///
  /// In en, this message translates to:
  /// **'Projected Closing'**
  String get projectedClosing;

  /// No description provided for @appLandingHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'All-in-One Franchise & Restaurant Management'**
  String get appLandingHeroHeadline;

  /// No description provided for @appLandingHeroSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Mobile Ordering, Customization, Analytics, and Powerful Admin Tools for Modern Franchises.'**
  String get appLandingHeroSubheadline;

  /// No description provided for @appLandingAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Doughboys Franchise Admin Portal'**
  String get appLandingAboutTitle;

  /// No description provided for @appLandingAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Doughboys Pizzeria empowers franchises with a unified platform for online ordering, menu management, analytics, inventory, staff management, and more.'**
  String get appLandingAboutBody;

  /// No description provided for @appLandingFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get appLandingFeaturesTitle;

  /// No description provided for @featureMobileOrdering.
  ///
  /// In en, this message translates to:
  /// **'Mobile Ordering for Customers'**
  String get featureMobileOrdering;

  /// No description provided for @featureFranchiseManagement.
  ///
  /// In en, this message translates to:
  /// **'Franchise Management for Owners and Admins'**
  String get featureFranchiseManagement;

  /// No description provided for @featureCustomMenus.
  ///
  /// In en, this message translates to:
  /// **'Customizable Menus & Ingredients'**
  String get featureCustomMenus;

  /// No description provided for @featureFinancialTools.
  ///
  /// In en, this message translates to:
  /// **'Financial & Inventory Tools'**
  String get featureFinancialTools;

  /// No description provided for @featureRoleBasedAccess.
  ///
  /// In en, this message translates to:
  /// **'Role-Based Secure Access'**
  String get featureRoleBasedAccess;

  /// No description provided for @featureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Detailed Analytics & Insights'**
  String get featureAnalytics;

  /// No description provided for @featureSupportTools.
  ///
  /// In en, this message translates to:
  /// **'Integrated Support & Feedback Tools'**
  String get featureSupportTools;

  /// No description provided for @appLandingGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshots & Gallery'**
  String get appLandingGalleryTitle;

  /// No description provided for @appLandingDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'See It In Action'**
  String get appLandingDemoTitle;

  /// No description provided for @appLandingDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch a quick walkthrough of our app.'**
  String get appLandingDemoSubtitle;

  /// No description provided for @bookDemo.
  ///
  /// In en, this message translates to:
  /// **'Book a Demo'**
  String get bookDemo;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @videoDemoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Demo Video Coming Soon'**
  String get videoDemoPlaceholder;

  /// No description provided for @watchDemo.
  ///
  /// In en, this message translates to:
  /// **'Watch Demo'**
  String get watchDemo;

  /// No description provided for @devPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Panel'**
  String get devPanelTitle;

  /// No description provided for @devPanelDesc.
  ///
  /// In en, this message translates to:
  /// **'Developer-only tools and debug information.'**
  String get devPanelDesc;

  /// No description provided for @devPanelFeatureToggles.
  ///
  /// In en, this message translates to:
  /// **'Feature Toggles'**
  String get devPanelFeatureToggles;

  /// No description provided for @futureFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Future Features'**
  String get futureFeaturesTitle;

  /// No description provided for @futureFeaturesBody.
  ///
  /// In en, this message translates to:
  /// **'More advanced controls for platform owners coming soon.'**
  String get futureFeaturesBody;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @noValidRoleFound.
  ///
  /// In en, this message translates to:
  /// **'No valid role found for your account. Please contact support.'**
  String get noValidRoleFound;

  /// No description provided for @claimsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh your access permissions. Please try again or contact support.'**
  String get claimsRefreshFailed;

  /// No description provided for @profileLoadTimeout.
  ///
  /// In en, this message translates to:
  /// **'Profile loading timed out.'**
  String get profileLoadTimeout;

  /// No description provided for @tryAgainOrContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Please try again or contact support if the issue persists.'**
  String get tryAgainOrContactSupport;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your profile.'**
  String get profileLoadFailed;

  /// No description provided for @syncingRolesPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Syncing your access permissions, please wait...'**
  String get syncingRolesPleaseWait;

  /// No description provided for @redirectingToDeveloperDashboard.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to developer dashboard...'**
  String get redirectingToDeveloperDashboard;

  /// No description provided for @redirecting.
  ///
  /// In en, this message translates to:
  /// **'Redirecting...'**
  String get redirecting;

  /// No description provided for @loadingProfileAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile and permissions...'**
  String get loadingProfileAndPermissions;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get developerMode;

  /// No description provided for @forceClaimsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Force Claims Refresh'**
  String get forceClaimsRefresh;

  /// No description provided for @redirectingToOwnerHQDashboard.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to HQ Dashboard'**
  String get redirectingToOwnerHQDashboard;

  /// No description provided for @selectFranchiseToManage.
  ///
  /// In en, this message translates to:
  /// **'Select Franchise To Manage'**
  String get selectFranchiseToManage;

  /// No description provided for @dashboard_active_alerts.
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get dashboard_active_alerts;

  /// No description provided for @dashboard_alerts_filter_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter alerts (coming soon)'**
  String get dashboard_alerts_filter_tooltip;

  /// No description provided for @dashboard_alerts_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load alerts.'**
  String get dashboard_alerts_error;

  /// No description provided for @dashboard_no_active_alerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get dashboard_no_active_alerts;

  /// No description provided for @dashboard_see_all_alerts.
  ///
  /// In en, this message translates to:
  /// **'See all alerts'**
  String get dashboard_see_all_alerts;

  /// No description provided for @unauthorized_title.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get unauthorized_title;

  /// No description provided for @unauthorized_default_reason.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this section.'**
  String get unauthorized_default_reason;

  /// No description provided for @alert_dismissed_success.
  ///
  /// In en, this message translates to:
  /// **'Alert dismissed.'**
  String get alert_dismissed_success;

  /// No description provided for @alert_dismissed_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to dismiss alert.'**
  String get alert_dismissed_error;

  /// No description provided for @alert_dismiss_button.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get alert_dismiss_button;

  /// No description provided for @alert_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get alert_time;

  /// No description provided for @alert_dismissed_on.
  ///
  /// In en, this message translates to:
  /// **'Dismissed On'**
  String get alert_dismissed_on;

  /// No description provided for @alert_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get alert_type;

  /// No description provided for @alert_type_generic.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get alert_type_generic;

  /// No description provided for @alert_custom_fields.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get alert_custom_fields;

  /// No description provided for @menuItemId.
  ///
  /// In en, this message translates to:
  /// **'Menu Item ID'**
  String get menuItemId;

  /// No description provided for @menuItemName.
  ///
  /// In en, this message translates to:
  /// **'Menu Item Name'**
  String get menuItemName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryId.
  ///
  /// In en, this message translates to:
  /// **'Category ID'**
  String get categoryId;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @taxCategory.
  ///
  /// In en, this message translates to:
  /// **'Tax Category'**
  String get taxCategory;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @dietaryTags.
  ///
  /// In en, this message translates to:
  /// **'Dietary Tags'**
  String get dietaryTags;

  /// No description provided for @allergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// No description provided for @prepTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time'**
  String get prepTime;

  /// No description provided for @customizationGroups.
  ///
  /// In en, this message translates to:
  /// **'Customization Groups'**
  String get customizationGroups;

  /// No description provided for @auditLogId.
  ///
  /// In en, this message translates to:
  /// **'Audit Log ID'**
  String get auditLogId;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @promoId.
  ///
  /// In en, this message translates to:
  /// **'Promo ID'**
  String get promoId;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @applicableItems.
  ///
  /// In en, this message translates to:
  /// **'Applicable Items'**
  String get applicableItems;

  /// No description provided for @maxUses.
  ///
  /// In en, this message translates to:
  /// **'Max Uses'**
  String get maxUses;

  /// No description provided for @maxUsesType.
  ///
  /// In en, this message translates to:
  /// **'Max Uses Type'**
  String get maxUsesType;

  /// No description provided for @minOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Value'**
  String get minOrderValue;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @segment.
  ///
  /// In en, this message translates to:
  /// **'Segment'**
  String get segment;

  /// No description provided for @timeRules.
  ///
  /// In en, this message translates to:
  /// **'Time Rules'**
  String get timeRules;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @averageOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Average Order Value'**
  String get averageOrderValue;

  /// No description provided for @mostPopularItem.
  ///
  /// In en, this message translates to:
  /// **'Most Popular Item'**
  String get mostPopularItem;

  /// No description provided for @retention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get retention;

  /// No description provided for @uniqueCustomers.
  ///
  /// In en, this message translates to:
  /// **'Unique Customers'**
  String get uniqueCustomers;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Orders'**
  String get cancelledOrders;

  /// No description provided for @addOnRevenue.
  ///
  /// In en, this message translates to:
  /// **'Add-on Revenue'**
  String get addOnRevenue;

  /// No description provided for @toppingCounts.
  ///
  /// In en, this message translates to:
  /// **'Topping Counts'**
  String get toppingCounts;

  /// No description provided for @comboCounts.
  ///
  /// In en, this message translates to:
  /// **'Combo Counts'**
  String get comboCounts;

  /// No description provided for @addOnCounts.
  ///
  /// In en, this message translates to:
  /// **'Add-on Counts'**
  String get addOnCounts;

  /// No description provided for @orderStatusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Order Status Breakdown'**
  String get orderStatusBreakdown;

  /// No description provided for @franchiseId.
  ///
  /// In en, this message translates to:
  /// **'Franchise ID'**
  String get franchiseId;

  /// No description provided for @noFranchiseSelected.
  ///
  /// In en, this message translates to:
  /// **'No franchise selected.'**
  String get noFranchiseSelected;

  /// No description provided for @invoiceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoiceListTitle;

  /// No description provided for @searchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Search invoices'**
  String get searchInvoices;

  /// No description provided for @errorLoadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Error loading invoices.'**
  String get errorLoadingInvoices;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found.'**
  String get noInvoicesFound;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No Invoices'**
  String get noInvoices;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @errorLoadingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Error loading invoice.'**
  String get errorLoadingInvoice;

  /// No description provided for @invoiceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found.'**
  String get invoiceNotFound;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @noLineItems.
  ///
  /// In en, this message translates to:
  /// **'No line items available.'**
  String get noLineItems;

  /// No description provided for @lineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get lineItems;

  /// No description provided for @totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totals;

  /// No description provided for @noAuditTrail.
  ///
  /// In en, this message translates to:
  /// **'No audit trail available.'**
  String get noAuditTrail;

  /// No description provided for @auditTrail.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get auditTrail;

  /// No description provided for @noSupportNotes.
  ///
  /// In en, this message translates to:
  /// **'No support notes available.'**
  String get noSupportNotes;

  /// No description provided for @supportNotes.
  ///
  /// In en, this message translates to:
  /// **'Support Notes'**
  String get supportNotes;

  /// No description provided for @viewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get viewed;

  /// No description provided for @exportInvoices.
  ///
  /// In en, this message translates to:
  /// **'Export Invoices'**
  String get exportInvoices;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **'By user'**
  String get byUser;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get eventCreated;

  /// No description provided for @eventSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get eventSent;

  /// No description provided for @eventViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get eventViewed;

  /// No description provided for @eventPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get eventPaid;

  /// No description provided for @eventOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get eventOverdue;

  /// No description provided for @eventRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get eventRefunded;

  /// No description provided for @eventVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get eventVoided;

  /// No description provided for @eventFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get eventFailed;

  /// No description provided for @sortDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Date (Newest first)'**
  String get sortDateDesc;

  /// No description provided for @sortDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest first)'**
  String get sortDateAsc;

  /// No description provided for @sortTotalDesc.
  ///
  /// In en, this message translates to:
  /// **'Total (High to Low)'**
  String get sortTotalDesc;

  /// No description provided for @sortTotalAsc.
  ///
  /// In en, this message translates to:
  /// **'Total (Low to High)'**
  String get sortTotalAsc;

  /// No description provided for @actionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Action completed successfully.'**
  String get actionCompleted;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get actionFailed;

  /// No description provided for @markSelectedPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Selected as Paid'**
  String get markSelectedPaid;

  /// No description provided for @sendPaymentReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Payment Reminder'**
  String get sendPaymentReminder;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @viewAllInvoices.
  ///
  /// In en, this message translates to:
  /// **'View All Invoices'**
  String get viewAllInvoices;

  /// No description provided for @noOverdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'No Overdue Invoices'**
  String get noOverdueInvoices;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @totalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get totalInvoices;

  /// No description provided for @overdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'Overdue Invoices'**
  String get overdueInvoices;

  /// No description provided for @paidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Paid Invoices'**
  String get paidInvoices;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @lastInvoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Last Invoice Date'**
  String get lastInvoiceDate;

  /// No description provided for @billingSummary.
  ///
  /// In en, this message translates to:
  /// **'Billing Summary'**
  String get billingSummary;

  /// No description provided for @failedToLoadSummary.
  ///
  /// In en, this message translates to:
  /// **'Failed to load summary. Please try again.'**
  String get failedToLoadSummary;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @paidLastNDays.
  ///
  /// In en, this message translates to:
  /// **'Paid in last {days} days'**
  String paidLastNDays(Object days);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @downloadSummary.
  ///
  /// In en, this message translates to:
  /// **'Download Summary'**
  String get downloadSummary;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started...'**
  String get downloadStarted;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @payoutAlert.
  ///
  /// In en, this message translates to:
  /// **'Payout alert'**
  String get payoutAlert;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @sentAt.
  ///
  /// In en, this message translates to:
  /// **'Sent At'**
  String get sentAt;

  /// No description provided for @failedAt.
  ///
  /// In en, this message translates to:
  /// **'Failed At'**
  String get failedAt;

  /// No description provided for @payoutMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get payoutMethod;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get bankAccount;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @payoutId.
  ///
  /// In en, this message translates to:
  /// **'Payout ID'**
  String get payoutId;

  /// No description provided for @noPayoutsFound.
  ///
  /// In en, this message translates to:
  /// **'No payouts found.'**
  String get noPayoutsFound;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found.'**
  String get noDataFound;

  /// No description provided for @payoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payout not found.'**
  String get payoutNotFound;

  /// No description provided for @payoutDetail.
  ///
  /// In en, this message translates to:
  /// **'Payout Detail'**
  String get payoutDetail;

  /// No description provided for @failureReason.
  ///
  /// In en, this message translates to:
  /// **'Failure Reason'**
  String get failureReason;

  /// No description provided for @noAuditTrailFound.
  ///
  /// In en, this message translates to:
  /// **'No audit trail found.'**
  String get noAuditTrailFound;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get by;

  /// No description provided for @selectedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedItemsCount(Object count);

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get exportSelected;

  /// No description provided for @markAsSent.
  ///
  /// In en, this message translates to:
  /// **'Mark as sent'**
  String get markAsSent;

  /// No description provided for @markAsFailed.
  ///
  /// In en, this message translates to:
  /// **'Mark as failed'**
  String get markAsFailed;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @approveSelected.
  ///
  /// In en, this message translates to:
  /// **'Approve selected'**
  String get approveSelected;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attachFile;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @featureDeveloperOnly.
  ///
  /// In en, this message translates to:
  /// **'This feature is for developer use only.'**
  String get featureDeveloperOnly;

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addNoteHint;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotesYet;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save note.'**
  String get failedToSave;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed To Delete.'**
  String get failedToDelete;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @confirmDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Note'**
  String get confirmDeleteNote;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove Attachment'**
  String get removeAttachment;

  /// No description provided for @bulkStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bulk Success'**
  String get bulkStatusSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete Successfull'**
  String get deleteSuccess;

  /// No description provided for @resetToPending.
  ///
  /// In en, this message translates to:
  /// **'Reset Status To Pending'**
  String get resetToPending;

  /// No description provided for @searchPayoutsHint.
  ///
  /// In en, this message translates to:
  /// **'Search Payouts'**
  String get searchPayoutsHint;

  /// No description provided for @platformOwner.
  ///
  /// In en, this message translates to:
  /// **'Platform Owner'**
  String get platformOwner;

  /// No description provided for @inviteFranchiseesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Franchisees'**
  String get inviteFranchiseesTitle;

  /// No description provided for @inviteFranchisee.
  ///
  /// In en, this message translates to:
  /// **'Invite Franchisee'**
  String get inviteFranchisee;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitations;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations.'**
  String get noPendingInvitations;

  /// No description provided for @franchiseNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Franchise Network'**
  String get franchiseNetworkTitle;

  /// No description provided for @viewAllFranchises.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllFranchises;

  /// No description provided for @globalFinancialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Financials'**
  String get globalFinancialsTitle;

  /// No description provided for @noFinancialData.
  ///
  /// In en, this message translates to:
  /// **'No financial data available.'**
  String get noFinancialData;

  /// No description provided for @platformAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Analytics'**
  String get platformAnalyticsTitle;

  /// No description provided for @totalFranchises.
  ///
  /// In en, this message translates to:
  /// **'Total Franchises'**
  String get totalFranchises;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @analyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Analytics coming soon.'**
  String get analyticsComingSoon;

  /// No description provided for @platformSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get platformSettingsTitle;

  /// No description provided for @platformSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings feature coming soon.'**
  String get platformSettingsComingSoon;

  /// No description provided for @ownerAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get ownerAnnouncementsTitle;

  /// No description provided for @sendAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Send Announcement'**
  String get sendAnnouncement;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @redirectingToPlatformOwnerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Redirecting To Platform Owner Dashboard'**
  String get redirectingToPlatformOwnerDashboard;

  /// No description provided for @platformOwnerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Owner'**
  String get platformOwnerDashboardTitle;

  /// No description provided for @inviteStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get inviteStatusPending;

  /// No description provided for @inviteStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get inviteStatusSent;

  /// No description provided for @inviteStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get inviteStatusAccepted;

  /// No description provided for @inviteStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get inviteStatusRevoked;

  /// No description provided for @inviteStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inviteStatusExpired;

  /// No description provided for @revokeInvitation.
  ///
  /// In en, this message translates to:
  /// **'Revoke Invitation'**
  String get revokeInvitation;

  /// No description provided for @confirmRevokeInvitation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke this invitation?'**
  String get confirmRevokeInvitation;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @invitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked.'**
  String get invitationRevoked;

  /// No description provided for @resendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Resend Invitation'**
  String get resendInvitation;

  /// No description provided for @franchiseName.
  ///
  /// In en, this message translates to:
  /// **'Franchise Name'**
  String get franchiseName;

  /// No description provided for @franchiseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pizza Hub'**
  String get franchiseNameHint;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'{role, select,hq_owner{HQ Owner} owner{Owner} admin{Admin} manager{Manager} staff{Staff} other{User}}'**
  String roleLabel(String role);

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully!'**
  String get invitationSent;

  /// No description provided for @inviteErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation. Please try again.'**
  String get inviteErrorGeneric;

  /// No description provided for @platformKpiMrr.
  ///
  /// In en, this message translates to:
  /// **'MRR'**
  String get platformKpiMrr;

  /// No description provided for @platformKpiArr.
  ///
  /// In en, this message translates to:
  /// **'ARR'**
  String get platformKpiArr;

  /// No description provided for @platformKpiActiveFranchises.
  ///
  /// In en, this message translates to:
  /// **'Active Franchises'**
  String get platformKpiActiveFranchises;

  /// No description provided for @platformKpiRecentPayouts.
  ///
  /// In en, this message translates to:
  /// **'Recent Payouts'**
  String get platformKpiRecentPayouts;

  /// No description provided for @platformStatTotalRevenueYtd.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue (YTD)'**
  String get platformStatTotalRevenueYtd;

  /// No description provided for @platformStatSubscriptionRevenue.
  ///
  /// In en, this message translates to:
  /// **'Subscription Revenue'**
  String get platformStatSubscriptionRevenue;

  /// No description provided for @platformStatRoyaltyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Royalty Revenue'**
  String get platformStatRoyaltyRevenue;

  /// No description provided for @platformStatOverdueAmount.
  ///
  /// In en, this message translates to:
  /// **'Outstanding/Overdue'**
  String get platformStatOverdueAmount;

  /// No description provided for @platformOwnerRevenueSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Revenue Overview'**
  String get platformOwnerRevenueSummaryTitle;

  /// No description provided for @genericErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get genericErrorOccurred;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invitation.'**
  String get failedToLoadData;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorized;

  /// No description provided for @billingAndPayments.
  ///
  /// In en, this message translates to:
  /// **'Billing & Payments'**
  String get billingAndPayments;

  /// No description provided for @storeBilling.
  ///
  /// In en, this message translates to:
  /// **'Store Billing'**
  String get storeBilling;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @profileEditContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Need to update your profile? Contact support.'**
  String get profileEditContactSupport;

  /// No description provided for @platformOwnerDescription.
  ///
  /// In en, this message translates to:
  /// **'You are the platform owner. Manage platform-wide settings, billing, and analytics from the platform dashboard.'**
  String get platformOwnerDescription;

  /// No description provided for @goToPlatformAdmin.
  ///
  /// In en, this message translates to:
  /// **'Go to Platform Admin'**
  String get goToPlatformAdmin;

  /// No description provided for @noBillingRecords.
  ///
  /// In en, this message translates to:
  /// **'No billing records found.'**
  String get noBillingRecords;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @securityFeaturesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'More security features coming soon.'**
  String get securityFeaturesComingSoon;

  /// No description provided for @needHelpContact.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact support below.'**
  String get needHelpContact;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @paymentMethodManagementComing.
  ///
  /// In en, this message translates to:
  /// **'Payment method management coming soon.'**
  String get paymentMethodManagementComing;

  /// No description provided for @downloadReceiptsExportComing.
  ///
  /// In en, this message translates to:
  /// **'Download receipts/export coming soon.'**
  String get downloadReceiptsExportComing;

  /// No description provided for @upgradePlanAddOnsComing.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan and add-ons coming soon.'**
  String get upgradePlanAddOnsComing;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get acceptInvitation;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invitation not found.'**
  String get inviteNotFound;

  /// No description provided for @inviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'This invitation has been revoked.'**
  String get inviteRevoked;

  /// No description provided for @inviteAlreadyAccepted.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been accepted.'**
  String get inviteAlreadyAccepted;

  /// No description provided for @inviteWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {email}! You\'re invited to join the portal.'**
  String inviteWelcome(Object email);

  /// No description provided for @inviteForFranchise.
  ///
  /// In en, this message translates to:
  /// **'Invited for franchise: {franchiseName}'**
  String inviteForFranchise(Object franchiseName);

  /// No description provided for @inviteSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set your password to activate your account.'**
  String get inviteSetPassword;

  /// No description provided for @inviteAcceptExisting.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your account, then accept this invite.'**
  String get inviteAcceptExisting;

  /// No description provided for @inviteAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation Accepted!'**
  String get inviteAcceptedTitle;

  /// No description provided for @inviteAcceptedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your invite is now active. Continue to your dashboard.'**
  String get inviteAcceptedDesc;

  /// No description provided for @inviteAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation. Please try again.'**
  String get inviteAcceptFailed;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @signInRequiredToAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to accept this invitation.'**
  String get signInRequiredToAcceptInvite;

  /// No description provided for @loadingInvite.
  ///
  /// In en, this message translates to:
  /// **'Loading invitation data...'**
  String get loadingInvite;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @role_hq_owner.
  ///
  /// In en, this message translates to:
  /// **'HQ Owner'**
  String get role_hq_owner;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @signInWithEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmailButton;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get emailRequired;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @inviteMustSignIn.
  ///
  /// In en, this message translates to:
  /// **'Invite Must Sign In'**
  String get inviteMustSignIn;

  /// No description provided for @setupBusinessHours.
  ///
  /// In en, this message translates to:
  /// **'Setup business hours'**
  String get setupBusinessHours;

  /// No description provided for @setupBusinessHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'Your business hours are used for calculating on-duty hours. Business hours are also advertised on your Mobile App and Webpage.'**
  String get setupBusinessHoursDesc;

  /// No description provided for @openAt.
  ///
  /// In en, this message translates to:
  /// **'open at'**
  String get openAt;

  /// No description provided for @closeAt.
  ///
  /// In en, this message translates to:
  /// **'close at'**
  String get closeAt;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'[+] add more'**
  String get addMore;

  /// No description provided for @mustSetAtLeastOneInterval.
  ///
  /// In en, this message translates to:
  /// **'Set at least one business hour.'**
  String get mustSetAtLeastOneInterval;

  /// No description provided for @mustSelectDays.
  ///
  /// In en, this message translates to:
  /// **'Select days for each interval.'**
  String get mustSelectDays;

  /// No description provided for @openMustBeforeClose.
  ///
  /// In en, this message translates to:
  /// **'Open time must be before close time.'**
  String get openMustBeforeClose;

  /// No description provided for @daysOverlap.
  ///
  /// In en, this message translates to:
  /// **'Overlapping days across intervals are not allowed.'**
  String get daysOverlap;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get zip;

  /// No description provided for @businessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get businessEmail;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @taxIdEIN.
  ///
  /// In en, this message translates to:
  /// **'Tax ID (EIN)'**
  String get taxIdEIN;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get businessType;

  /// No description provided for @platformInvoices.
  ///
  /// In en, this message translates to:
  /// **'Platform Invoices'**
  String get platformInvoices;

  /// No description provided for @platformPayments.
  ///
  /// In en, this message translates to:
  /// **'Platform Payments'**
  String get platformPayments;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments found.'**
  String get noPaymentsFound;

  /// No description provided for @addPlatformPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPlatformPayment;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled For'**
  String get scheduledFor;

  /// No description provided for @executedAt.
  ///
  /// In en, this message translates to:
  /// **'Processed At'**
  String get executedAt;

  /// No description provided for @recurringRule.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringRule;

  /// No description provided for @enterPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter payment details'**
  String get enterPaymentDetails;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as completed'**
  String get paymentCompleted;

  /// No description provided for @developerOnlyFeature.
  ///
  /// In en, this message translates to:
  /// **'Developer-only feature'**
  String get developerOnlyFeature;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get statusVoided;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @splitPayment.
  ///
  /// In en, this message translates to:
  /// **'Split Payment'**
  String get splitPayment;

  /// No description provided for @payInvoice.
  ///
  /// In en, this message translates to:
  /// **'Pay Invoice'**
  String get payInvoice;

  /// No description provided for @noteDevOnlyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Placeholder – dev-only payment flow active'**
  String get noteDevOnlyPlaceholder;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Status Unpaid'**
  String get statusUnpaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Status Partial'**
  String get statusPartial;

  /// No description provided for @platformPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Plans'**
  String get platformPlansTitle;

  /// No description provided for @noPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plans are currently defined.'**
  String get noPlansAvailable;

  /// No description provided for @customPlan.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customPlan;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @featurePlanComingSoon.
  ///
  /// In en, this message translates to:
  /// **'More plan features coming soon...'**
  String get featurePlanComingSoon;

  /// No description provided for @franchiseSubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Franchise Subscriptions'**
  String get franchiseSubscriptionsTitle;

  /// No description provided for @noSubscriptionsFound.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions were found.'**
  String get noSubscriptionsFound;

  /// No description provided for @franchiseIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Franchise ID'**
  String get franchiseIdLabel;

  /// No description provided for @planIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planIdLabel;

  /// No description provided for @trialEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get trialEndsLabel;

  /// No description provided for @nextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Billing Date'**
  String get nextBillingLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscription;

  /// No description provided for @editSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get editSubscription;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @pleaseSelectAPlan.
  ///
  /// In en, this message translates to:
  /// **'Please select a plan'**
  String get pleaseSelectAPlan;

  /// No description provided for @subscriptionStatus_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionStatus_active;

  /// No description provided for @subscriptionStatus_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subscriptionStatus_paused;

  /// No description provided for @subscriptionStatus_trialing.
  ///
  /// In en, this message translates to:
  /// **'Trialing'**
  String get subscriptionStatus_trialing;

  /// No description provided for @subscriptionStatus_canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get subscriptionStatus_canceled;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Subscription?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the subscription from Firestore.'**
  String get confirmDeleteDescription;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteSubscription;

  /// No description provided for @bulkDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count} subscriptions.'**
  String bulkDeleteSuccess(Object count);

  /// No description provided for @enableBulkSelect.
  ///
  /// In en, this message translates to:
  /// **'Enable Bulk Select'**
  String get enableBulkSelect;

  /// No description provided for @translateStatus.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active{Active} paused{Paused} trialing{Trialing} canceled{Canceled} other{Unknown}}'**
  String translateStatus(String status);

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Plan'**
  String get deletePlan;

  /// No description provided for @quickLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinksLabel;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @confirmPlanSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Plan'**
  String get confirmPlanSubscriptionTitle;

  /// No description provided for @confirmPlanSubscriptionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to subscribe to this plan?'**
  String get confirmPlanSubscriptionPrompt;

  /// No description provided for @subscriptionSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Successfully subscribed to plan.'**
  String get subscriptionSuccessMessage;

  /// No description provided for @billingIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing Interval'**
  String get billingIntervalLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @selectThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Select This Plan'**
  String get selectThisPlan;

  /// No description provided for @onboardingRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You must complete onboarding to access this screen.'**
  String get onboardingRequiredBody;

  /// No description provided for @viewPlatformPlans.
  ///
  /// In en, this message translates to:
  /// **'View Platform Plans'**
  String get viewPlatformPlans;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get noActiveSubscription;

  /// No description provided for @activePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Plan'**
  String get activePlanLabel;

  /// No description provided for @subscriptionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Subscription'**
  String get subscriptionLoadError;

  /// No description provided for @priceAtSubscription.
  ///
  /// In en, this message translates to:
  /// **'Price Of Subscription'**
  String get priceAtSubscription;

  /// No description provided for @subscriptionsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Franchise Subscriptions'**
  String get subscriptionsListTitle;

  /// No description provided for @planDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get planDetails;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown Date'**
  String get unknownDate;

  /// Used to describe billing interval, e.g., 'per month', 'per year'
  ///
  /// In en, this message translates to:
  /// **'per {interval}'**
  String perLabel(Object interval);

  /// Label shown when a subscription is under a custom price quote
  ///
  /// In en, this message translates to:
  /// **'Custom Quote'**
  String get customQuote;

  /// Label for the subscription start date
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// Shown as a warning if cancelAtPeriodEnd is true
  ///
  /// In en, this message translates to:
  /// **'Plan is set to cancel at the end of this billing cycle.'**
  String get planCancelsAtPeriodEnd;

  /// Future placeholder for billing-related analytics
  ///
  /// In en, this message translates to:
  /// **'Billing insights and usage coming soon'**
  String get subscriptionBillingInsights;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmailLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @linkedUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked User ID'**
  String get linkedUserIdLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @trialEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial Ends'**
  String get trialEndLabel;

  /// No description provided for @subscriptionCreated.
  ///
  /// In en, this message translates to:
  /// **'Subscription Created'**
  String get subscriptionCreated;

  /// No description provided for @linkedInvoices.
  ///
  /// In en, this message translates to:
  /// **'Linked Invoices'**
  String get linkedInvoices;

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceNumberLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @subscriptionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Subscription analytics'**
  String get subscriptionAnalytics;

  /// No description provided for @editSubscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open subscription editor.'**
  String get editSubscriptionFailed;

  /// No description provided for @showDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetailsTooltip;

  /// No description provided for @hideDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetailsTooltip;

  /// No description provided for @subscriptionInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get subscriptionInsights;

  /// No description provided for @cancelAtPeriodEndToggle.
  ///
  /// In en, this message translates to:
  /// **'Cancel at End of Billing Cycle'**
  String get cancelAtPeriodEndToggle;

  /// No description provided for @cancelAtPeriodEndDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan will auto-cancel after the current billing cycle completes.'**
  String get cancelAtPeriodEndDescription;

  /// No description provided for @toggleLockedDueToStatus.
  ///
  /// In en, this message translates to:
  /// **'Disabled due to current subscription status'**
  String get toggleLockedDueToStatus;

  /// No description provided for @paymentOverdueWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Payment Overdue'**
  String get paymentOverdueWarning;

  /// No description provided for @invoiceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Status'**
  String get invoiceStatusLabel;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @overdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBadge;

  /// No description provided for @currentPlatformPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Current Platform Plan'**
  String get currentPlatformPlan;

  /// No description provided for @noActivePlatformPlan.
  ///
  /// In en, this message translates to:
  /// **'You\'re not subscribed to a platform plan.'**
  String get noActivePlatformPlan;

  /// No description provided for @nextBillingDate.
  ///
  /// In en, this message translates to:
  /// **'Next billing date: {date}'**
  String nextBillingDate(Object date);

  /// No description provided for @errorLoadingPlan.
  ///
  /// In en, this message translates to:
  /// **'Error loading current plan.'**
  String get errorLoadingPlan;

  /// No description provided for @mockPaymentHeader.
  ///
  /// In en, this message translates to:
  /// **'Mock Payment Details'**
  String get mockPaymentHeader;

  /// No description provided for @mockPaymentDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a test-only input form. No real charges will be made.'**
  String get mockPaymentDisclaimer;

  /// No description provided for @nameOnCard.
  ///
  /// In en, this message translates to:
  /// **'Name on Card'**
  String get nameOnCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @invalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid card number'**
  String get invalidCardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date (MM/YY)'**
  String get expiryDate;

  /// No description provided for @invalidExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid expiry date'**
  String get invalidExpiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @invalidCvv.
  ///
  /// In en, this message translates to:
  /// **'Enter a 3-digit CVV'**
  String get invalidCvv;

  /// No description provided for @validatePayment.
  ///
  /// In en, this message translates to:
  /// **'Validate Payment'**
  String get validatePayment;

  /// No description provided for @mockPaymentValidated.
  ///
  /// In en, this message translates to:
  /// **'Mock payment validated successfully.'**
  String get mockPaymentValidated;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @priceWithInterval.
  ///
  /// In en, this message translates to:
  /// **'{price} / {interval}'**
  String priceWithInterval(Object interval, Object price);

  /// No description provided for @billingInterval.
  ///
  /// In en, this message translates to:
  /// **'Billing Interval'**
  String get billingInterval;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select This Plan'**
  String get selectPlan;

  /// No description provided for @subscriptionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscription updated successfully!'**
  String get subscriptionUpdated;

  /// No description provided for @cardType.
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get cardType;

  /// No description provided for @paymentValidated.
  ///
  /// In en, this message translates to:
  /// **'Payment Validated'**
  String get paymentValidated;

  /// No description provided for @completePaymentToContinue.
  ///
  /// In en, this message translates to:
  /// **'Complete payment to continue'**
  String get completePaymentToContinue;

  /// No description provided for @selectBillingIntervalFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a billing interval first'**
  String get selectBillingIntervalFirst;

  /// No description provided for @unnamedPlan.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Plan'**
  String get unnamedPlan;

  /// No description provided for @subscriptionStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date: {date}'**
  String subscriptionStartDate(Object date);

  /// No description provided for @autoRenewLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-Renew'**
  String get autoRenewLabel;

  /// No description provided for @cancelAtPeriodEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel at Period End'**
  String get cancelAtPeriodEndLabel;

  /// No description provided for @overduePaymentWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Your subscription has an overdue invoice.'**
  String get overduePaymentWarning;

  /// No description provided for @unknownPlan.
  ///
  /// In en, this message translates to:
  /// **'Unknown Plan'**
  String get unknownPlan;

  /// No description provided for @paymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatusLabel;

  /// No description provided for @cardOnFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Card on File'**
  String get cardOnFileLabel;

  /// No description provided for @viewLastReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Last Receipt'**
  String get viewLastReceipt;

  /// No description provided for @gracePeriodEndsAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace Period Ends'**
  String get gracePeriodEndsAtLabel;

  /// No description provided for @billingEmail.
  ///
  /// In en, this message translates to:
  /// **'Billing Email'**
  String get billingEmail;

  /// No description provided for @gracePeriodWarning.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue. Grace period ends on {date}.'**
  String gracePeriodWarning(Object date);

  /// No description provided for @gracePeriodExpired.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue. Your access may be limited until resolved.'**
  String get gracePeriodExpired;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @noMatchingInvoices.
  ///
  /// In en, this message translates to:
  /// **'No matching invoices found.'**
  String get noMatchingInvoices;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @manualSubscriptionInjectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Subscription Injector'**
  String get manualSubscriptionInjectorTitle;

  /// No description provided for @selectFranchise.
  ///
  /// In en, this message translates to:
  /// **'Select Franchise'**
  String get selectFranchise;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get selectStatus;

  /// No description provided for @injectSubscription.
  ///
  /// In en, this message translates to:
  /// **'Inject Subscription'**
  String get injectSubscription;

  /// No description provided for @subscriptionInjectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subscription injected successfully'**
  String get subscriptionInjectionSuccess;

  /// No description provided for @subscriptionInjectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to inject subscription'**
  String get subscriptionInjectionFailed;

  /// No description provided for @pleaseSelectFranchiseAndPlan.
  ///
  /// In en, this message translates to:
  /// **'Please select both a franchise and a plan'**
  String get pleaseSelectFranchiseAndPlan;

  /// No description provided for @genericSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get genericSavedSuccess;

  /// No description provided for @nextBillingDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Billing Date'**
  String get nextBillingDateLabel;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @toggleSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Subscription Status'**
  String get toggleSubscriptionTitle;

  /// No description provided for @planSwapperTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Franchise Plan'**
  String get planSwapperTitle;

  /// No description provided for @onboardingMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Franchise Onboarding'**
  String get onboardingMenuTitle;

  /// No description provided for @onboardingFor.
  ///
  /// In en, this message translates to:
  /// **'Onboarding for'**
  String get onboardingFor;

  /// No description provided for @stepIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get stepIngredients;

  /// No description provided for @stepIngredientsDesc.
  ///
  /// In en, this message translates to:
  /// **'Define all ingredients like toppings, sauces, and sides.'**
  String get stepIngredientsDesc;

  /// No description provided for @stepCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get stepCategories;

  /// No description provided for @stepCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize your menu into logical sections (e.g. Pizzas, Drinks).'**
  String get stepCategoriesDesc;

  /// No description provided for @stepMenuItems.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Menu Items'**
  String get stepMenuItems;

  /// No description provided for @stepMenuItemsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create actual items customers can order, using ingredients and categories.'**
  String get stepMenuItemsDesc;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Step 6: Final Review'**
  String get stepReview;

  /// No description provided for @stepReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Validate all required data before going live.'**
  String get stepReviewDesc;

  /// No description provided for @progressComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Progress tracking and automation coming soon.'**
  String get progressComingSoon;

  /// No description provided for @stepMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'Step marked complete!'**
  String get stepMarkedComplete;

  /// No description provided for @onboardingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get onboardingIngredients;

  /// No description provided for @noIngredientsFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredients found'**
  String get noIngredientsFound;

  /// No description provided for @noIngredientsMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not added any ingredients yet. Start by tapping the add button.'**
  String get noIngredientsMessage;

  /// No description provided for @ingredientName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ingredientName;

  /// No description provided for @ingredientDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ingredientDescription;

  /// No description provided for @errorSavingIngredient.
  ///
  /// In en, this message translates to:
  /// **'Error saving ingredient'**
  String get errorSavingIngredient;

  /// No description provided for @ingredientType.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Type'**
  String get ingredientType;

  /// No description provided for @removable.
  ///
  /// In en, this message translates to:
  /// **'Removable'**
  String get removable;

  /// No description provided for @supportsExtra.
  ///
  /// In en, this message translates to:
  /// **'Supports Extra'**
  String get supportsExtra;

  /// No description provided for @sidesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Sides Allowed'**
  String get sidesAllowed;

  /// No description provided for @saveIngredient.
  ///
  /// In en, this message translates to:
  /// **'Save Ingredient'**
  String get saveIngredient;

  /// No description provided for @allergenTags.
  ///
  /// In en, this message translates to:
  /// **'Allergen Tags'**
  String get allergenTags;

  /// No description provided for @deleteIngredient.
  ///
  /// In en, this message translates to:
  /// **'Delete Ingredient'**
  String get deleteIngredient;

  /// No description provided for @confirmDeleteIngredient.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ingredient?'**
  String get confirmDeleteIngredient;

  /// No description provided for @errorDeletingIngredient.
  ///
  /// In en, this message translates to:
  /// **'Error deleting ingredient'**
  String get errorDeletingIngredient;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @selectAFranchiseFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a franchise first.'**
  String get selectAFranchiseFirst;

  /// No description provided for @ingredientTypes.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Types'**
  String get ingredientTypes;

  /// No description provided for @addIngredientType.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient Type'**
  String get addIngredientType;

  /// No description provided for @editIngredientType.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient Type'**
  String get editIngredientType;

  /// No description provided for @noIngredientTypesFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredient types found.'**
  String get noIngredientTypesFound;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescription;

  /// No description provided for @ingredientTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ingredient type deleted'**
  String get ingredientTypeDeleted;

  /// No description provided for @systemTag.
  ///
  /// In en, this message translates to:
  /// **'System Tag'**
  String get systemTag;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @manageIngredientTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage Ingredient Types'**
  String get manageIngredientTypes;

  /// No description provided for @pleaseAddIngredientTypesFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one ingredient with a type before marking this step complete.'**
  String get pleaseAddIngredientTypesFirst;

  /// No description provided for @stepIngredientTypes.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Types'**
  String get stepIngredientTypes;

  /// No description provided for @stepIngredientTypesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create logical ingredient type tags like toppings, sauces, and sides.'**
  String get stepIngredientTypesDesc;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @selectIngredientTypeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select a Starter Template'**
  String get selectIngredientTypeTemplate;

  /// No description provided for @templateLoadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Template loaded successfully!'**
  String get templateLoadedSuccessfully;

  /// No description provided for @pizzaShopTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pizza Shop Starter'**
  String get pizzaShopTemplateLabel;

  /// No description provided for @pizzaShopTemplateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Includes cheeses, meats, sauces, and more'**
  String get pizzaShopTemplateSubtitle;

  /// No description provided for @wingBarTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Wing Bar Starter (Coming Soon)'**
  String get wingBarTemplateLabel;

  /// No description provided for @wingBarTemplateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Includes dips, sauces, and portion logic'**
  String get wingBarTemplateSubtitle;

  /// No description provided for @loadDefaultTypes.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient Type Template'**
  String get loadDefaultTypes;

  /// No description provided for @deletionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Deletion Blocked'**
  String get deletionBlocked;

  /// No description provided for @ingredientTypeInUseError.
  ///
  /// In en, this message translates to:
  /// **'This ingredient type is currently used by one or more ingredients and cannot be deleted.'**
  String get ingredientTypeInUseError;

  /// No description provided for @ingredientTypeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ingredientTypeName;

  /// No description provided for @ingredientTypeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toppings'**
  String get ingredientTypeNameHint;

  /// No description provided for @ingredientTypeAdded.
  ///
  /// In en, this message translates to:
  /// **'Ingredient type added'**
  String get ingredientTypeAdded;

  /// No description provided for @ingredientTypeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get ingredientTypeNameRequired;

  /// No description provided for @ingredientTypeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Type Updated.'**
  String get ingredientTypeUpdated;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @revertChanges.
  ///
  /// In en, this message translates to:
  /// **'Revert Changes'**
  String get revertChanges;

  /// No description provided for @invalidJsonFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format. Please ensure the input is a valid list of ingredient types.'**
  String get invalidJsonFormat;

  /// No description provided for @jsonParseError.
  ///
  /// In en, this message translates to:
  /// **'Unable to parse JSON preview.'**
  String get jsonParseError;

  /// No description provided for @noPreviewData.
  ///
  /// In en, this message translates to:
  /// **'No preview data available.'**
  String get noPreviewData;

  /// No description provided for @visibleInApp.
  ///
  /// In en, this message translates to:
  /// **'Visible in App'**
  String get visibleInApp;

  /// No description provided for @importExportIngredientTypes.
  ///
  /// In en, this message translates to:
  /// **'Import / Export Ingredient Types'**
  String get importExportIngredientTypes;

  /// No description provided for @editJsonBelow.
  ///
  /// In en, this message translates to:
  /// **'Edit the JSON below to import or adjust ingredient types.'**
  String get editJsonBelow;

  /// No description provided for @jsonInput.
  ///
  /// In en, this message translates to:
  /// **'JSON Input'**
  String get jsonInput;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get importExport;

  /// No description provided for @selectIngredientTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient Template'**
  String get selectIngredientTemplate;

  /// No description provided for @loadDefaultIngredients.
  ///
  /// In en, this message translates to:
  /// **'Load Default Ingredients'**
  String get loadDefaultIngredients;

  /// No description provided for @confirmLoadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Template Load'**
  String get confirmLoadTemplate;

  /// No description provided for @overwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite existing ingredients. Continue?'**
  String get overwriteWarning;

  /// No description provided for @templateLoaded.
  ///
  /// In en, this message translates to:
  /// **'Template loaded successfully!'**
  String get templateLoaded;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes Saved'**
  String get changesSaved;

  /// No description provided for @noDataToPreview.
  ///
  /// In en, this message translates to:
  /// **'No Data To Preview'**
  String get noDataToPreview;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @importExportIngredientMetadata.
  ///
  /// In en, this message translates to:
  /// **'Import / Export Ingredient Metadata'**
  String get importExportIngredientMetadata;

  /// No description provided for @importChanges.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importChanges;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group By'**
  String get groupBy;

  /// No description provided for @typeId.
  ///
  /// In en, this message translates to:
  /// **'Type ID'**
  String get typeId;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get ungrouped;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @bulkDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected ingredients? This action cannot be undone.'**
  String bulkDeleteConfirmation(Object count);

  /// No description provided for @bulkDeleteIngredientsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bulk Delete Ingredients Success'**
  String get bulkDeleteIngredientsSuccess;

  /// No description provided for @stepMarkedIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Step marked as incomplete.'**
  String get stepMarkedIncomplete;

  /// No description provided for @saveSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Save Successful'**
  String get saveSuccessful;

  /// No description provided for @invalidTypeIdError.
  ///
  /// In en, this message translates to:
  /// **'Invalid typeId found for ingredients'**
  String get invalidTypeIdError;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get confirmDeleteCategory;

  /// No description provided for @onboardingCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get onboardingCategories;

  /// No description provided for @addCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategoryTitle;

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategoryTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameLabel;

  /// No description provided for @categoryDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Description'**
  String get categoryDescriptionLabel;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get importSuccess;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Failed to import data.'**
  String get importError;

  /// No description provided for @importExportCategories.
  ///
  /// In en, this message translates to:
  /// **'Import/Export Categories'**
  String get importExportCategories;

  /// No description provided for @importExportInstruction.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON data to import or edit it before saving.'**
  String get importExportInstruction;

  /// No description provided for @jsonData.
  ///
  /// In en, this message translates to:
  /// **'JSON Data'**
  String get jsonData;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @selectCategoryTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select a category template'**
  String get selectCategoryTemplate;

  /// No description provided for @categoryMarkedAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Category step marked as complete.'**
  String get categoryMarkedAsComplete;

  /// No description provided for @sizes.
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// No description provided for @deleteMenuItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {itemName}?'**
  String deleteMenuItemConfirm(Object itemName);

  /// No description provided for @menuItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Menu item deleted successfully.'**
  String get menuItemDeleted;

  /// No description provided for @menuItemMarkedAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Menu items step marked as complete.'**
  String get menuItemMarkedAsComplete;

  /// No description provided for @onboardingMenuItems.
  ///
  /// In en, this message translates to:
  /// **'Onboarding: Menu Items'**
  String get onboardingMenuItems;

  /// No description provided for @loadDefaultTemplates.
  ///
  /// In en, this message translates to:
  /// **'Load Default Templates'**
  String get loadDefaultTemplates;

  /// No description provided for @noMenuItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No menu items found.'**
  String get noMenuItemsFound;

  /// No description provided for @noMenuItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Start by adding at least one menu item.'**
  String get noMenuItemsMessage;

  /// No description provided for @editMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {itemName}'**
  String editMenuItem(Object itemName);

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePrice;

  /// No description provided for @importExportJson.
  ///
  /// In en, this message translates to:
  /// **'Import / Export JSON'**
  String get importExportJson;

  /// No description provided for @pasteOrEditJson.
  ///
  /// In en, this message translates to:
  /// **'Paste or edit JSON for your menu items below.'**
  String get pasteOrEditJson;

  /// No description provided for @noTemplatesFound.
  ///
  /// In en, this message translates to:
  /// **'No Templates Found'**
  String get noTemplatesFound;

  /// No description provided for @toggleFeatureError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update feature toggle. Please try again.'**
  String get toggleFeatureError;

  /// No description provided for @featureSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Enabled Features'**
  String get featureSetupTitle;

  /// No description provided for @featureSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which optional features this franchise should have access to. These are constrained by their current platform plan.'**
  String get featureSetupDescription;

  /// No description provided for @featureSetupToggleSection.
  ///
  /// In en, this message translates to:
  /// **'Available Features'**
  String get featureSetupToggleSection;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Features saved successfully.'**
  String get saveSuccess;

  /// No description provided for @saveErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveErrorTitle;

  /// No description provided for @saveErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your feature selections. Please try again.'**
  String get saveErrorBody;

  /// No description provided for @stepFeatureSetup.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Feature Setup'**
  String get stepFeatureSetup;

  /// No description provided for @stepFeatureSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which modules and features this franchise will use.'**
  String get stepFeatureSetupDesc;

  /// No description provided for @seedPlatformFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Platform Features'**
  String get seedPlatformFeaturesTitle;

  /// No description provided for @seedPlatformFeaturesDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste a JSON array of feature objects below to overwrite or create entries in the /platform_features collection.'**
  String get seedPlatformFeaturesDescription;

  /// No description provided for @jsonInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature JSON Array'**
  String get jsonInputLabel;

  /// No description provided for @submitSeedData.
  ///
  /// In en, this message translates to:
  /// **'Submit Seed Data'**
  String get submitSeedData;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @seedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Successfully seeded platform features.'**
  String get seedSuccess;

  /// No description provided for @seedFailure.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to seed features. Please check your JSON and try again.'**
  String get seedFailure;

  /// No description provided for @devtoolsSeedPlatformPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Platform Plans'**
  String get devtoolsSeedPlatformPlansTitle;

  /// No description provided for @devtoolsSeedPlatformPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Input a list of plan objects to store in the /platform_plans collection. Each plan must include a unique \'id\' field. Existing entries will be overwritten.'**
  String get devtoolsSeedPlatformPlansDescription;

  /// No description provided for @devtoolsJsonInputLabel.
  ///
  /// In en, this message translates to:
  /// **'JSON Input'**
  String get devtoolsJsonInputLabel;

  /// No description provided for @devtoolsJsonValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Input cannot be empty'**
  String get devtoolsJsonValidationEmpty;

  /// No description provided for @devtoolsSeedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Seeded successfully!'**
  String get devtoolsSeedSuccess;

  /// No description provided for @devtoolsSeedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to seed. Check error logs.'**
  String get devtoolsSeedError;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @copySampleJson.
  ///
  /// In en, this message translates to:
  /// **'Copy Sample JSON'**
  String get copySampleJson;

  /// No description provided for @sampleJsonCopied.
  ///
  /// In en, this message translates to:
  /// **'Sample JSON copied to clipboard!'**
  String get sampleJsonCopied;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @devtoolsDeletePlatformPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Platform Plan'**
  String get devtoolsDeletePlatformPlansTitle;

  /// No description provided for @devtoolsSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select Plan ID'**
  String get devtoolsSelectPlan;

  /// No description provided for @devtoolsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted successfully.'**
  String get devtoolsDeleteSuccess;

  /// No description provided for @devtoolsDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the plan.'**
  String get devtoolsDeleteError;

  /// No description provided for @platformFeaturePlanTools.
  ///
  /// In en, this message translates to:
  /// **'Platform Feature + Plan Tools'**
  String get platformFeaturePlanTools;

  /// No description provided for @subscriptionTools.
  ///
  /// In en, this message translates to:
  /// **'Subscription Tools'**
  String get subscriptionTools;

  /// No description provided for @billingTools.
  ///
  /// In en, this message translates to:
  /// **'Billing Tools'**
  String get billingTools;

  /// No description provided for @devtoolsFieldKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get devtoolsFieldKey;

  /// No description provided for @devtoolsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get devtoolsFieldName;

  /// No description provided for @devtoolsFieldModule.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get devtoolsFieldModule;

  /// No description provided for @devtoolsFieldDeprecated.
  ///
  /// In en, this message translates to:
  /// **'Deprecated'**
  String get devtoolsFieldDeprecated;

  /// No description provided for @devtoolsFieldDeveloperOnly.
  ///
  /// In en, this message translates to:
  /// **'Developer Only'**
  String get devtoolsFieldDeveloperOnly;

  /// No description provided for @devtoolsFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get devtoolsFieldDescription;

  /// No description provided for @devtoolsAddFeature.
  ///
  /// In en, this message translates to:
  /// **'Add Feature'**
  String get devtoolsAddFeature;

  /// No description provided for @devtoolsFeaturesToSeed.
  ///
  /// In en, this message translates to:
  /// **'Features to Seed'**
  String get devtoolsFeaturesToSeed;

  /// No description provided for @devtoolsValidationEmptyFeatureList.
  ///
  /// In en, this message translates to:
  /// **'No features to submit.'**
  String get devtoolsValidationEmptyFeatureList;

  /// No description provided for @devtoolsValidationMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Key and Name are required.'**
  String get devtoolsValidationMissingFields;

  /// No description provided for @uploadViaJson.
  ///
  /// In en, this message translates to:
  /// **'Upload via JSON'**
  String get uploadViaJson;

  /// No description provided for @devtoolsDeletePlatformFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Platform Feature'**
  String get devtoolsDeletePlatformFeaturesTitle;

  /// No description provided for @devtoolsSelectFeature.
  ///
  /// In en, this message translates to:
  /// **'Select a feature to delete'**
  String get devtoolsSelectFeature;

  /// No description provided for @noIngredientsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No ingredients have been configured yet. Please add or import ingredients to continue.'**
  String get noIngredientsConfigured;

  /// No description provided for @customizationGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Label'**
  String get customizationGroupLabel;

  /// No description provided for @selectionLimit.
  ///
  /// In en, this message translates to:
  /// **'Selection Limit'**
  String get selectionLimit;

  /// No description provided for @removeGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove Group'**
  String get removeGroup;

  /// No description provided for @addCustomizationGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Customization Group'**
  String get addCustomizationGroup;

  /// No description provided for @editNutrition.
  ///
  /// In en, this message translates to:
  /// **'Edit Nutrition Info'**
  String get editNutrition;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @carbohydrates.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get carbohydrates;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get chooseTemplate;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @noChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Chats'**
  String get noChatsTitle;

  /// No description provided for @noChatsMessage.
  ///
  /// In en, this message translates to:
  /// **'No support chats yet.'**
  String get noChatsMessage;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat thread?'**
  String get deleteChatConfirmMessage;

  /// No description provided for @deleteChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat'**
  String get deleteChatTooltip;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @genericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericErrorMessage;

  /// No description provided for @createNewIngredient.
  ///
  /// In en, this message translates to:
  /// **'Create New Ingredient'**
  String get createNewIngredient;

  /// No description provided for @e_g_anchovies.
  ///
  /// In en, this message translates to:
  /// **'e.g. Anchovies'**
  String get e_g_anchovies;

  /// No description provided for @upchargeOptional.
  ///
  /// In en, this message translates to:
  /// **'Upcharge (optional)'**
  String get upchargeOptional;

  /// No description provided for @selectIngredient.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient'**
  String get selectIngredient;

  /// No description provided for @ingredientCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{ingredientName} created successfully.'**
  String ingredientCreatedSuccessfully(Object ingredientName);

  /// No description provided for @ingredientCreatedSuccessfullyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Confirm ingredient creation'**
  String get ingredientCreatedSuccessfullyTooltip;

  /// No description provided for @ingredientStagedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ingredient \"{name}\" staged successfully.'**
  String ingredientStagedSuccessfully(Object name);

  /// No description provided for @ingredientStagedSuccessfullyTooltip.
  ///
  /// In en, this message translates to:
  /// **'This ingredient has been added temporarily. Remember to save changes to finalize it.'**
  String get ingredientStagedSuccessfullyTooltip;

  /// No description provided for @createNewIngredientType.
  ///
  /// In en, this message translates to:
  /// **'Create New Ingredient Type'**
  String get createNewIngredientType;

  /// No description provided for @typeName.
  ///
  /// In en, this message translates to:
  /// **'Type Name'**
  String get typeName;

  /// No description provided for @systemTagOptional.
  ///
  /// In en, this message translates to:
  /// **'System Tag (optional)'**
  String get systemTagOptional;

  /// No description provided for @ingredientTypeStagedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ingredient type \"{name}\" staged successfully.'**
  String ingredientTypeStagedSuccessfully(Object name);

  /// No description provided for @selectIngredientType.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient Type'**
  String get selectIngredientType;

  /// No description provided for @createNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Create New Category'**
  String get createNewCategory;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @categoryStagedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category \"{categoryName}\" staged successfully.'**
  String categoryStagedSuccessfully(Object categoryName);

  /// No description provided for @toDelete.
  ///
  /// In en, this message translates to:
  /// **'to delete'**
  String get toDelete;

  /// No description provided for @selectAllPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select all ingredient types for delete?'**
  String get selectAllPrompt;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @missingMenuItemPrereqs.
  ///
  /// In en, this message translates to:
  /// **'Menu Item Step Blocked'**
  String get missingMenuItemPrereqs;

  /// No description provided for @menuItemsMissingPrerequisites.
  ///
  /// In en, this message translates to:
  /// **'You must complete the following steps before adding menu items: {steps}'**
  String menuItemsMissingPrerequisites(Object steps);

  /// No description provided for @goToStep.
  ///
  /// In en, this message translates to:
  /// **'Go to {step}'**
  String goToStep(Object step);

  /// No description provided for @ingredientsImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} ingredients.'**
  String ingredientsImported(Object count);

  /// No description provided for @onboardingReviewPublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Publish'**
  String get onboardingReviewPublishTitle;

  /// No description provided for @onboardingReviewPublishDesc.
  ///
  /// In en, this message translates to:
  /// **'Check for any missing information or schema issues before going live. All critical issues must be resolved.'**
  String get onboardingReviewPublishDesc;

  /// No description provided for @onboardingReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Review Failed'**
  String get onboardingReviewFailed;

  /// No description provided for @onboardingReviewReadyToPublish.
  ///
  /// In en, this message translates to:
  /// **'All required information is complete. Ready to publish.'**
  String get onboardingReviewReadyToPublish;

  /// No description provided for @onboardingReviewFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Resolve all blocking issues before you can publish.'**
  String get onboardingReviewFixErrors;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepLabel(Object step, Object total);

  /// Tooltip description for dairy allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains dairy products such as milk, cheese, or butter.'**
  String get tagDairyDescription;

  /// Tooltip description for gluten allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains gluten from wheat, barley, rye, or related grains.'**
  String get tagGlutenDescription;

  /// Tooltip description for nuts allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains tree nuts or peanuts.'**
  String get tagNutsDescription;

  /// Tooltip description for soy allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains soy or soy-based products.'**
  String get tagSoyDescription;

  /// Tooltip description for eggs allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains eggs or egg-based ingredients.'**
  String get tagEggsDescription;

  /// Tooltip description for fish allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains fish or fish-derived ingredients.'**
  String get tagFishDescription;

  /// Tooltip description for shellfish allergen tag.
  ///
  /// In en, this message translates to:
  /// **'Contains shellfish such as crab, shrimp, or lobster.'**
  String get tagShellfishDescription;

  /// Tooltip description for vegan dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Suitable for a vegan diet; contains no animal products.'**
  String get tagVeganDescription;

  /// Tooltip description for vegetarian dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Suitable for a vegetarian diet; contains no meat or fish.'**
  String get tagVegetarianDescription;

  /// Tooltip description for halal dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Prepared according to Halal dietary guidelines.'**
  String get tagHalalDescription;

  /// Tooltip description for kosher dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Prepared according to Kosher dietary guidelines.'**
  String get tagKosherDescription;

  /// Tooltip description for sugar-free dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Contains no added sugars.'**
  String get tagSugarFreeDescription;

  /// Tooltip description for low sodium dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Low in sodium content.'**
  String get tagLowSodiumDescription;

  /// Tooltip description for spicy food tag.
  ///
  /// In en, this message translates to:
  /// **'May be spicy or contain hot peppers.'**
  String get tagSpicyDescription;

  /// Tooltip description for organic dietary tag.
  ///
  /// In en, this message translates to:
  /// **'Made with organic ingredients.'**
  String get tagOrganicDescription;
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
