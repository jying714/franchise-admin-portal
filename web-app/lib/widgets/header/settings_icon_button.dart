import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/settings/settings_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: 'Settings',
      icon: Icon(
        Icons.settings,
        color: DesignTokens.primaryColor,
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const SettingsDialog(),
      ),
    );
  }
}
