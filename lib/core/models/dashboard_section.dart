import 'package:flutter/material.dart';

class DashboardSection {
  final String key;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final int sidebarOrder;

  const DashboardSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.builder,
    required this.sidebarOrder,
  });
}
