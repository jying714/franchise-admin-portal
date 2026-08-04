import 'package:flutter/material.dart';

/// Regular / Double pill toggle (mobile parity).
class PortionPillToggle extends StatelessWidget {
  const PortionPillToggle({
    super.key,
    required this.isDouble,
    required this.onTap,
  });

  final bool isDouble;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDouble ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDouble ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? 'Double' : 'Regular',
          style: TextStyle(
            color: isDouble ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
