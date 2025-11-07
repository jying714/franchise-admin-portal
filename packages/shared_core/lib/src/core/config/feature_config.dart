/// Pure Dart feature configuration — shared across mobile, web, and functions
/// Contains default values and mapping logic only
/// No Firebase, no Logger, no async
class FeatureConfig {
  // Singleton
  FeatureConfig._();
  static final FeatureConfig instance = FeatureConfig._();

  // ===== Feature Toggles (Defaults) =====
  bool loyaltyEnabled = false;
  bool inventoryEnabled = false;
  bool statusEnabled = false;
  bool segmentationEnabled = false;
  bool dynamicPricingEnabled = false;
  bool nutritionEnabled = false;
  bool recurrenceEnabled = false;
  bool languageEnabled = false;
  bool supportEnabled = false;
  bool trackOrderEnabled = true;

  // ===== Auth Toggles =====
  bool enableGuestMode = true;
  bool enableDemoMode = false;
  bool forceLogin = false;
  bool googleAuthEnabled = true;
  bool facebookAuthEnabled = true;
  bool appleAuthEnabled = false;
  bool phoneAuthEnabled = true;

  // ===== Admin/Analytics/Promo Toggles =====
  bool adminDashboardEnabled = true;
  bool bannerPromoManagementEnabled = true;
  bool feedbackManagementEnabled = true;
  bool analyticsDashboardEnabled = true;
  bool staffAccessEnabled = true;
  bool featureToggleUIEnabled = true;
  bool chatManagementEnabled = true;
  bool promoBulkUploadEnabled = true;
  bool promoExportEnabled = true;
  bool analyticsExportEnabled = true;

  /// Apply Firestore data to this instance
  void apply(Map<String, dynamic> data) {
    loyaltyEnabled = data['loyaltyEnabled'] ?? loyaltyEnabled;
    inventoryEnabled = data['inventoryEnabled'] ?? inventoryEnabled;
    statusEnabled = data['statusEnabled'] ?? statusEnabled;
    segmentationEnabled = data['segmentationEnabled'] ?? segmentationEnabled;
    dynamicPricingEnabled =
        data['dynamicPricingEnabled'] ?? dynamicPricingEnabled;
    nutritionEnabled = data['nutritionEnabled'] ?? nutritionEnabled;
    recurrenceEnabled = data['recurrenceEnabled'] ?? recurrenceEnabled;
    languageEnabled = data['languageEnabled'] ?? languageEnabled;
    supportEnabled = data['supportEnabled'] ?? supportEnabled;
    trackOrderEnabled = data['trackOrderEnabled'] ?? trackOrderEnabled;

    enableGuestMode = data['enableGuestMode'] ?? enableGuestMode;
    enableDemoMode = data['enableDemoMode'] ?? enableDemoMode;
    forceLogin = data['forceLogin'] ?? forceLogin;
    googleAuthEnabled = data['googleAuthEnabled'] ?? googleAuthEnabled;
    facebookAuthEnabled = data['facebookAuthEnabled'] ?? facebookAuthEnabled;
    appleAuthEnabled = data['appleAuthEnabled'] ?? appleAuthEnabled;
    phoneAuthEnabled = data['phoneAuthEnabled'] ?? phoneAuthEnabled;

    adminDashboardEnabled =
        data['adminDashboardEnabled'] ?? adminDashboardEnabled;
    bannerPromoManagementEnabled =
        data['bannerPromoManagementEnabled'] ?? bannerPromoManagementEnabled;
    feedbackManagementEnabled =
        data['feedbackManagementEnabled'] ?? feedbackManagementEnabled;
    analyticsDashboardEnabled =
        data['analyticsDashboardEnabled'] ?? analyticsDashboardEnabled;
    staffAccessEnabled = data['staffAccessEnabled'] ?? staffAccessEnabled;
    featureToggleUIEnabled =
        data['featureToggleUIEnabled'] ?? featureToggleUIEnabled;
    chatManagementEnabled =
        data['chatManagementEnabled'] ?? chatManagementEnabled;
    promoBulkUploadEnabled =
        data['promoBulkUploadEnabled'] ?? promoBulkUploadEnabled;
    promoExportEnabled = data['promoExportEnabled'] ?? promoExportEnabled;
    analyticsExportEnabled =
        data['analyticsExportEnabled'] ?? analyticsExportEnabled;

    // Business rule: demo and guest cannot both be true
    if (enableDemoMode && enableGuestMode) {
      enableGuestMode = false;
    }
  }

  /// Export current state as map
  Map<String, bool> get asMap => {
        'loyaltyEnabled': loyaltyEnabled,
        'inventoryEnabled': inventoryEnabled,
        'statusEnabled': statusEnabled,
        'segmentationEnabled': segmentationEnabled,
        'dynamicPricingEnabled': dynamicPricingEnabled,
        'nutritionEnabled': nutritionEnabled,
        'recurrenceEnabled': recurrenceEnabled,
        'languageEnabled': languageEnabled,
        'supportEnabled': supportEnabled,
        'trackOrderEnabled': trackOrderEnabled,
        'enableGuestMode': enableGuestMode,
        'enableDemoMode': enableDemoMode,
        'forceLogin': forceLogin,
        'googleAuthEnabled': googleAuthEnabled,
        'facebookAuthEnabled': facebookAuthEnabled,
        'appleAuthEnabled': appleAuthEnabled,
        'phoneAuthEnabled': phoneAuthEnabled,
        'adminDashboardEnabled': adminDashboardEnabled,
        'bannerPromoManagementEnabled': bannerPromoManagementEnabled,
        'feedbackManagementEnabled': feedbackManagementEnabled,
        'analyticsDashboardEnabled': analyticsDashboardEnabled,
        'staffAccessEnabled': staffAccessEnabled,
        'featureToggleUIEnabled': featureToggleUIEnabled,
        'chatManagementEnabled': chatManagementEnabled,
        'promoBulkUploadEnabled': promoBulkUploadEnabled,
        'promoExportEnabled': promoExportEnabled,
        'analyticsExportEnabled': analyticsExportEnabled,
      };
}
