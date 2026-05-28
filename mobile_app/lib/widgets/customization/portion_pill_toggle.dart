import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDouble ? UiConfig.primaryColor : UiConfig.surfaceColor,
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          border: Border.all(
            color: isDouble
                ? UiConfig.primaryColor
                : UiConfig.secondaryTextColor.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? "Double" : "Regular",
          style: TextStyle(
            color: isDouble ? Colors.white : UiConfig.textColor,
            fontWeight: UiConfig.bold,
            fontSize: 14,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}
