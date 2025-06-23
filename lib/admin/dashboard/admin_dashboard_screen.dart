import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/chat/chat_management_screen.dart';
// Import your admin features/screens here
import 'package:franchise_admin_portal/admin/menu/menu_editor_screen.dart';
import 'package:franchise_admin_portal/admin/categories/category_management_screen.dart';
import 'package:franchise_admin_portal/admin/inventory/inventory_screen.dart';
import 'package:franchise_admin_portal/admin/orders/analytics_screen.dart';
import 'package:franchise_admin_portal/admin/feedback/feedback_management_screen.dart';
import 'package:franchise_admin_portal/admin/promo/promo_management_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_access_screen.dart';
import 'package:franchise_admin_portal/admin/features/feature_settings_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // List of admin tiles for the dashboard
    final adminTiles = [
      _AdminTile(
        icon: Icons.restaurant_menu,
        color: BrandingConfig.brandRed,
        label: loc.menuEditorTitle,
        screen: const MenuEditorScreen(),
      ),
      _AdminTile(
        icon: Icons.category,
        color: Colors.deepOrange,
        label: loc.categoryManagementTitle,
        screen: const CategoryManagementScreen(),
      ),
      _AdminTile(
        icon: Icons.inventory,
        color: Colors.indigo,
        label: loc.inventoryManagementTitle,
        screen: const InventoryScreen(),
      ),
      _AdminTile(
        icon: Icons.analytics,
        color: Colors.teal,
        label: loc.orderAnalyticsTitle,
        screen: const AnalyticsScreen(),
      ),
      _AdminTile(
        icon: Icons.feedback,
        color: Colors.amber,
        label: loc.feedbackManagementTitle,
        screen: const FeedbackManagementScreen(),
      ),
      _AdminTile(
        icon: Icons.local_offer,
        color: Colors.green,
        label: loc.promoManagementTitle,
        screen: const PromoManagementScreen(),
      ),
      _AdminTile(
        icon: Icons.people,
        color: Colors.blueGrey,
        label: loc.staffAccessTitle,
        screen: const StaffAccessScreen(),
      ),
      _AdminTile(
        icon: Icons.settings,
        color: Colors.purple,
        label: loc.featureSettingsTitle,
        screen: const FeatureSettingsScreen(),
      ),
      _AdminTile(
        icon: Icons.chat,
        color: Colors.deepPurple,
        label: 'Chat Management',
        screen: const ChatManagementScreen(),
      ),
      // Add more tiles as you add features!
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminDashboardTitle),
        backgroundColor: BrandingConfig.brandRed,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adminTiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, i) => adminTiles[i],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget screen;

  const _AdminTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha((0.10 * 255).toInt()),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 42),
              const SizedBox(height: 18),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
