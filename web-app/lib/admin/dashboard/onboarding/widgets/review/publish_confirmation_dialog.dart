// File: lib/admin/dashboard/onboarding/widgets/review/publish_confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/onboarding_validation_issue.dart';

/// Confirmation modal shown before onboarding publish.
/// - Lists any remaining blocking issues (should be empty if UI is correct)
/// - Requires user to type "CONFIRM" to proceed
/// - Strongly worded, a11y-friendly, and visually consistent
class PublishConfirmationDialog extends StatefulWidget {
  /// Pass any remaining blocking issues. If nonempty, disables publish.
  final List<OnboardingValidationIssue> blockingIssues;

  const PublishConfirmationDialog({
    Key? key,
    required this.blockingIssues,
  }) : super(key: key);

  @override
  State<PublishConfirmationDialog> createState() =>
      _PublishConfirmationDialogState();
}

class _PublishConfirmationDialogState extends State<PublishConfirmationDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _showValidationError = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _inputValid =>
      _confirmController.text.trim().toUpperCase() == "CONFIRM";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPublish = widget.blockingIssues.isEmpty && _inputValid;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminDialogRadius),
      ),
      backgroundColor: colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.rocket_launch_rounded,
              color: colorScheme.primary, size: 26),
          const SizedBox(width: 10),
          const Text(
            "Ready to Publish?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Publishing will move your franchise from onboarding to LIVE status. This will:",
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.93),
                fontSize: 15.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 17),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                      "Make your menu and info visible to staff and customers."),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 17),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                      "Prevent further onboarding edits unless unlocked by an admin."),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Show issues if any (should be empty unless a critical bug in UI)
            if (widget.blockingIssues.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "The following issues must be fixed before publishing:",
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ...widget.blockingIssues.map((issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.error, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                issue.message,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                ],
              ),
            // Confirmation prompt
            if (widget.blockingIssues.isEmpty) ...[
              Text(
                "Type CONFIRM to enable publishing:",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                autofocus: true,
                onChanged: (_) {
                  if (_showValidationError) {
                    setState(() {
                      _showValidationError = false;
                    });
                  } else {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  hintText: "CONFIRM",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  errorText: _showValidationError && !_inputValid
                      ? "Please type CONFIRM to enable publishing."
                      : null,
                ),
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.3,
                  color: colorScheme.primary,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 10),
            ],
            if (_showValidationError &&
                !_inputValid &&
                widget.blockingIssues.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3.5),
                child: Text(
                  "You must type CONFIRM (all caps) to proceed.",
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text("Publish & Go Live"),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canPublish ? colorScheme.primary : colorScheme.outlineVariant,
            foregroundColor: canPublish
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withOpacity(0.68),
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            elevation: canPublish ? 2.5 : 0,
          ),
          onPressed: !canPublish
              ? null
              : () {
                  if (!_inputValid) {
                    setState(() => _showValidationError = true);
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
        ),
      ],
    );
  }
}
