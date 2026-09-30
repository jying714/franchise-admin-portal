import 'package:flutter/material.dart';

/// Station 0–9 pad. Digits only; max 8. No system keyboard.
class PosPinPad extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int maxLength;
  final VoidCallback? onChanged;

  const PosPinPad({
    super.key,
    required this.controller,
    this.enabled = true,
    this.maxLength = 8,
    this.onChanged,
  });

  void _digit(String d) {
    if (!enabled) return;
    if (controller.text.length >= maxLength) return;
    controller.text = '${controller.text}$d';
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged?.call();
  }

  void _backspace() {
    if (!enabled) return;
    final t = controller.text;
    if (t.isEmpty) return;
    controller.text = t.substring(0, t.length - 1);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onPressed, IconData? icon}) {
      return SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: enabled ? (onPressed ?? () => _digit(label)) : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: icon != null ? Icon(icon, size: 22) : Text(label),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: key('1')),
            const SizedBox(width: 8),
            Expanded(child: key('2')),
            const SizedBox(width: 8),
            Expanded(child: key('3')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: key('4')),
            const SizedBox(width: 8),
            Expanded(child: key('5')),
            const SizedBox(width: 8),
            Expanded(child: key('6')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: key('7')),
            const SizedBox(width: 8),
            Expanded(child: key('8')),
            const SizedBox(width: 8),
            Expanded(child: key('9')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: key(
                '⌫',
                onPressed: _backspace,
                icon: Icons.backspace_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: key('0')),
            const SizedBox(width: 8),
            Expanded(
              child: key(
                'C',
                onPressed: enabled
                    ? () {
                        controller.clear();
                        onChanged?.call();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
