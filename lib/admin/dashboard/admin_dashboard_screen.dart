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
import 'package:franchise_admin_portal/core/theme_provider.dart';

// ------------------- FRANCHISE DROPDOWN ------------------
class FranchiseDropdown extends StatelessWidget {
  const FranchiseDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Switch franchise',
        child: DropdownButton<String>(
          value: "Default Franchise",
          onChanged: (_) {},
          items: const [
            DropdownMenuItem(
                value: "Default Franchise", child: Text("Default Franchise")),
            DropdownMenuItem(value: "Franchise 2", child: Text("Franchise 2")),
          ],
          underline: SizedBox(),
          icon: Icon(Icons.store),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
}

// ------------- HELP DIALOG: ASYNC CONTENT, ERROR/LOADING/EMPTY STATE -------------
class HelpButton extends StatelessWidget {
  const HelpButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Help & Support',
        child: Semantics(
          button: true,
          label: 'Open help and support dialog',
          child: IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const _AsyncDialog(
                  title: 'Help & Support',
                  contentBuilder: _loadHelpContent,
                ),
              );
            },
          ),
        ),
      );
}

Future<Widget> _loadHelpContent(BuildContext context) async {
  await Future.delayed(const Duration(milliseconds: 800));
  // Simulate possible error:
  // throw Exception('Failed to load support info.');
  return Text(AppLocalizations.of(context)!.helpDialogContent);
}

// -------- SETTINGS DIALOG: DARK MODE TOGGLE, ACCESSIBILITY, ASYNC DEMO -----------
class SettingsButton extends StatelessWidget {
  const SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Settings',
        child: Semantics(
          button: true,
          label: 'Open settings dialog',
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => const SettingsDialog(),
            ),
          ),
        ),
      );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.settings ?? "Settings"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(loc.themeModeLabel),
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.languageLabel),
              subtitle: Text(loc.languageSettingNote),
              onTap: () {}, // Language logic
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.close ?? "Close"),
        ),
      ],
    );
  }
}

// ------------- ASYNC DIALOG WRAPPER W/ LOADING/ERROR/EMPTY STATE SUPPORT ----------
class _AsyncDialog extends StatefulWidget {
  final String title;
  final Future<Widget> Function(BuildContext) contentBuilder;
  const _AsyncDialog({required this.title, required this.contentBuilder});
  @override
  State<_AsyncDialog> createState() => _AsyncDialogState();
}

class _AsyncDialogState extends State<_AsyncDialog> {
  late Future<Widget> _content;
  @override
  void initState() {
    super.initState();
    _content = widget.contentBuilder(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: FutureBuilder<Widget>(
        future: _content,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                height: 60, child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 8),
                Text('Failed to load content.',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                Text('${snap.error}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _content = widget.contentBuilder(context)),
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          if (snap.data == null) {
            return Text('No content found.');
          }
          return snap.data!;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
}

// ----------------------- PROFILE / SIGN OUT MENU ---------------------
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    return Semantics(
      label: 'Profile menu',
      child: PopupMenuButton<String>(
        icon: const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/images/avatar_placeholder.png'),
        ),
        tooltip: 'Profile',
        onSelected: (value) async {
          if (value == 'signout') {
            await authService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'profile', child: Text(loc.profileLabel)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'signout', child: Text(loc.signOut)),
        ],
      ),
    );
  }
}

// -------------------------- SIDEBAR WIDGET (MOBILE/DESKTOP) ----------------------
class AdminSidebar extends StatelessWidget {
  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isMobile;
  const AdminSidebar({
    required this.titles,
    required this.selectedIndex,
    required this.onSelect,
    this.isMobile = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color highlight = Theme.of(context).colorScheme.primary;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final spacing = isMobile ? 6.0 : 16.0;

    return ListView(
      children: [
        for (int i = 0; i < titles.length; i++)
          Semantics(
            button: true,
            label: 'Navigate to ${titles[i]}',
            selected: i == selectedIndex,
            child: ListTile(
              title: Text(
                titles[i],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: i == selectedIndex
                      ? highlight
                      : textColor.withOpacity(0.85),
                ),
              ),
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: spacing, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minLeadingWidth: 0,
              horizontalTitleGap: 0,
              visualDensity: VisualDensity.comfortable,
              trailing: isMobile && i == selectedIndex
                  ? Icon(Icons.chevron_right, color: highlight)
                  : null,
            ),
          ),
        SizedBox(height: isMobile ? 12 : 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Semantics(
            button: true,
            label: 'Add menu item',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(titles[0]),
              style: ElevatedButton.styleFrom(
                backgroundColor: highlight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(44),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => onSelect(0),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------- BOTTOM NAVIGATION FOR MOBILE ----------------
class AdminBottomNavBar extends StatelessWidget {
  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const AdminBottomNavBar({
    required this.titles,
    required this.selectedIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      items: [
        for (final title in titles)
          BottomNavigationBarItem(
            icon: const Icon(Icons.circle, size: 20),
            label: title.length > 12 ? title.substring(0, 12) + '…' : title,
          ),
      ],
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}

// ------------------------- MAIN DASHBOARD SCREEN ----------------------------
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<String> _sectionKeys;
  late final List<Widget> _sectionWidgets;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sectionKeys = [
      'menuEditor',
      'categoryManagement',
      'inventoryManagement',
      'orderAnalytics',
      'feedbackManagement',
      'promoManagement',
      'staffAccess',
      'featureSettings',
      'chatManagement',
    ];
    _sectionWidgets = const [
      MenuEditorScreen(),
      CategoryManagementScreen(),
      InventoryScreen(),
      AnalyticsScreen(),
      FeedbackManagementScreen(),
      PromoManagementScreen(),
      StaffAccessScreen(),
      FeatureSettingsScreen(),
      ChatManagementScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sidebarTitles = [
      loc.menuEditorTitle,
      loc.categoryManagementTitle,
      loc.inventoryManagementTitle,
      loc.orderAnalyticsTitle,
      loc.feedbackManagementTitle,
      loc.promoManagementTitle,
      loc.staffAccessTitle,
      loc.featureSettingsTitle,
      loc.chatManagementTitle,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  loc.adminDashboardTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                if (!isMobile) ...[
                  const FranchiseDropdown(),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            actions: const [
              HelpButton(),
              SettingsButton(),
              ProfileMenu(),
            ],
            elevation: 1,
          ),
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: AdminSidebar(
                      titles: sidebarTitles,
                      selectedIndex: _selectedIndex,
                      onSelect: (i) {
                        setState(() => _selectedIndex = i);
                        Navigator.of(context).pop();
                      },
                      isMobile: true,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: 240,
                  color:
                      Theme.of(context).colorScheme.surface.withOpacity(0.92),
                  child: SafeArea(
                    child: AdminSidebar(
                      titles: sidebarTitles,
                      selectedIndex: _selectedIndex,
                      onSelect: (i) => setState(() => _selectedIndex = i),
                    ),
                  ),
                ),
              Expanded(
                child: Semantics(
                  label: 'Dashboard content area',
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _sectionWidgets,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile
              ? AdminBottomNavBar(
                  titles: sidebarTitles,
                  selectedIndex: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                )
              : null,
        );
      },
    );
  }
}
