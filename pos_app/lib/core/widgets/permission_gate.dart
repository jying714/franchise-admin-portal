import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pin_session_provider.dart';

/// Hides or disables [child] when the session lacks [permission].
class PermissionGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final bool disableInsteadOfHide;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.disableInsteadOfHide = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PinSessionProvider>();
    final allowed = session.hasPermission(permission);

    if (allowed) return child;

    if (disableInsteadOfHide) {
      return IgnorePointer(child: Opacity(opacity: 0.4, child: child));
    }

    return fallback ?? const SizedBox.shrink();
  }
}
