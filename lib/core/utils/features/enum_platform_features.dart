enum PlatformFeature {
  webOrdering,
  supportChat,
  staffAccess,
  schemaManagement,
  promoBanners,
  pluginRegistry,
  orderTracking,
  nutritionalInfo,
  multiLocation,
  mobileOrdering,
  menuItemCustomization,
  loyalty,
  languageSupport,
  inventory,
  feedback,
  featureToggles,
  discountCodes,
  comboMeals,
  chatSupport,
  brandingCustomization,
  analyticsReporting,
}

extension PlatformFeatureExtension on PlatformFeature {
  String get key => toString().split('.').last.snakeCase();
}

extension StringCasingExtension on String {
  String snakeCase() {
    return replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(0)}')
        .toLowerCase()
        .replaceFirst('_', '');
  }
}
