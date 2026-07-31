import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Robust, reusable info tile for profile and other label/value displays.
/// Handles null/empty values gracefully.
class InfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? leadingIcon;
  final Widget? trailing;

  const InfoTile({
    Key? key,
    required this.label,
    this.value,
    this.leadingIcon,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingIcon != null
          ? Icon(leadingIcon, color: DesignTokens.primaryColor)
          : null,
      title: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.bodyFontSize,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
      subtitle: Text(
        (value == null || value!.trim().isEmpty) ? '—' : value!,
        style: TextStyle(
          fontSize: DesignTokens.captionFontSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFamily: DesignTokens.fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
