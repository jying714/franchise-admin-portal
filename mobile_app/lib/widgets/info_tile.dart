import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Robust, reusable info tile for profile and other label/value displays.
/// Handles null/empty values gracefully.
class InfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? leadingIcon;
  final Widget? trailing;

  const InfoTile({
    super.key,
    required this.label,
    this.value,
    this.leadingIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingIcon != null
          ? Icon(leadingIcon, color: shared.UiConfig.primaryColor)
          : null,
      title: Text(
        label,
        style: shared.UiConfig.bodyStyle.copyWith(
          fontWeight: shared.UiConfig.fontWeightBold,
          color: shared.UiConfig.textColor,
        ),
      ),
      subtitle: Text(
        (value == null || value!.trim().isEmpty) ? '—' : value!,
        style: shared.UiConfig.captionStyle.copyWith(
          fontWeight: shared.UiConfig.fontWeightNormal,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
