import 'package:flutter/material.dart';

class ActivityFeedWidget extends StatelessWidget {
  final List<String>? activities;
  const ActivityFeedWidget({Key? key, this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Activity",
                style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 14),
            activities == null || activities!.isEmpty
                ? Center(
                    child: Text(
                      "No recent activity.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: activities!.length,
                      itemBuilder: (context, idx) => ListTile(
                        leading: Icon(Icons.history,
                            size: 18, color: colorScheme.primary),
                        title: Text(activities![idx],
                            style: Theme.of(context).textTheme.bodyMedium),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
