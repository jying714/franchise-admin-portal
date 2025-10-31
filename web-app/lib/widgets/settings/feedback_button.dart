import 'package:flutter/material.dart';

class FeedbackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback coming soon!')));
      },
      icon: const Icon(Icons.feedback_outlined),
      label: const Text("Feedback"),
    );
  }
}


