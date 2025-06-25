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
  String _selectedSection = 'Menus';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final sections = <String, List<_AdminTile>>{
      'Menus': [
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
      ],
      'Inventory': [
        _AdminTile(
          icon: Icons.inventory,
          color: Colors.indigo,
          label: loc.inventoryManagementTitle,
          screen: const InventoryScreen(),
        ),
      ],
      'Orders': [
        _AdminTile(
          icon: Icons.analytics,
          color: Colors.teal,
          label: loc.orderAnalyticsTitle,
          screen: const AnalyticsScreen(),
        ),
      ],
      'Customers': [
        _AdminTile(
          icon: Icons.feedback,
          color: Colors.amber,
          label: loc.feedbackManagementTitle,
          screen: const FeedbackManagementScreen(),
        ),
        _AdminTile(
          icon: Icons.chat,
          color: Colors.deepPurple,
          label: 'Chat Management',
          screen: const ChatManagementScreen(),
        ),
      ],
      'Promotions': [
        _AdminTile(
          icon: Icons.local_offer,
          color: Colors.green,
          label: loc.promoManagementTitle,
          screen: const PromoManagementScreen(),
        ),
      ],
      'Staff': [
        _AdminTile(
          icon: Icons.people,
          color: Colors.blueGrey,
          label: loc.staffAccessTitle,
          screen: const StaffAccessScreen(),
        ),
      ],
      'Settings': [
        _AdminTile(
          icon: Icons.settings,
          color: Colors.purple,
          label: loc.featureSettingsTitle,
          screen: const FeatureSettingsScreen(),
        ),
      ],
    };

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
                    label: Text(loc.addMenuTab),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandingConfig.brandRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () => setState(() => _selectedSection = 'Menus'),
                  ),
                ),
              ],
            ),
          ),

          // ─── Content ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount;
                  if (width > 1200)
                    crossAxisCount = 4;
                  else if (width > 900)
                    crossAxisCount = 3;
                  else if (width > 600)
                    crossAxisCount = 2;
                  else
                    crossAxisCount = 1;

                  final tiles = sections[_selectedSection]!;

                  return GridView.builder(
                    itemCount: tiles.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 1.18,
                    ),
                    itemBuilder: (_, i) => tiles[i],
                  );
                },
              ),
            ),
          ),
        ],
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
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.screen,
  }) : super(key: key);

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
