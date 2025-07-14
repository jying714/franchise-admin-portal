// widgets/dashboard/dashboard_switcher_dropdown.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardSwitcherDropdown extends StatelessWidget {
  final String currentScreen;

  const DashboardSwitcherDropdown({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProfileNotifier>(context).user;
    final loc = AppLocalizations.of(context)!;
    print(
        '[DashboardSwitcherDropdown] build called with roles=${user?.roles}, currentScreen="$currentScreen"');
    final roles = user?.roles ?? [];

    // Only allow for hq_owner, hq_manager, developer
    if (!roles
        .any((r) => ['hq_owner', 'hq_manager', 'developer'].contains(r))) {
      return const SizedBox.shrink();
    }

    // Build the list of dashboards available to this user
    final options = <_DashboardTarget>[
      _DashboardTarget(
        key: 'admin',
        label: loc.adminDashboardTitle ?? 'Admin Dashboard',
        route: '/admin/dashboard', // <-- matches your route
      ),
      if (roles.contains('developer'))
        _DashboardTarget(
          key: 'developer',
          label: loc.developerDashboardTitle ?? 'Developer Dashboard',
          route: '/developer/dashboard', // <-- matches your route
        ),
      if (roles.contains('hq_owner') || roles.contains('hq_manager'))
        _DashboardTarget(
          key: 'hq',
          label: loc.ownerHQDashboardTitle ?? 'HQ Dashboard',
          route: '/hq-owner/dashboard', // <-- matches your route
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
      underline: SizedBox.shrink(),
      onChanged: (selected) {
        if (selected == null) return;
        if (selected.route == ModalRoute.of(context)?.settings.name)
          return; // already here
        print(
            '[DEBUG-NAV] FROM DASHBOARD SWITCHER DOPDOWN Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');

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
  _DashboardTarget(
      {required this.key, required this.label, required this.route});
}
