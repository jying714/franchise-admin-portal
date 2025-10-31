import 'package:flutter/material.dart';

class DashboardStatCard<T extends num> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<T> Function() getValue;
  final Color? color;
  final String? tooltip;
  final String? semanticLabel;
  final String Function(T value)? formatter;

  const DashboardStatCard({
    Key? key,
    required this.label,
    required this.icon,
    required this.getValue,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.formatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).cardColor;

    return Semantics(
      label: semanticLabel ?? label,
      container: true,
      child: Tooltip(
        message: tooltip ?? label,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<T>(
              future: getValue(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading State
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 18,
                        width: 60,
                        decoration: BoxDecoration(
                          color: background.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: background.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  // Error State
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error,
                          color: Theme.of(context).colorScheme.error, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                final value = (snapshot.data ?? (T == int ? 0 : 0.0)) as T;
                final display =
                    formatter != null ? formatter!(value) : value.toString();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        icon,
                        color: cardColor,
                        size: 36,
                        semanticLabel: semanticLabel ?? label,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          display,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                          semanticsLabel: display,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


