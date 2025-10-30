import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual build/version in a real app
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("About", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text("Doughboys Franchise Admin Portal"),
        Text("Version: 1.0.0 (build 100)"),
        const SizedBox(height: 8),
        Text("© 2025 Doughboys Inc. All rights reserved.",
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
