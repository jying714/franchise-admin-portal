import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../packages/shared_core/lib/src/core/models/feedback_entry.dart'
    as model;
import 'package:franchise_admin_portal/config/design_tokens.dart';

class FeedbackDetailDialog extends StatelessWidget {
  final model.FeedbackEntry feedback;

  const FeedbackDetailDialog({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isOrderFeedback = feedback.feedbackMode == 'orderExperience';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isOrderFeedback ? Icons.fastfood : Icons.app_settings_alt,
            color: isOrderFeedback
                ? DesignTokens.primaryColor
                : DesignTokens.secondaryColor,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOrderFeedback ? loc.filterOrderFeedback : loc.filterAppFeedback,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            children: List.generate(
              5,
              (idx) => Icon(
                idx < feedback.rating ? Icons.star : Icons.star_border,
                color:
                    idx < feedback.rating ? Colors.amber : Colors.grey.shade400,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedback.orderId.isNotEmpty)
              Text(
                '${loc.orderIdLabel}: ${feedback.orderId}',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            if (feedback.anonymous)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  loc.feedbackAnonymous,
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
            if (feedback.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: feedback.categories.map((catScore) {
                    final parts = catScore.split(':');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Chip(
                        label: Text(
                          parts.length > 1
                              ? '${parts[0].trim()}: ${parts[1].trim()}'
                              : catScore,
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: DesignTokens.surfaceColor,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                feedback.comment?.isNotEmpty == true
                    ? feedback.comment!
                    : (feedback.message.isNotEmpty
                        ? feedback.message
                        : loc.noMessage),
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${loc.submitted}: ${DateFormat('yyyy-MM-dd – HH:mm').format(feedback.timestamp)}',
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
            if (feedback.userId.isNotEmpty && !feedback.anonymous)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'User: ${feedback.userId}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.close),
        ),
      ],
    );
  }
}
