import 'package:flutter/material.dart';
// Import ALL your admin sections (ensure these files exist!)
import 'package:franchise_admin_portal/admin/dashboard/dashboard_home_screen.dart';
import 'package:franchise_admin_portal/admin/menu/menu_editor_screen.dart';
import 'package:franchise_admin_portal/admin/categories/category_management_screen.dart';
import 'package:franchise_admin_portal/admin/inventory/inventory_screen.dart';
import 'package:franchise_admin_portal/admin/orders/analytics_screen.dart';
import 'package:franchise_admin_portal/admin/orders/order_management_screen.dart';
import 'package:franchise_admin_portal/admin/feedback/feedback_management_screen.dart';
import 'package:franchise_admin_portal/admin/promo/promo_management_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_access_screen.dart';
import 'package:franchise_admin_portal/admin/features/feature_settings_screen.dart';
import 'package:franchise_admin_portal/admin/chat/chat_management_screen.dart';
import 'package:franchise_admin_portal/admin/error_logs/error_logs_screen.dart';
import 'package:franchise_admin_portal/admin/developer/platform/platform_plans_section.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_categories_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredients_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_items_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_review_screen.dart';
import 'package:shared_core/shared_core.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredient_type_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_feature_setup_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/menu_item_editor_screen.dart';
// Any new (plugin/module) screens can be imported and registered here

// ==== UNIFIED SECTION REGISTRY (ALL MAIN + ONBOARDING) ====
final List<DashboardSection> sectionRegistry = [
  // ---- Core dashboard sections ----
  DashboardSection(
    key: 'dashboardHome',
    title: 'Dashboard',
    icon: Icons.dashboard,
    builder: (_) => const DashboardHomeScreen(),
    sidebarOrder: 0,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'menuEditor',
    title: 'Menu',
    icon: Icons.local_pizza,
    builder: (_) => const MenuEditorScreen(),
    sidebarOrder: 1,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'categoryManagement',
    title: 'Categories',
    icon: Icons.category_outlined,
    builder: (_) => const CategoryManagementScreen(),
    sidebarOrder: 2,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'inventoryManagement',
    title: 'Inventory',
    icon: Icons.inventory,
    builder: (_) => const InventoryScreen(),
    sidebarOrder: 3,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'orderAnalytics',
    title: 'Order Analytics',
    icon: Icons.analytics_outlined,
    builder: (_) => const AnalyticsScreen(),
    sidebarOrder: 4,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'orderManagement',
    title: 'Orders',
    icon: Icons.receipt_long_outlined,
    builder: (_) => const OrderManagementScreen(),
    sidebarOrder: 5,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'feedbackManagement',
    title: 'Feedback',
    icon: Icons.feedback_outlined,
    builder: (_) => const FeedbackManagementScreen(),
    sidebarOrder: 6,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'promoManagement',
    title: 'Promotions',
    icon: Icons.card_giftcard_outlined,
    builder: (_) => const PromoManagementScreen(),
    sidebarOrder: 7,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'staffAccess',
    title: 'Staff',
    icon: Icons.people_outline,
    builder: (_) => const StaffAccessScreen(),
    sidebarOrder: 8,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'chatManagement',
    title: 'Support Chat',
    icon: Icons.chat_bubble_outline,
    builder: (_) => const ChatManagementScreen(),
    sidebarOrder: 10,
    showInSidebar: true,
  ),
  // Hidden editor screen (utility, not in sidebar)
  DashboardSection(
    key: 'menuItemEditor',
    title: 'Menu Item Editor',
    icon: Icons.edit_note_rounded,
    builder: (_) => const MenuItemEditorScreen(),
    sidebarOrder: 11,
    showInSidebar: false,
  ),

  // ---- Onboarding Steps (now unified, sidebarOrder >= 100 for grouping) ----
  DashboardSection(
    key: 'onboardingMenu',
    title: 'Overview',
    icon: Icons.list_alt_outlined,
    builder: (_) => const OnboardingMenuScreen(),
    sidebarOrder: 100,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboarding_feature_setup',
    title: 'Step 1: Feature Setup',
    icon: Icons.tune,
    builder: (_) => OnboardingFeatureSetupScreen(),
    sidebarOrder: 101,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboardingIngredientTypes',
    title: 'Step 2: Ingredient Types',
    icon: Icons.category_outlined,
    builder: (_) => const IngredientTypeManagementScreen(),
    sidebarOrder: 102,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboardingIngredients',
    title: 'Step 3: Ingredients',
    icon: Icons.kitchen_outlined,
    builder: (_) => const OnboardingIngredientsScreen(),
    sidebarOrder: 103,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboardingCategories',
    title: 'Step 4: Categories',
    icon: Icons.category_outlined,
    builder: (_) => const OnboardingCategoriesScreen(),
    sidebarOrder: 104,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboardingMenuItems',
    title: 'Step 5: Menu Items',
    icon: Icons.local_pizza_outlined,
    builder: (_) => const OnboardingMenuItemsScreen(),
    sidebarOrder: 105,
    showInSidebar: true,
  ),
  DashboardSection(
    key: 'onboardingReview',
    title: 'Review & Publish',
    icon: Icons.check_circle_outline,
    builder: (_) => const OnboardingReviewScreen(),
    sidebarOrder: 106,
    showInSidebar: true,
  ),
  // Add further onboarding/future steps here...
];

// ---- Sidebar and Section List Utilities ----

/// Only sections with showInSidebar==true, sorted by sidebarOrder.
List<DashboardSection> getSidebarSections() =>
    sectionRegistry.where((s) => s.showInSidebar).toList()
      ..sort((a, b) => a.sidebarOrder.compareTo(b.sidebarOrder));

/// All sections (for routing, content stack, and selection), sorted by sidebarOrder.
List<DashboardSection> getAllDashboardSections() => sectionRegistry.toList()
  ..sort((a, b) => a.sidebarOrder.compareTo(b.sidebarOrder));
