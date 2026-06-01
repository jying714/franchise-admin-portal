import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

class PayInvoiceDialog extends StatefulWidget {
  final shared.PlatformInvoice invoice;

  const PayInvoiceDialog({
    super.key,
    required this.invoice,
  });

  @override
  State<PayInvoiceDialog> createState() => _PayInvoiceDialogState();
}

class _PayInvoiceDialogState extends State<PayInvoiceDialog> {
  String? _selectedMethod;
  bool _loading = false;

  final List<String> _methods = ['Credit Card', 'PayPal', 'Check', 'ACH'];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allowedRoles: ['developer', 'hq_owner'],
      featureName: 'PayPlatformInvoice',
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                      await provider.Provider.of<shared.FirestoreService>(
                        context,
                        listen: false,
                      ).markPlatformInvoicePaid(
                        widget.invoice.id,
                        _selectedMethod!,
                      );
                      Navigator.of(context).pop(true);
                    } catch (e, stack) {
                      shared.ErrorLogger.log(
                        message: e.toString(),
                        stack: stack.toString(),
                        source: 'PayInvoiceDialog',
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
