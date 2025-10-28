import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/core/models/feedback_entry.dart'
    as model;

class FeedbackDetailDialog extends StatelessWidget {
  final model.FeedbackEntry feedback;
  const FeedbackDetailDialog({Key? key, required this.feedback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feedback Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating: ${feedback.rating}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Comment: ${feedback.comment}'),
          ],
          const SizedBox(height: 8),
          Text('Categories: ${feedback.categories.join(', ')}'),
          const SizedBox(height: 8),
          Text('Timestamp: ${feedback.timestamp}'),
          const SizedBox(height: 8),
          Text('User ID: ${feedback.userId}'),
          const SizedBox(height: 8),
          Text('Order ID: ${feedback.orderId}'),
          const SizedBox(height: 8),
          Text('Anonymous: ${feedback.anonymous ? "Yes" : "No"}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
