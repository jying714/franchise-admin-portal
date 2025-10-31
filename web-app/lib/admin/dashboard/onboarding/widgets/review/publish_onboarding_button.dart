// File: lib/admin/dashboard/onboarding/widgets/review/publish_onboarding_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../package:shared_core/src/core/providers/onboarding_review_provider.dart';
import 'package:franchise_admin_portal/widgets/confirmation_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/review/publish_confirmation_dialog.dart';
import '../package:shared_core/src/core/models/onboarding_validation_issue.dart';

// You will implement PublishConfirmationDialog as a separate file/component

class PublishOnboardingButton extends StatefulWidget {
  final String franchiseId;
  final String userId;

  const PublishOnboardingButton({
    Key? key,
    required this.franchiseId,
    required this.userId,
  }) : super(key: key);

  @override
  State<PublishOnboardingButton> createState() =>
      _PublishOnboardingButtonState();
}

class _PublishOnboardingButtonState extends State<PublishOnboardingButton> {
  bool _publishing = false;
  String? _publishStatusMsg;

  Future<void> _handlePublish(
      BuildContext context, OnboardingReviewProvider provider) async {
    // Trigger confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PublishConfirmationDialog(
        blockingIssues: provider.allIssuesFlat
            .where((e) =>
                e.isBlocking && e.severity == OnboardingIssueSeverity.critical)
            .toList(),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _publishing = true;
      _publishStatusMsg = null;
    });

    try {
      await provider.publishOnboarding(
        franchiseId: widget.franchiseId,
        userId: widget.userId,
      );
      setState(() => _publishStatusMsg = "Franchise onboarding published!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Franchise onboarding published successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      // Optional: navigate to main dashboard or onboarding complete screen.
    } catch (e) {
      setState(() => _publishStatusMsg = "Publish failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish onboarding: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<OnboardingReviewProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final canPublish = reviewProvider.isPublishable && !_publishing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: _publishing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2.2,
                  ),
                )
              : const Icon(Icons.rocket_launch_rounded),
          label: Text(
            _publishing ? "Publishing..." : "Publish / Go Live",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canPublish ? colorScheme.primary : colorScheme.outlineVariant,
            foregroundColor: canPublish
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withOpacity(0.61),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            elevation: canPublish ? 2.5 : 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed:
              canPublish ? () => _handlePublish(context, reviewProvider) : null,
        ),
        if (_publishStatusMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              _publishStatusMsg!,
              style: TextStyle(
                color: _publishStatusMsg!.toLowerCase().contains('fail')
                    ? colorScheme.error
                    : colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
      ],
    );
  }
}


