import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/platform_invoice.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';

class PayInvoiceDialog extends StatefulWidget {
  final PlatformInvoice invoice;

  const PayInvoiceDialog({Key? key, required this.invoice}) : super(key: key);

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
      allowedRoles: ['developer'],
      featureName: 'PayPlatformInvoice',
      screen: 'PayInvoiceDialog',
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
                      await FirestoreService().markPlatformInvoicePaid(
                          widget.invoice.id!, _selectedMethod!);
                      Navigator.of(context).pop(true);
                    } catch (e, stack) {
                      await ErrorLogger.log(
                        message: e.toString(),
                        stack: stack.toString(),
                        source: 'PayInvoiceDialog',
                        screen: 'PayInvoiceDialog',
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
