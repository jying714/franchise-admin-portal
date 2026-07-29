import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

class PortionPillToggle extends StatelessWidget {
  final bool isDouble;
  final VoidCallback onTap;

  const PortionPillToggle({
    super.key,
    required this.isDouble,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<shared.FranchiseProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDouble ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          border: Border.all(
            color: isDouble ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? "Double" : "Regular",
          style: TextStyle(
            color: isDouble ? scheme.onPrimary : scheme.onSurface,
            fontWeight: shared.UiConfig.bold,
            fontSize: 14,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}
