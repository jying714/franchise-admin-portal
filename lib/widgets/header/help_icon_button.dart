import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/help/help_dialog.dart';

class HelpIconButton extends StatelessWidget {
  const HelpIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Help & Support',
      icon: Icon(Icons.help_outline, color: colorScheme.primary),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const HelpDialog(),
      ),
    );
  }
}
