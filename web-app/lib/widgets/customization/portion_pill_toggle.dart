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
          color:
              isDouble ? DesignTokens.primaryColor : DesignTokens.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDouble
                ? DesignTokens.primaryColor
                : DesignTokens.secondaryTextColor.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          isDouble ? "Double" : "Regular",
          style: TextStyle(
            color: isDouble ? Colors.white : DesignTokens.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}


