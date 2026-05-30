import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

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
          ? Icon(leadingIcon, color: UiConfig.primaryColor)
          : null,
      title: Text(
        label,
        style: UiConfig.bodyStyle.copyWith(
          fontWeight: UiConfig.fontWeightBold,
          color: UiConfig.textColor,
        ),
      ),
      subtitle: Text(
        (value == null || value!.trim().isEmpty) ? '—' : value!,
        style: UiConfig.captionStyle.copyWith(
          fontWeight: UiConfig.fontWeightNormal,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
