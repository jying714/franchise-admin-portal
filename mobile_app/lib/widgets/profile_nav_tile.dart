import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

/// A reusable navigation tile for profile/account menus.
/// Handles optional icons and highlight states.
class ProfileNavTile extends StatelessWidget {
  final String label;
  final Widget destination;
  final IconData? icon;
  final bool highlight;

  const ProfileNavTile({
    Key? key,
    required this.label,
    required this.destination,
    this.icon,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: highlight
                  ? DesignTokens.adminPrimaryColor
                  : DesignTokens.primaryColor,
            )
          : null,
      title: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.bodyFontSize,
          color: highlight
              ? DesignTokens.adminPrimaryColor
              : DesignTokens.textColor,
          fontFamily: DesignTokens.fontFamily,
          fontWeight: DesignTokens.bodyFontWeight,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward,
        color: DesignTokens.primaryColor,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
