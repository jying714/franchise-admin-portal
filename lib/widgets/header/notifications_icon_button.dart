import 'package:flutter/material.dart';

class NotificationsIconButton extends StatefulWidget {
  const NotificationsIconButton({Key? key}) : super(key: key);

  @override
  State<NotificationsIconButton> createState() =>
      _NotificationsIconButtonState();
}

class _NotificationsIconButtonState extends State<NotificationsIconButton> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final int notificationCount = 0; // TODO: Replace with real data source

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
              tooltip: "Notifications",
              icon: Icon(
                Icons.notifications_none_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () async {
                setState(() => _panelOpen = !_panelOpen);
                if (_panelOpen) {
                  await showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: colorScheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox(
                        width: 340,
                        height: 400,
                        child: Center(child: Text("No notifications.")),
                        // TODO: Replace with NotificationsPanel(notifications: [])
                      ),
                    ),
                  );
                  setState(() => _panelOpen = false);
                }
              },
            ),
          ),
          if (notificationCount > 0)
            Positioned(
              right: 8,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
