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
    // FranchiseProvider injected (P1 Batch 1) for franchise/{franchiseId}/ scoping centrality
    Provider.of<shared.FranchiseProvider>(context, listen: false);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDouble
              ? shared.UiConfig.primaryColor
              : shared.UiConfig.surfaceColor,
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          border: Border.all(
            color: isDouble
                ? shared.UiConfig.primaryColor
                : shared.UiConfig.secondaryTextColor.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? "Double" : "Regular",
          style: TextStyle(
            color: isDouble
                ? shared.UiConfig.onPrimaryColor
                : shared.UiConfig.textColor,
            fontWeight: shared.UiConfig.bold,
            fontSize: 14,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}
