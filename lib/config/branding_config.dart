import 'package:flutter/material.dart';

class BrandingConfig {
  // --------- Franchise Details ---------
  static const String franchiseName = "Doughboys Pizzeria";
  static const String franchiseAddress = "123 Main St, City, State";
  static const String franchisePhone = "(555) 123-4567";
  static const String poweredBy = "Powered by Dough Boys Tech";

  // --------- Logos ---------
  static const String logoMain = 'assets/images/logo.png';
  static const String logoSmall = 'assets/images/logo_small.png';
  static const String logoLarge = 'assets/logo/logo_large.png';
  static const String logoLargeLegacy = 'assets/images/logo_large.png';

  // --------- Icons & Images ---------
  static const String defaultPizzaIcon = 'assets/icons/pizza.png';
  static const String defaultPizzaIconLegacy =
      'assets/images/default_pizza_icon.png';
  static const String defaultCategoryIcon =
      'assets/images/default_category_icon.png';
  static const String bannerPlaceholder =
      'assets/images/banner_placeholder.png';
  static const String fallbackAppIcon = 'assets/images/pizza_icon.png';

  // --------- Admin/Editor Assets ---------
  static const String adminEmptyStateImage = 'assets/images/admin_empty.png';
  static const String menuItemPlaceholderImage =
      'assets/images/menu_item_placeholder.png';
  static const Color brandRed = Color(0xFFD23215); // Dough Boys Pizzeria Red

  // --------- Bulk Upload, Export, Misc ---------
  static const String bulkUploadCSVIcon = 'assets/icons/csv_upload.png';
  static const String exportCSVIcon = 'assets/icons/export_csv.png';

  // --------- Legal/Docs ---------
  static const String termsOfServiceUrl = 'https://doughboys.com/terms';
  static const String privacyPolicyUrl = 'https://doughboys.com/privacy';

  // app bar

  static const String appBarLogoAsset =
      'assets/images/logo.png'; // Path to logo
  static const bool showLogoInAppBar = false; // Default to false
  static const String appBarTitle = 'Menu Categories';

  // ======================
  // === FUTURE TOKENS ====
  // ======================
  // static const String instagramHandle = "@doughboys";
  // static const String franchiseEmail = "contact@doughboys.com";
  // static const String franchiseSlogan = "Slice of Heaven Since 1999";
}
