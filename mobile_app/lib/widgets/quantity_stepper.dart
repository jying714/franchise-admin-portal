import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

/// A universal, reusable quantity stepper widget.
/// Accepts a value, increment/decrement callbacks, and an optional minimum/maximum.
class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int? max;
  final double fontSize;
  final double iconSize;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
    this.max,
    this.fontSize = 16.0,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = value > min;
    final bool canIncrement = max == null ? true : value < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          iconSize: iconSize,
          onPressed: canDecrement ? onDecrement : null,
          color: canDecrement
              ? DesignTokens.primaryColor
              : DesignTokens.disabledTextColor,
          splashRadius: 20,
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          iconSize: iconSize,
          onPressed: canIncrement ? onIncrement : null,
          color: canIncrement
              ? DesignTokens.primaryColor
              : DesignTokens.disabledTextColor,
          splashRadius: 20,
        ),
      ],
    );
  }
}
