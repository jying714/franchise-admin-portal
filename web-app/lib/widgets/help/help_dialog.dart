import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/help/contact_support_section.dart';
import 'package:franchise_admin_portal/widgets/help/faq_section.dart';
import 'package:franchise_admin_portal/widgets/help/release_notes_section.dart';
import 'package:franchise_admin_portal/widgets/help/shortcuts_guide_section.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({Key? key}) : super(key: key);

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
            Text("Help & Support",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ContactSupportSection(),
            const Divider(height: 32),
            FAQSection(),
            const Divider(height: 32),
            ReleaseNotesSection(),
            const Divider(height: 32),
            ShortcutsGuideSection(),
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


