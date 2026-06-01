import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class AdminBottomNavBar extends StatelessWidget {
  final List<shared.DashboardSection> sections;
  final int selectedIndex;
  final void Function(int index) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
      showUnselectedLabels: true,
      items: sections.map((section) {
        return BottomNavigationBarItem(
          icon: Icon(section.icon),
          label: section.title,
        );
      }).toList(),
    );
  }
}
