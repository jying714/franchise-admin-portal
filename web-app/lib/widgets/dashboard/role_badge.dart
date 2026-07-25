import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color badgeColor;
    switch (role) {
      case 'Owner':
        badgeColor = DesignTokens.primaryColor;
        break;
      case 'Admin':
        badgeColor = DesignTokens.secondaryColor;
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
