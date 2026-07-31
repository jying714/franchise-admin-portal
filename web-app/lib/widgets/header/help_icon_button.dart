import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/help/help_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class HelpIconButton extends StatelessWidget {
  const HelpIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help & Support',
      icon: Icon(
        Icons.help_outline,
        color: DesignTokens.primaryColor,
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const HelpDialog(),
      ),
    );
  }
}
