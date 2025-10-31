import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

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


