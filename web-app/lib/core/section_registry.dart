import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/dashboard/dashboard_home_screen.dart';
import 'package:franchise_admin_portal/admin/menu/menu_editor_screen.dart';
import 'package:franchise_admin_portal/admin/categories/category_management_screen.dart';
import 'package:franchise_admin_portal/admin/inventory/inventory_screen.dart';
import 'package:franchise_admin_portal/admin/orders/analytics_screen.dart';
import 'package:franchise_admin_portal/admin/orders/order_management_screen.dart';
import 'package:franchise_admin_portal/admin/feedback/feedback_management_screen.dart';
import 'package:franchise_admin_portal/admin/promo/promo_management_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_access_screen.dart';
import 'package:franchise_admin_portal/admin/staff/pos_staff_roster_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_schedule_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_hours_summary_screen.dart';
import 'package:franchise_admin_portal/admin/chat/chat_management_screen.dart';
// Menu item editor lives under HQ onboarding copy after Phase 4 removal of Admin onboarding tree.
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/menu_item_editor_screen.dart';

// ==== UNIFIED SECTION REGISTRY (Admin ops only — onboarding hosts under HQ) ====
final List<shared.DashboardSection> sectionRegistry = [
  // ---- Core dashboard sections ----
  shared.DashboardSection(
    key: 'dashboardHome',
    title: 'Dashboard',
    icon: Icons.dashboard,
    builder: (_) => const DashboardHomeScreen(),
    sidebarOrder: 0,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'menuEditor',
    title: 'Menu',
    icon: Icons.local_pizza,
    builder: (_) => const MenuEditorScreen(),
    sidebarOrder: 1,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'categoryManagement',
    title: 'Categories',
    icon: Icons.category_outlined,
    builder: (_) => const CategoryManagementScreen(),
    sidebarOrder: 2,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'inventoryManagement',
    title: 'Inventory',
    icon: Icons.inventory,
    builder: (_) => const InventoryScreen(),
    sidebarOrder: 3,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'orderAnalytics',
    title: 'Order Analytics',
    icon: Icons.analytics_outlined,
    builder: (_) => const AnalyticsScreen(),
    sidebarOrder: 4,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'orderManagement',
    title: 'Orders',
    icon: Icons.receipt_long_outlined,
    builder: (_) => const OrderManagementScreen(),
    sidebarOrder: 5,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'feedbackManagement',
    title: 'Feedback',
    icon: Icons.feedback_outlined,
    builder: (_) => const FeedbackManagementScreen(),
    sidebarOrder: 6,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'promoManagement',
    title: 'Promotions',
    icon: Icons.card_giftcard_outlined,
    builder: (_) => const PromoManagementScreen(),
    sidebarOrder: 7,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'staffAccess',
    title: 'Portal users',
    icon: Icons.manage_accounts_outlined,
    builder: (_) => const StaffAccessScreen(),
    sidebarOrder: 8,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'posStaffRoster',
    title: 'Station staff',
    icon: Icons.badge_outlined,
    builder: (_) => const PosStaffRosterScreen(),
    sidebarOrder: 9,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'staffSchedule',
    title: 'Schedule',
    icon: Icons.event_available_outlined,
    builder: (_) => const StaffScheduleScreen(),
    sidebarOrder: 10,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'staffHours',
    title: 'Hours',
    icon: Icons.hourglass_bottom_outlined,
    builder: (_) => const StaffHoursSummaryScreen(),
    sidebarOrder: 11,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'chatManagement',
    title: 'Support Chat',
    icon: Icons.chat_bubble_outline,
    builder: (context) => const Scaffold(
      body: Center(
        child: Text(
          'Support Chat is available in full Admin mode only.\n\n(Admin-only feature)',
          textAlign: TextAlign.center,
        ),
      ),
    ),
    sidebarOrder: 12,
    showInSidebar: true,
  ),
  shared.DashboardSection(
    key: 'menuItemEditor',
    title: 'Menu Item Editor',
    icon: Icons.edit_note_rounded,
    builder: (_) => const MenuItemEditorScreen(),
    sidebarOrder: 99,
    showInSidebar: false,
  ),
];

// Utilities (unchanged)
List<shared.DashboardSection> getSidebarSections() =>
    sectionRegistry.where((s) => s.showInSidebar).toList()
      ..sort((a, b) => a.sidebarOrder.compareTo(b.sidebarOrder));

List<shared.DashboardSection> getAllDashboardSections() =>
    sectionRegistry.toList()
      ..sort((a, b) => a.sidebarOrder.compareTo(b.sidebarOrder));
