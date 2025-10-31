// packages/shared_core/lib/src/core/config/app_config.dart

class AppConfig {
  // ===== FIRESTORE COLLECTION NAMES =====
  static const String usersCollection = 'users';
  static const String menuItemsCollection = 'menu_items';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';
  static const String cartCollection = 'cart';
  static const String bannersCollection = 'banners';
  static const String feedbackCollection = 'feedback';
  static const String inventoryCollection = 'inventory_transactions';
  static const String supportChatsCollection = 'support_chats';
  static const String promotionsCollection = 'promotions';
  static const String configCollection = 'config';
  static const String auditLogCollection = 'audit_logs';

  // ===== SUBCOLLECTION NAMES =====
  static const String addressesSubcollection = 'addresses';
  static const String favoriteOrdersSubcollection = 'favorite_orders';

  // ===== FAVORITE MENU ITEM LIMIT =====
  static const int maxFavoriteMenuItemsLookup = 10;

  // ===== UTILITY CONSTANTS =====
  static const Duration toastDuration = Duration(seconds: 2);

  // ===== SCHEDULED ORDERS =====
  static const String scheduledOrdersCollection = 'scheduledOrders';

  // ===== STATIC TEXT =====
  static const String poweredBy = "Powered by Dough Boys Tech";

  // ===== MENU EDITOR & BULK ACTIONS =====
  static const int menuItemMaxImageSizeMB = 2;
  static const int menuItemImageDim = 1200;
  static const int bulkUploadMaxRows = 100;
  static const List<String> allowedImageFormats = ['jpeg', 'jpg', 'png'];
  static const bool enableAuditLogs = true;
  static const bool enableCSVExport = true;
  static const List<String> dietaryTags = [
    'Vegan',
    'Vegetarian',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher'
  ];
  static const List<String> allergenTags = [
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Tree Nuts',
    'Peanuts',
    'Wheat',
    'Soy'
  ];

  // File-system-ish paths kept generic; apps decide actual assets/usage
  static const String promoExportDir = 'exports/promos';
  static const String analyticsExportDir = 'exports/analytics';
  static const String dateFormat = 'yyyy-MM-dd';

  // Cross-platform runtime knobs (no Flutter types)
  final String apiBaseUrl;
  final String brandingColorHex; // keep as hex string in shared_core
  final bool isProduction;

  const AppConfig({
    required this.apiBaseUrl,
    required this.brandingColorHex,
    required this.isProduction,
  });

  static String featureDisplayName(String featureKey) {
    switch (featureKey) {
      case 'mobile_app':
        return 'Mobile App';
      case 'web_ordering':
        return 'Web Ordering';
      case 'multi_location':
        return 'Multi-location Support';
      case 'custom_branding':
        return 'Custom Branding';
      case 'priority_support':
        return 'Priority Support';
      case 'analytics_dashboard':
        return 'Analytics Dashboard';
      case 'coupon_management':
        return 'Coupon Management';
      case 'loyalty_program':
        return 'Loyalty Program';
      case 'pos_integration':
        return 'POS Integration';
      case 'custom_plan':
        return 'Custom Plan Features';
      default:
        return featureKey;
    }
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
