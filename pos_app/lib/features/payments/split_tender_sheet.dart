import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TenderLine {
  final String method; // cash | card
  final double amount;

  const TenderLine({required this.method, required this.amount});

  Map<String, dynamic> toMap() => {'method': method, 'amount': amount};
}

/// Collects split tenders until remaining due is covered (cash-complete path).
/// Card lines are allowed for UI structure but do not count toward completable
/// coverage until Phase 5.3 Terminal capture.
class SplitTenderSheet extends StatefulWidget {
  final double amountDue;
  final int maxSplitTenders;

  const SplitTenderSheet({
    super.key,
    required this.amountDue,
    this.maxSplitTenders = 3,
  });

  static Future<List<TenderLine>?> show(
    BuildContext context, {
    required double amountDue,
    int maxSplitTenders = 3,
  }) {
    return showDialog<List<TenderLine>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SplitTenderSheet(
        amountDue: amountDue,
        maxSplitTenders: maxSplitTenders,
      ),
    );
  }

  @override
  State<SplitTenderSheet> createState() => _SplitTenderSheetState();
}

class _SplitTenderSheetState extends State<SplitTenderSheet> {
  final List<TenderLine> _lines = [];
  final _amountController = TextEditingController();
  String? _error;

  double get _cashCovered => _lines
      .where((l) => l.method == 'cash')
      .fold(0.0, (sum, l) => sum + l.amount);

  double get _remaining {
    final v = widget.amountDue - _cashCovered;
    return v < 0 ? 0 : (v * 100).roundToDouble() / 100.0;
  }

  bool get _canAdd => _lines.length < widget.maxSplitTenders;

  bool get _canComplete =>
      _cashCovered + 0.001 >= widget.amountDue && _lines.isNotEmpty;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addCash() {
    final raw = double.tryParse(_amountController.text.trim());
    if (raw == null || raw <= 0) {
      setState(() => _error = 'Enter a positive cash amount');
      return;
    }
    if (!_canAdd) {
      setState(() => _error = 'Max ${widget.maxSplitTenders} tenders');
      return;
    }

    final amount = (raw * 100).roundToDouble() / 100.0;
    setState(() {
      _lines.add(TenderLine(method: 'cash', amount: amount));
      _amountController.clear();
      _error = null;
    });
  }

  void _addCardStub() {
    if (!_canAdd) {
      setState(() => _error = 'Max ${widget.maxSplitTenders} tenders');
      return;
    }
    if (_remaining <= 0) {
      setState(() => _error = 'Already covered by cash');
      return;
    }
    setState(() {
      _lines.add(TenderLine(method: 'card', amount: _remaining));
      _error =
          'Card line recorded as stub — capture needs Phase 5.3. Remove card lines to complete with cash only.';
    });
  }

  void _removeAt(int index) {
    setState(() {
      _lines.removeAt(index);
      _error = null;
    });
  }

  void _complete() {
    final hasCard = _lines.any((l) => l.method == 'card');
    if (hasCard) {
      setState(
        () => _error =
            'Remove card lines to complete (Terminal capture is Phase 5.3)',
      );
      return;
    }
    if (!_canComplete) {
      setState(() => _error = 'Cash must cover amount due');
      return;
    }
    Navigator.of(context).pop(List<TenderLine>.from(_lines));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final change = _cashCovered - widget.amountDue;

    return AlertDialog(
      title: const Text('Split payment'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Due \$${widget.amountDue.toStringAsFixed(2)} · '
                'Remaining \$${_remaining.toStringAsFixed(2)} · '
                'Max ${widget.maxSplitTenders} tenders',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_lines.isEmpty)
                Text(
                  'No tenders yet',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              else
                ...List.generate(_lines.length, (i) {
                  final line = _lines[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${line.method.toUpperCase()}  \$${line.amount.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeAt(i),
                    ),
                  );
                }),
              if (_cashCovered > widget.amountDue) ...[
                const SizedBox(height: 4),
                Text(
                  'Change \$${change.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                enabled: _canAdd,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Cash amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                onSubmitted: (_) => _addCash(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canAdd ? _addCash : null,
                      child: const Text('Add cash'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canAdd ? _addCardStub : null,
                      child: const Text('Add card (stub)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canComplete ? _complete : null,
          child: const Text('Complete split (cash)'),
        ),
      ],
    );
  }
}
