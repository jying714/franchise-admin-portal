import 'package:flutter/material.dart';

class ReleaseNotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Release Notes", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text("v1.0.0 - Initial release of Doughboys Franchise Admin Portal."),
        const SizedBox(height: 8),
        Text("Release notes and new features will appear here."),
      ],
    );
  }
}
