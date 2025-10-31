import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color badgeColor;
    switch (role) {
      case 'Owner':
        badgeColor = colorScheme.primary;
        break;
      case 'Admin':
        badgeColor = colorScheme.secondary;
        break;
      default:
        badgeColor = colorScheme.tertiary ?? colorScheme.primaryContainer;
    }
    return Chip(
      label: Text(role, style: TextStyle(color: colorScheme.onPrimary)),
      backgroundColor: badgeColor,
      visualDensity: VisualDensity.compact,
      labelPadding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
}


