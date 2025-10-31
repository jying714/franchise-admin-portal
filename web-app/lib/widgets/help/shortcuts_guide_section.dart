import 'package:flutter/material.dart';

class ShortcutsGuideSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Shortcuts Guide", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text("Shortcuts coming soon!"),
      ],
    );
  }
}


