import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
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
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';

// Placeholder widgets (implement as needed)
class FranchiseDropdown extends StatelessWidget {
  const FranchiseDropdown({super.key});
  @override
  Widget build(BuildContext context) => DropdownButton<String>(
        value: "Default Franchise",
        onChanged: (_) {},
        items: const [
          DropdownMenuItem(
              value: "Default Franchise", child: Text("Default Franchise")),
          DropdownMenuItem(value: "Franchise 2", child: Text("Franchise 2")),
        ],
      );
}

class HelpButton extends StatelessWidget {
  const HelpButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.help_outline),
        tooltip: 'Help & Support',
        onPressed: () {
          // TODO: Show help/support dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Help & Support'),
              content: const Text('Help and support info goes here.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: () {
          // TODO: Show settings dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Settings'),
              content: const Text('Settings panel goes here.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return PopupMenuButton<String>(
      icon: const CircleAvatar(
        radius: 16,
        backgroundImage: AssetImage('assets/images/avatar_placeholder.png'),
      ),
      onSelected: (value) async {
        if (value == 'signout') {
          await authService.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        }
        // Implement 'profile' or other actions as needed
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Text('Profile')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'signout', child: Text('Sign Out')),
      ],
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

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
        titleSpacing: 0,
        backgroundColor: BrandingConfig.brandRed,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              loc.adminDashboardTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 28),
            // Franchise selector placeholder
            const FranchiseDropdown(),
          ],
        ),
        actions: const [
          HelpButton(),
          SettingsButton(),
          ProfileMenu(), // Includes sign-out
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _getColumnCount(context);
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: adminTiles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, i) => adminTiles[i],
          );
        },
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
      color: color.withAlpha((0.08 * 255).toInt()),
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 18),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
