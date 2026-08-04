import 'package:flutter/material.dart';

/// Circular Left / Whole / Right portion control (mobile parity).
/// [portion] is 'left' | 'whole' | 'right'.
class PortionSelector extends StatelessWidget {
  const PortionSelector({
    super.key,
    required this.portion,
    required this.onChanged,
    this.size = 28,
    this.disables,
  });

  final String portion;
  final void Function(String portion) onChanged;
  final double size;

  /// Optional: map of portion value → disabled.
  final Map<String, bool>? disables;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.outline;
    final disabledColor = scheme.onSurfaceVariant.withValues(alpha: 0.35);
    final disables = this.disables ?? const <String, bool>{};

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PortionCircle(
          portion: 'left',
          isSelected: portion == 'left',
          onTap: disables['left'] == true ? null : () => onChanged('left'),
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          disabledColor: disabledColor,
          disabled: disables['left'] == true,
          size: size,
        ),
        SizedBox(width: size * 0.2),
        _PortionCircle(
          portion: 'whole',
          isSelected: portion == 'whole',
          onTap: disables['whole'] == true ? null : () => onChanged('whole'),
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          disabledColor: disabledColor,
          disabled: disables['whole'] == true,
          size: size,
        ),
        SizedBox(width: size * 0.2),
        _PortionCircle(
          portion: 'right',
          isSelected: portion == 'right',
          onTap: disables['right'] == true ? null : () => onChanged('right'),
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          disabledColor: disabledColor,
          disabled: disables['right'] == true,
          size: size,
        ),
      ],
    );
  }
}

class _PortionCircle extends StatelessWidget {
  const _PortionCircle({
    required this.portion,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    required this.disabledColor,
    required this.disabled,
    required this.size,
  });

  final String portion;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Color disabledColor;
  final bool disabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: CustomPaint(
          size: Size(size, size),
          painter: _PortionPainter(
            portion: portion,
            isSelected: isSelected,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            disabledColor: disabledColor,
            disabled: disabled,
          ),
        ),
      ),
    );
  }
}

class _PortionPainter extends CustomPainter {
  _PortionPainter({
    required this.portion,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.disabledColor,
    required this.disabled,
  });

  final String portion;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color disabledColor;
  final bool disabled;

  @override
  void paint(Canvas canvas, Size size) {
    final color = disabled
        ? disabledColor
        : (isSelected ? activeColor : inactiveColor);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isSelected && !disabled ? 1.0 : 0.35)
      ..style = PaintingStyle.fill;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - size.width * 0.13;

    canvas.drawCircle(center, radius, outerPaint);

    switch (portion) {
      case 'left':
        final rect = Rect.fromCircle(center: center, radius: radius - 1.2);
        canvas.drawArc(rect, 3.14159 / 2, 3.14159, true, fillPaint);
        break;
      case 'whole':
        canvas.drawCircle(center, radius - 1.2, fillPaint);
        break;
      case 'right':
        final rect = Rect.fromCircle(center: center, radius: radius - 1.2);
        canvas.drawArc(rect, -3.14159 / 2, 3.14159, true, fillPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
