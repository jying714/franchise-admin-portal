import 'package:flutter/material.dart';

class MaintenanceBanner extends StatelessWidget {
  final bool show;
  final String? message;
  const MaintenanceBanner({Key? key, this.show = false, this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show) return SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      content: Text(
        message ??
            "The system is in maintenance mode. Some features may be unavailable.",
        style: TextStyle(color: colorScheme.onError),
      ),
      backgroundColor: colorScheme.error,
      actions: [
        TextButton(
          onPressed: () {},
          child: Text("Dismiss", style: TextStyle(color: colorScheme.onError)),
        ),
      ],
    );
  }
}
