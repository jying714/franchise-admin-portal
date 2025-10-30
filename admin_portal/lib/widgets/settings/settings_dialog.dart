import 'package:flutter/material.dart';
import 'package:admin_portal/widgets/settings/theme_mode_selector.dart';
import 'package:admin_portal/widgets/settings/language_selector.dart';
import 'package:admin_portal/widgets/settings/about_section.dart';
import 'package:admin_portal/widgets/settings/legal_section.dart';
import 'package:admin_portal/widgets/settings/keyboard_shortcuts_section.dart';
import 'package:admin_portal/widgets/settings/support_chat_button.dart';
import 'package:admin_portal/widgets/settings/feedback_button.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colorScheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ThemeModeSelector(),
            const SizedBox(height: 16),
            LanguageSelector(),
            const Divider(height: 32),
            AboutSection(),
            const Divider(height: 32),
            LegalSection(),
            const Divider(height: 32),
            KeyboardShortcutsSection(),
            const Divider(height: 32),
            Row(
              children: [
                SupportChatButton(),
                const SizedBox(width: 20),
                FeedbackButton(),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
