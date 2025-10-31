import 'package:flutter/material.dart';

class NotificationsPanel extends StatelessWidget {
  final List<String>? notifications;
  const NotificationsPanel({Key? key, this.notifications}) : super(key: key);

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
            Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: colorScheme.primary, size: 24),
                SizedBox(width: 8),
                Text("Notifications",
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            SizedBox(height: 12),
            notifications == null || notifications!.isEmpty
                ? Center(
                    child: Text(
                      "You're all caught up!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: notifications!.length,
                      itemBuilder: (context, idx) => ListTile(
                        leading: Icon(Icons.notifications,
                            color: colorScheme.primary, size: 18),
                        title: Text(notifications![idx],
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


