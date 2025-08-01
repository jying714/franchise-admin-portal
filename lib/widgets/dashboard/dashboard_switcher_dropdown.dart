import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as app;

class DashboardSwitcherDropdown extends StatelessWidget {
  final String currentScreen;
  final app.User user;

  const DashboardSwitcherDropdown({
    super.key,
    required this.currentScreen,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[DashboardSwitcherDropdown] loc is null! Localization not available.');
      return const Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final roles = user.roles;
    print(
        '[DashboardSwitcherDropdown] build called with roles=$roles, currentScreen="$currentScreen"');

    // Only allow access if one of the supported roles is present
    if (!roles.any((r) => [
          'platform_owner',
          'hq_owner',
          'hq_manager',
          'developer'
        ].contains(r))) {
      return const SizedBox.shrink();
    }

    final options = <_DashboardTarget>[
      _DashboardTarget(
        key: 'admin',
        label: loc.adminDashboardTitle ?? 'Admin Dashboard',
        route: '/admin/dashboard',
      ),
      if (roles.contains('developer'))
        _DashboardTarget(
          key: 'developer',
          label: loc.developerDashboardTitle ?? 'Developer Dashboard',
          route: '/developer/dashboard',
        ),
      if (roles.contains('hq_owner') || roles.contains('hq_manager'))
        _DashboardTarget(
          key: 'hq',
          label: loc.ownerHQDashboardTitle ?? 'HQ Dashboard',
          route: '/hq-owner/dashboard',
        ),
      if (roles.contains('platform_owner'))
        _DashboardTarget(
          key: 'platform_owner',
          label: loc.platformOwnerDashboardTitle ?? 'Platform Owner Dashboard',
          route: '/platform-owner/dashboard',
        ),
    ];

    final current = options.firstWhere(
      (opt) => opt.route.toLowerCase().contains(currentScreen.toLowerCase()),
      orElse: () => options.first,
    );

    return DropdownButton<_DashboardTarget>(
      value: current,
      icon: const Icon(Icons.keyboard_arrow_down),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      underline: const SizedBox.shrink(),
      onChanged: (selected) {
        if (selected == null) return;
        if (selected.route == ModalRoute.of(context)?.settings.name) return;

        print(
            '[DEBUG-NAV] FROM DASHBOARD SWITCHER DROPDOWN → Navigating to ${selected.route}');
        Navigator.of(context).pushReplacementNamed(selected.route);
      },
      items: options.map((opt) {
        return DropdownMenuItem<_DashboardTarget>(
          value: opt,
          child: Text(opt.label),
        );
      }).toList(),
    );
  }
}

class _DashboardTarget {
  final String key;
  final String label;
  final String route;

  _DashboardTarget({
    required this.key,
    required this.label,
    required this.route,
  });
}
