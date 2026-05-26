class FeatureConfig {
  static FeatureConfig get instance => _instance;
  static final FeatureConfig _instance = FeatureConfig._internal();

  FeatureConfig._internal();

  final bool loyaltyEnabled = true;
  final bool favoritesEnabled = true;
  final bool scheduledOrdersEnabled = true;
  final bool chatSupportEnabled = true;
  final bool notificationsEnabled = true;
}
