import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class DashboardSwitcherDropdown extends StatelessWidget {
  final String currentScreen;
  final shared.User? user;

  const DashboardSwitcherDropdown({
    super.key,
    required this.currentScreen,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null || user == null) {
      return const SizedBox.shrink();
    }

    final roles = user!.roles;

    if (!roles.any((r) => [
          'platform_owner',
          'hq_owner',
          'hq_manager',
          'developer'
        ].contains(r))) {
      return const SizedBox.shrink();
    }

    final options = <_DashboardTarget>[
      if (roles.contains('hq_owner') || roles.contains('hq_manager'))
        _DashboardTarget(
          key: 'hq',
          label: loc.ownerHQDashboardTitle ?? 'HQ Dashboard',
          route: '/hq-owner/dashboard',
        ),
      if (roles.contains('platform_owner') || roles.contains('developer'))
        _DashboardTarget(
          key: 'platform_owner',
          label: loc.platformOwnerDashboardTitle ?? 'Platform Owner Dashboard',
          route: '/platform-owner/dashboard',
        ),
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
    ];

    final normalized = currentScreen.toLowerCase();

    // Prefer explicit key / full route match. Do NOT match only the last
    // path segment ("dashboard") — HQ, Admin, Platform all end that way.
    final current = options.firstWhere(
      (opt) {
        final route = opt.route.toLowerCase();
        final key = opt.key.toLowerCase();
        if (normalized == route) return true;
        if (normalized.contains('/$key/') || normalized.endsWith('/$key')) {
          return true;
        }
        // Explicit aliases used as currentScreen values
        if (key == 'hq' &&
            (normalized.contains('hq-owner') ||
                normalized.contains('owner-hq') ||
                normalized.contains('hq_owner'))) {
          return true;
        }
        if (key == 'admin' &&
            (normalized.contains('/admin') || normalized.startsWith('admin'))) {
          return true;
        }
        if (key == 'platform_owner' && normalized.contains('platform')) {
          return true;
        }
        if (key == 'developer' && normalized.contains('developer')) {
          return true;
        }
        return false;
      },
      orElse: () => options.firstWhere(
        (opt) => opt.key == 'admin',
        orElse: () => options.first,
      ),
    );

    debugPrint(
        '[DashboardSwitcherDropdown] currentScreen="$currentScreen" → Selected="${current.label}"');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButton<_DashboardTarget>(
      value: current,
      icon: Icon(Icons.keyboard_arrow_down,
          color: isDark ? Colors.white : Colors.black),
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600),
      underline: const SizedBox.shrink(),
      onChanged: (selected) {
        if (selected == null) return;

        try {
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed(selected.route);
        } catch (e, stack) {
          shared.ErrorLogger.log(
            message: 'Navigation failed to ${selected.route}',
            source: 'DashboardSwitcherDropdown',
            severity: 'error',
            stack: stack.toString(),
            contextData: {
              'currentScreen': currentScreen,
              'target': selected.route
            },
          );
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed('/admin/dashboard');
        }
      },
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt.label)))
          .toList(),
    );
  }
}

class _DashboardTarget {
  final String key;
  final String label;
  final String route;
  _DashboardTarget(
      {required this.key, required this.label, required this.route});
}
