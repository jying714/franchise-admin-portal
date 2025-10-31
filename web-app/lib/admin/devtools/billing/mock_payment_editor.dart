import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class MockPaymentEditor extends StatefulWidget {
  const MockPaymentEditor({super.key});

  @override
  State<MockPaymentEditor> createState() => _MockPaymentEditorState();
}

class _MockPaymentEditorState extends State<MockPaymentEditor> {
  final _formKey = GlobalKey<FormState>();

  final _brandController = TextEditingController(text: 'Visa');
  final _last4Controller = TextEditingController(text: '4242');
  final _tokenIdController = TextEditingController(text: 'tok_mock_abc123');

  bool _isSaving = false;
  String? _statusMessage;

  @override
  void dispose() {
    _brandController.dispose();
    _last4Controller.dispose();
    _tokenIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final brand = _brandController.text.trim();
      final last4 = _last4Controller.text.trim();
      final tokenId = _tokenIdController.text.trim();

      await Clipboard.setData(ClipboardData(text: '''
{
  "cardBrand": "$brand",
  "cardLast4": "$last4",
  "paymentTokenId": "$tokenId"
}
'''));

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Mock payment data copied to clipboard!';
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'MockPaymentEditor error: $e',
        stack: stack.toString(),
        source: 'MockPaymentEditor',
        screen: 'mock_payment_editor',
        severity: 'error',
      );
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to generate mock data.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mock Payment Editor',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Card Brand'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _last4Controller,
                    decoration: const InputDecoration(labelText: 'Card Last 4'),
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.length != 4) {
                        return 'Must be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tokenIdController,
                    decoration: const InputDecoration(labelText: 'Token ID'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: const Icon(Icons.copy),
                    label: Text(_isSaving ? 'Copying...' : 'Copy to Clipboard'),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.contains('Failed')
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


