import 'package:flutter/material.dart';

enum Portion { left, whole, right }

class PortionSelector extends StatelessWidget {
  final Portion value;
  final void Function(Portion) onChanged;
  final double size;

  /// New: Map<Portion, bool> disables. If null, all enabled. Example: {Portion.left: true}
  final Map<Portion, bool>? disables;

  const PortionSelector({
    Key? key,
    required this.value,
    required this.onChanged,
    this.size = 24,
    this.disables, // <-- Optional: not required for existing usage!
  }) : super(key: key);

  Color get _activeColor => Colors.teal.shade700;
  Color get _inactiveColor => Colors.grey.shade400;
  Color get _disabledColor => Colors.grey.shade300;

  @override
  Widget build(BuildContext context) {
    final disables = this.disables ?? {};
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PortionCircle(
          portion: Portion.left,
          isSelected: value == Portion.left,
          onTap: disables[Portion.left] == true
              ? null
              : () => onChanged(Portion.left),
          activeColor: _activeColor,
          inactiveColor: _inactiveColor,
          disabledColor: _disabledColor,
          disabled: disables[Portion.left] == true,
          size: size,
        ),
        SizedBox(width: size * 0.2),
        _PortionCircle(
          portion: Portion.whole,
          isSelected: value == Portion.whole,
          onTap: disables[Portion.whole] == true
              ? null
              : () => onChanged(Portion.whole),
          activeColor: _activeColor,
          inactiveColor: _inactiveColor,
          disabledColor: _disabledColor,
          disabled: disables[Portion.whole] == true,
          size: size,
        ),
        SizedBox(width: size * 0.2),
        _PortionCircle(
          portion: Portion.right,
          isSelected: value == Portion.right,
          onTap: disables[Portion.right] == true
              ? null
              : () => onChanged(Portion.right),
          activeColor: _activeColor,
          inactiveColor: _inactiveColor,
          disabledColor: _disabledColor,
          disabled: disables[Portion.right] == true,
          size: size,
        ),
      ],
    );
  }
}

class _PortionCircle extends StatelessWidget {
  final Portion portion;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Color disabledColor;
  final bool disabled;
  final double size;

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
  final Portion portion;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color disabledColor;
  final bool disabled;

  _PortionPainter({
    required this.portion,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.disabledColor,
    required this.disabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color =
        disabled ? disabledColor : (isSelected ? activeColor : inactiveColor);

    final fillPaint = Paint()
      ..color = color.withOpacity(isSelected && !disabled ? 1.0 : 0.35)
      ..style = PaintingStyle.fill;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - size.width * 0.13;

    // Draw outer circle
    canvas.drawCircle(center, radius, outerPaint);

    // Draw inside (based on portion)
    switch (portion) {
      case Portion.left:
        final rect = Rect.fromCircle(center: center, radius: radius - 1.2);
        canvas.drawArc(rect, 3.14 / 2, 3.14, true, fillPaint);
        break;
      case Portion.whole:
        canvas.drawCircle(center, radius - 1.2, fillPaint);
        break;
      case Portion.right:
        final rect = Rect.fromCircle(center: center, radius: radius - 1.2);
        canvas.drawArc(rect, -3.14 / 2, 3.14, true, fillPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


