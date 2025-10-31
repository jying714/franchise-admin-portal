import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/models/analytics_summary.dart';

class FeedbackCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const FeedbackCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber[700], size: 22),
                            const SizedBox(width: 6),
                            Text("Overall Avg: ",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                )),
                            Text(
                              summary.feedbackStats?["averageStarRating"] !=
                                      null
                                  ? (summary.feedbackStats!["averageStarRating"]
                                          as num)
                                      .toStringAsFixed(2)
                                  : "-",
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt_rounded,
                                color: Colors.blueGrey[700], size: 20),
                            const SizedBox(width: 4),
                            Text("Feedbacks: ",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                )),
                            Text(
                              summary.feedbackStats?["totalFeedbacks"]
                                      ?.toString() ??
                                  "-",
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Participation Rate: ",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                )),
                            Text(
                              summary.feedbackStats?["participationRate"] !=
                                      null
                                  ? "${(summary.feedbackStats!["participationRate"] * 100).toStringAsFixed(1)}%"
                                  : "-",
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 16),
                    if (summary.feedbackStats?["orderFeedback"] != null)
                      _buildFeedbackSection(
                        context,
                        label: "Order Feedback (meals, delivery)",
                        data: summary.feedbackStats!["orderFeedback"],
                        icon: Icons.fastfood_rounded,
                        iconColor: Colors.red[700]!,
                      ),
                    if (summary.feedbackStats?["appFeedback"] != null)
                      _buildFeedbackSection(
                        context,
                        label: "App Feedback (ordering, UI)",
                        data: summary.feedbackStats!["appFeedback"],
                        icon: Icons.app_settings_alt_rounded,
                        iconColor: Colors.green[700]!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(
    BuildContext context, {
    required String label,
    required Map data,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              data['avgStarRating'] != null
                  ? (data['avgStarRating'] as num).toStringAsFixed(2)
                  : "-",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (data['count'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Text(
              "Count: ${data['count']}",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        if (data['avgCategories'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 6, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (data['avgCategories'] as Map).entries.map<Widget>(
                (entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        Icon(Icons.label_outline,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(
                          "${entry.key}: ",
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          entry.value != null
                              ? (entry.value as num).toStringAsFixed(2)
                              : "-",
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        const Divider(height: 18),
      ],
    );
  }
}
