import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';

class AdminBottomNavBar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final void Function(int index) onTap;

  const AdminBottomNavBar({
    Key? key,
    required this.sections,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).iconTheme.color?.withOpacity(0.6),
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
