import 'package:flutter/material.dart';

class ContactSupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Contact Support", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text("Email: support@doughboyspizza.com"),
        Text("Phone: +1 (800) 555-1234"),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text("Start Live Chat"),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon!')));
          },
        ),
      ],
    );
  }
}
