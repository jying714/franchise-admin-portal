import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/

class PayInvoiceDialog extends StatefulWidget {
  final PlatformInvoice invoice;

  PayInvoiceDialog({Key? key, required this.invoice}) : super(key: key) {
    debugPrint(
        '[PayInvoiceDialog] Constructor: invoice=${invoice.invoiceNumber}, id=${invoice.id}');
  }

  @override
  State<PayInvoiceDialog> createState() => _PayInvoiceDialogState();
}

class _PayInvoiceDialogState extends State<PayInvoiceDialog> {
  String? _selectedMethod;
  bool _loading = false;

  final List<String> _methods = ['Credit Card', 'PayPal', 'Check', 'ACH'];

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[PayInvoiceDialog] build called for invoice=${widget.invoice.invoiceNumber}');
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allowedRoles: ['developer', 'hq_owner'],
      featureName: 'PayPlatformInvoice',
      source: 'PayInvoiceDialog' /* was screen, Phase 5 */,
      child: AlertDialog(
        title: Text(loc.payInvoice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title:
                  Text('${loc.invoiceNumber}: ${widget.invoice.invoiceNumber}'),
              subtitle: Text(
                  '${loc.total}: \$${widget.invoice.amount.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: InputDecoration(
                labelText: loc.paymentMethod,
                border: const OutlineInputBorder(),
              ),
              items: _methods
                  .map((method) => DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMethod = val;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              loc.noteDevOnlyPlaceholder,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: _loading || _selectedMethod == null
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      // TODO: Replace with actual payment integration logic
                      await Provider.of<shared.FirestoreService>(context, listen: false)
                          .markPlatformInvoicePaid(
                              widget.invoice.id!, _selectedMethod!);
                      Navigator.of(context).pop(true);
                    } catch (e, stack) {
                      await shared.ErrorLogger.log(
                        message: e.toString(),
                        stack: stack.toString(),
                        source: 'PayInvoiceDialog',
                        source: 'PayInvoiceDialog' /* was screen, Phase 5 */,
                        severity: 'error',
                        contextData: {
                          'invoiceId': widget.invoice.id,
                          'method': _selectedMethod,
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.paymentFailed)),
                      );
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: _loading
                ? const CircularProgressIndicator.adaptive()
                : Text(loc.confirmPayment),
          ),
        ],
      ),
    );
  }
}






