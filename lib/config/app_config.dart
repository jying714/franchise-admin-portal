class AppConfig {
  // ===== FIRESTORE COLLECTION NAMES =====
  static const String usersCollection = 'users';
  static const String menuItemsCollection = 'menu_items';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';
  static const String cartCollection = 'cart';
  static const String bannersCollection = 'banners';
  static const String feedbackCollection = 'feedback';
  static const String inventoryCollection = 'inventory';
  static const String supportChatsCollection = 'support_chats';
  static const String promotionsCollection = 'promotions';
  static const String configCollection = 'config';
  static const String auditLogCollection = 'audit_logs';

  // ===== SUBCOLLECTION NAMES =====
  static const String addressesSubcollection = 'addresses';
  static const String favoriteOrdersSubcollection = 'favorite_orders';

  // ===== FAVORITE MENU ITEM LIMIT (Firestore best practice) =====
  static const int maxFavoriteMenuItemsLookup = 10;

  // ===== UTILITY CONSTANTS =====
  static const Duration toastDuration = Duration(seconds: 2);

  // ===== SCHEDULED ORDERS =====
  static const String scheduledOrdersCollection = 'scheduledOrders';

  // ===== FOOTER, LEGAL, & STATIC TEXT =====
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

  // ===== ADMIN DASHBOARD FEATURES =====

  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String promoExportDir = 'exports/promos';
  static const String analyticsExportDir = 'exports/analytics';
  static const String dateFormat =
      'yyyy-MM-dd'; // For date pickers if not set elsewhere

  // Example fields - adapt as needed
  final String apiBaseUrl;
  final String brandingColor;
  final bool isProduction;

  // 1. Singleton instance
  static final AppConfig instance = AppConfig._internal(
    apiBaseUrl: 'https://api.yourdomain.com',
    brandingColor: '#C62828',
    isProduction: true,
  );

  // 2. Private named constructor
  const AppConfig._internal({
    required this.apiBaseUrl,
    required this.brandingColor,
    required this.isProduction,
  });
}
