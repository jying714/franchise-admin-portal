import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class PortionPillToggle extends StatelessWidget {
  final bool isDouble;
  final VoidCallback onTap;

  const PortionPillToggle({
    Key? key,
    required this.isDouble,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDouble
              ? DesignTokens.primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDouble
                ? DesignTokens.primaryColor
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? "Double" : "Regular",
          style: TextStyle(
            color: isDouble
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}
