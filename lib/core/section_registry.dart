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

// Any new (plugin/module) screens can be imported and registered here

class DashboardSection {
  final String key;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final bool showInSidebar;
  final int sidebarOrder;
  // For plugin/franchise logic: you might add more config fields in the future

  DashboardSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.builder,
    this.showInSidebar = true,
    this.sidebarOrder = 100, // Used for drag/sort or plugin injection
  });
}

// Central registry. Add or remove screens here to affect ALL navigation/dashboards.
final List<DashboardSection> sectionRegistry = [
  DashboardSection(
    key: 'dashboardHome',
    title: 'Dashboard',
    icon: Icons.dashboard,
    builder: (_) => const DashboardHomeScreen(),
    sidebarOrder: 0,
  ),
  DashboardSection(
    key: 'menuEditor',
    title: 'Menu',
    icon: Icons.local_pizza,
    builder: (_) => const MenuEditorScreen(),
    sidebarOrder: 1,
  ),
  DashboardSection(
    key: 'categoryManagement',
    title: 'Categories',
    icon: Icons.category_outlined,
    builder: (_) => const CategoryManagementScreen(),
    sidebarOrder: 2,
  ),
  DashboardSection(
    key: 'inventoryManagement',
    title: 'Inventory',
    icon: Icons.inventory,
    builder: (_) => const InventoryScreen(),
    sidebarOrder: 3,
  ),
  DashboardSection(
    key: 'orderAnalytics',
    title: 'Order Analytics',
    icon: Icons.analytics_outlined,
    builder: (_) => const AnalyticsScreen(),
    sidebarOrder: 4,
  ),
  DashboardSection(
    key: 'orderManagement',
    title: 'Orders',
    icon: Icons.receipt_long_outlined,
    builder: (_) => const OrderManagementScreen(),
    sidebarOrder: 5,
  ),
  DashboardSection(
    key: 'feedbackManagement',
    title: 'Feedback',
    icon: Icons.feedback_outlined,
    builder: (_) => const FeedbackManagementScreen(),
    sidebarOrder: 6,
  ),
  DashboardSection(
    key: 'promoManagement',
    title: 'Promotions',
    icon: Icons.card_giftcard_outlined,
    builder: (_) => const PromoManagementScreen(),
    sidebarOrder: 7,
  ),
  DashboardSection(
    key: 'staffAccess',
    title: 'Staff',
    icon: Icons.people_outline,
    builder: (_) => const StaffAccessScreen(),
    sidebarOrder: 8,
  ),
  DashboardSection(
    key: 'featureSettings',
    title: 'Feature Toggles',
    icon: Icons.toggle_on_outlined,
    builder: (_) => const FeatureSettingsScreen(),
    sidebarOrder: 9,
  ),
  DashboardSection(
    key: 'chatManagement',
    title: 'Support Chat',
    icon: Icons.chat_bubble_outline,
    builder: (_) => const ChatManagementScreen(),
    sidebarOrder: 10,
  ),

  // ---- Plugin or Franchise-specific Section Example ----
  // DashboardSection(
  //   key: 'customPluginSection',
  //   title: 'Loyalty Program',
  //   icon: Icons.card_membership,
  //   builder: (_) => const LoyaltyProgramScreen(),
  //   sidebarOrder: 11,
  //   showInSidebar: true,
  // ),
];

/// Easily sort or filter sections for the sidebar/nav.
List<DashboardSection> getSidebarSections() =>
    sectionRegistry.where((s) => s.showInSidebar).toList()
      ..sort((a, b) => a.sidebarOrder.compareTo(b.sidebarOrder));
