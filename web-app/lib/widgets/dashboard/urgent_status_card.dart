import 'package:flutter/material.dart';

class UrgentStatusCard extends StatelessWidget {
  final List<String>? alerts;
  const UrgentStatusCard({Key? key, this.alerts}) : super(key: key);

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
                Icon(Icons.warning_rounded, color: colorScheme.error, size: 24),
                SizedBox(width: 8),
                Text("Urgent Actions",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.error,
                        )),
              ],
            ),
            SizedBox(height: 12),
            alerts == null || alerts!.isEmpty
                ? Center(
                    child: Text("No urgent actions!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5))),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: alerts!.length,
                      itemBuilder: (context, idx) => ListTile(
                        leading: Icon(Icons.error_outline,
                            color: colorScheme.error, size: 20),
                        title: Text(alerts![idx],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colorScheme.error)),
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


