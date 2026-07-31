import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// A reusable navigation tile for profile/account menus.
/// Handles optional icons and highlight states.
/// P2: All colors (primary/adminPrimary/text) now respect live FranchiseProvider via shared.UiConfig.
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
                  ? shared.UiConfig
                      .adminPrimaryColor // admin chrome; leave if web/admin-only
                  : Theme.of(context).colorScheme.primary,
            )
          : null,
      title: Text(
        label,
        style: shared.UiConfig.bodyStyle.copyWith(
          color: highlight
              ? shared.UiConfig.adminPrimaryColor
              : shared.UiConfig.textColor,
          fontWeight: shared.UiConfig.fontWeightBold,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
