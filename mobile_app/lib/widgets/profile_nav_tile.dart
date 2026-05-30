import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

/// A reusable navigation tile for profile/account menus.
/// Handles optional icons and highlight states.
/// P2: All colors (primary/adminPrimary/text) now respect live FranchiseProvider via UiConfig.
class ProfileNavTile extends StatelessWidget {
  final String label;
  final Widget destination;
  final IconData? icon;
  final bool highlight;

  const ProfileNavTile({
    super.key,
    required this.label,
    required this.destination,
    this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: highlight
                  ? UiConfig.adminPrimaryColor
                  : UiConfig.primaryColor,
            )
          : null,
      title: Text(
        label,
        style: UiConfig.bodyStyle.copyWith(
          color: highlight ? UiConfig.adminPrimaryColor : UiConfig.textColor,
          fontWeight: UiConfig.fontWeightBold,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward,
        color: UiConfig.primaryColor,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
