// web-app/lib/admin/hq_owner/screens/restaurant_settings_shell_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/design_branding_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/store_ops_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/website_settings_panel.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/contact_settings_panel.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/channels_settings_panel.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/payments_settings_panel.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/station_settings_panel.dart';

/// HQ Restaurant settings shell (slice hq-restaurant-settings-v1).
/// Top tabs only — section bodies filled in later phases.
class RestaurantSettingsShellScreen extends StatefulWidget {
  const RestaurantSettingsShellScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  /// 0 Brand · 1 Website · 2 Store ops · 3 Channels · 4 Payments · 5 Station · 6 Contact
  final int initialTabIndex;

  @override
  State<RestaurantSettingsShellScreen> createState() =>
      _RestaurantSettingsShellScreenState();
}

class _RestaurantSettingsShellScreenState
    extends State<RestaurantSettingsShellScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = <String>[
    'Brand',
    'Website',
    'Store ops',
    'Channels',
    'Payments',
    'Station',
    'Contact',
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final i = widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: i,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = fp.franchiseId;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        elevation: DesignTokens.appBarElevation,
        backgroundColor: DesignTokens.appBarBackgroundColor,
        foregroundColor: DesignTokens.appBarForegroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Restaurant settings'),
            Text(
              franchiseId.isEmpty || franchiseId == 'unknown'
                  ? 'No franchise selected'
                  : franchiseId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.appBarForegroundColor.withOpacity(0.85),
                  ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (final t in _tabs) Tab(text: t)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DesignBrandingScreen(embeddedInSettingsShell: true),
          WebsiteSettingsPanel(),
          StoreOpsScreen(embeddedInSettingsShell: true),
          ChannelsSettingsPanel(),
          PaymentsSettingsPanel(),
          StationSettingsPanel(),
          ContactSettingsPanel(),
        ],
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '$title — content lands in a later phase of hq-restaurant-settings-v1.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
