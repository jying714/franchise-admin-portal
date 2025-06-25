import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/menu/menu_editor_screen.dart';
import 'package:franchise_admin_portal/admin/categories/category_management_screen.dart';
import 'package:franchise_admin_portal/admin/inventory/inventory_screen.dart';
import 'package:franchise_admin_portal/admin/orders/analytics_screen.dart';
import 'package:franchise_admin_portal/admin/feedback/feedback_management_screen.dart';
import 'package:franchise_admin_portal/admin/promo/promo_management_screen.dart';
import 'package:franchise_admin_portal/admin/staff/staff_access_screen.dart';
import 'package:franchise_admin_portal/admin/features/feature_settings_screen.dart';
import 'package:franchise_admin_portal/admin/chat/chat_management_screen.dart';

class FranchiseDropdown extends StatelessWidget {
  const FranchiseDropdown({Key? key}) : super(key: key);

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
  const HelpButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.help_outline),
        tooltip: 'Help & Support',
        onPressed: () {
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
  const SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: () {
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
  const ProfileMenu({Key? key}) : super(key: key);

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
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'signout', child: Text('Sign Out')),
      ],
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedSection = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Map each sidebar entry to its content screen
    final sections = <String, Widget>{
      loc.menuEditorTitle: const MenuEditorScreen(),
      loc.categoryManagementTitle: const CategoryManagementScreen(),
      loc.inventoryManagementTitle: const InventoryScreen(),
      loc.orderAnalyticsTitle: const AnalyticsScreen(),
      loc.feedbackManagementTitle: const FeedbackManagementScreen(),
      loc.promoManagementTitle: const PromoManagementScreen(),
      loc.staffAccessTitle: const StaffAccessScreen(),
      loc.featureSettingsTitle: const FeatureSettingsScreen(),
      'Chat Management': const ChatManagementScreen(),
    };

    // Ensure a valid default selection
    if (!sections.containsKey(_selectedSection)) {
      _selectedSection = sections.keys.first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: BrandingConfig.brandRed,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              loc.adminDashboardTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            const FranchiseDropdown(),
          ],
        ),
        actions: const [
          HelpButton(),
          SettingsButton(),
          ProfileMenu(),
        ],
      ),
      body: Row(
        children: [
          // ─── Sidebar ─────────────────────────────────────
          Container(
            width: 240,
            color: BrandingConfig.brandRed.withOpacity(0.05),
            child: ListView(
              children: [
                for (final section in sections.keys)
                  ListTile(
                    title: Text(
                      section,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: section == _selectedSection
                            ? BrandingConfig.brandRed
                            : Colors.grey[700],
                      ),
                    ),
                    selected: section == _selectedSection,
                    onTap: () => setState(() => _selectedSection = section),
                  ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(loc.menuEditorTitle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandingConfig.brandRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () => setState(
                      () => _selectedSection = loc.menuEditorTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Content ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: sections[_selectedSection],
            ),
          ),
        ],
      ),
    );
  }
}
