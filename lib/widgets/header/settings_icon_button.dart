import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/settings/settings_dialog.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Settings',
      icon: Icon(Icons.settings, color: colorScheme.primary),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const SettingsDialog(),
      ),
    );
  }
}
