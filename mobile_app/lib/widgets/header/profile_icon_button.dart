import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:shared_core/shared_core.dart' as shared;

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

/// A modular profile icon button for AppBars, easily reused across the app.
/// Supports custom icon, tooltip, color, and onPressed logic.
class ProfileIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double? iconSize;

  const ProfileIconButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    return IconButton(
      icon: Icon(
        Icons.person,
        size: iconSize ?? shared.DesignTokens.iconSize,
        color: iconColor ?? UiConfig.foregroundColor,
        semanticLabel: tooltip,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
