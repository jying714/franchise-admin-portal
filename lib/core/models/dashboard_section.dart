import 'package:flutter/material.dart';

class DashboardSection {
  final String key;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final int sidebarOrder;
  final bool showInSidebar;

  const DashboardSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.builder,
    required this.sidebarOrder,
    this.showInSidebar = true,
  });
}
