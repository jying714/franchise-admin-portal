import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result of a discount entry. [amount] is always dollars off the base.
class DiscountResult {
  final double amount;
  final String label;

  const DiscountResult({required this.amount, required this.label});
}

/// Percent or fixed-dollar discount. Returns [DiscountResult] or null if cancelled.
class DiscountSheet extends StatefulWidget {
  final double baseAmount;

  const DiscountSheet({super.key, required this.baseAmount});

  static Future<DiscountResult?> show(
    BuildContext context, {
    required double baseAmount,
  }) {
    return showModalBottomSheet<DiscountResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DiscountSheet(baseAmount: baseAmount),
    );
  }

  @override
  State<DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<DiscountSheet> {
  bool _percentMode = true;
  final _valueController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = double.tryParse(_valueController.text.trim());
    if (raw == null || raw <= 0) {
      setState(() => _error = 'Enter a positive value');
      return;
    }

    double amount;
    String label;

    if (_percentMode) {
      if (raw > 100) {
        setState(() => _error = 'Percent cannot exceed 100');
        return;
      }
      amount = widget.baseAmount * (raw / 100.0);
      label =
          '${raw.toStringAsFixed(raw.truncateToDouble() == raw ? 0 : 1)}% off';
    } else {
      if (raw > widget.baseAmount) {
        setState(() => _error = 'Cannot exceed amount due');
        return;
      }
      amount = raw;
      label = '\$${raw.toStringAsFixed(2)} off';
    }

    // Round to cents
    amount = (amount * 100).roundToDouble() / 100.0;
    if (amount <= 0) {
      setState(() => _error = 'Discount rounds to zero');
      return;
    }

    Navigator.of(context).pop(DiscountResult(amount: amount, label: label));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Discount', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Base \$${widget.baseAmount.toStringAsFixed(2)}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('Percent')),
              ButtonSegment<bool>(value: false, label: Text('Fixed \$')),
            ],
            selected: {_percentMode},
            onSelectionChanged: (s) {
              setState(() {
                _percentMode = s.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _percentMode ? 'Percent' : 'Amount',
              border: const OutlineInputBorder(),
              prefixText: _percentMode ? null : '\$ ',
              suffixText: _percentMode ? '%' : null,
            ),
            onSubmitted: (_) => _apply(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _apply, child: const Text('Apply discount')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
