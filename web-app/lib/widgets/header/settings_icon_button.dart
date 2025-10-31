import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/settings/settings_dialog.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: 'Settings',
      icon: Icon(
        Icons.settings,
        color: isDark ? Colors.white : Colors.black,
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const SettingsDialog(),
      ),
    );
  }
}


