﻿// Mobile canonical in mobile_app/lib/widgets/header/.
// Web version kept for admin portal only. Safe for deletion in next batch
// if admin can reuse customer header widgets via shared_ui package or path dep.
// Current: uses local DesignTokens (appropriate for admin theming).
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A modular profile icon button for AppBars, easily reused across the app.
/// Supports custom icon, tooltip, color, and onPressed logic.
class ProfileIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double? iconSize;

  const ProfileIconButton({
    Key? key,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.person,
        size: iconSize ?? DesignTokens.iconSize,
        color: iconColor ?? DesignTokens.foregroundColor,
        semanticLabel: tooltip,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
