import 'package:flutter/material.dart';

class LegalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Legal", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // TODO: Link or open dialog
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms coming soon!')));
          },
          child: const Text("Terms of Service"),
        ),
        TextButton(
          onPressed: () {
            // TODO: Link or open dialog
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy coming soon!')));
          },
          child: const Text("Privacy Policy"),
        ),
      ],
    );
  }
}
