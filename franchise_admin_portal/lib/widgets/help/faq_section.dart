import 'package:flutter/material.dart';

class FAQSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Frequently Asked Questions",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
            "Q: How do I reset my password?\nA: Go to settings > reset password."),
        Text("Q: How do I contact support?\nA: Use the contact section above."),
        const SizedBox(height: 8),
        Text("More FAQs coming soon...",
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
