import 'package:flutter/material.dart';

class AnalyticsPlaceholderCard extends StatelessWidget {
  final String title;
  const AnalyticsPlaceholderCard({Key? key, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Center(
              child: Icon(Icons.show_chart,
                  size: 46, color: colorScheme.surfaceVariant),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                "Coming Soon",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


