import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class OnboardingTrackerWidget extends StatelessWidget {
  final Map<String, bool> checklist;
  final void Function()? onCompletePressed;

  const OnboardingTrackerWidget({
    Key? key,
    required this.checklist,
    this.onCompletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final completed = checklist.entries.where((e) => e.value).length;
    final total = checklist.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.onboardingChecklist,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.primary,
              semanticsLabel: loc.onboardingChecklist,
            ),
            const SizedBox(height: 16),
            ...checklist.entries.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    entry.value
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: entry.value
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                  title: Text(
                    _labelForKey(entry.key, loc),
                    style: theme.textTheme.bodyLarge,
                  ),
                )),
            const SizedBox(height: 12),
            if (progress == 1.0 && onCompletePressed != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(loc.markAsComplete),
                  onPressed: onCompletePressed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _labelForKey(String key, AppLocalizations loc) {
    switch (key) {
      case 'profileCompleted':
        return loc.profileCompleted;
      case 'menuUploaded':
        return loc.menuUploaded;
      case 'inventoryLoaded':
        return loc.inventoryLoaded;
      case 'staffInvited':
        return loc.staffInvited;
      case 'testOrderPlaced':
        return loc.testOrderPlaced;
      default:
        return key;
    }
  }
}
