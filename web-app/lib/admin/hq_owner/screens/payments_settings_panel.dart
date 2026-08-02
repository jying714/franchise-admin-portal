// web-app/lib/admin/hq_owner/screens/payments_settings_panel.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:url_launcher/url_launcher.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Restaurant settings → Payments (hq-restaurant-settings-v1 S6).
/// Same Connect callables as CustomerCardPaymentsStatusCard.
class PaymentsSettingsPanel extends StatefulWidget {
  const PaymentsSettingsPanel({super.key});

  @override
  State<PaymentsSettingsPanel> createState() => _PaymentsSettingsPanelState();
}

class _PaymentsSettingsPanelState extends State<PaymentsSettingsPanel> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOnboarding(String franchiseId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('createConnectAccountLink');
    final result = await callable.call(<String, dynamic>{
      'franchiseId': franchiseId,
      'returnUrl': 'https://franchisehq.io/',
      'refreshUrl': 'https://franchisehq.io/',
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = data['url'] as String?;
    final accountId = data['accountId'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('No onboarding URL returned');
    }

    if (accountId != null && accountId.isNotEmpty) {
      final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
      final merged = Map<String, dynamic>.from(fp.currentBranding)
        ..['stripeConnectAccountId'] = accountId
        ..['paymentsEnabled'] = false;
      fp.setBrandingFromFranchiseDoc(merged);
    }

    final ok = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    if (!ok) {
      throw StateError('Could not open Stripe onboarding link');
    }
  }

  Future<void> _refreshStatus(String franchiseId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('refreshConnectAccountStatus');
    final result = await callable.call(<String, dynamic>{
      'franchiseId': franchiseId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final merged = Map<String, dynamic>.from(fp.currentBranding)
      ..['paymentsEnabled'] = data['paymentsEnabled'] == true
      ..['stripeConnectStatus'] = data['stripeConnectStatus']
      ..['stripeConnectAccountId'] = data['stripeConnectAccountId'];
    fp.setBrandingFromFranchiseDoc(merged);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          data['paymentsEnabled'] == true
              ? 'Card payments enabled'
              : 'Status updated — card payments still blocked',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = fp.franchiseId;
    final enabled = fp.paymentsEnabled;
    final accountId = fp.stripeConnectAccountId;
    final status = fp.stripeConnectStatus;
    final canAct = franchiseId.isNotEmpty && franchiseId != 'unknown';

    final String headline;
    final String detail;
    if (enabled) {
      headline = 'Card payments enabled';
      detail = status != null && status.isNotEmpty
          ? 'Connect status: $status'
          : 'Ready to accept customer card orders.';
    } else if (accountId != null && accountId.isNotEmpty) {
      headline = 'Connect onboarding incomplete';
      detail = status != null && status.isNotEmpty
          ? 'Status: $status — card checkout stays blocked.'
          : 'Account linked but not ready — card checkout blocked.';
    } else {
      headline = 'Card payments not set up';
      detail =
          'Customers cannot pay by card until Stripe Connect is completed.';
    }

    return ListView(
      padding: EdgeInsets.all(DesignTokens.paddingLg),
      children: [
        Text(
          'Customer card payments (Stripe Connect)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: DesignTokens.adminCardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      enabled
                          ? Icons.check_circle_outline
                          : Icons.payments_outlined,
                      color: enabled
                          ? DesignTokens.primaryColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headline,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (accountId != null && accountId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Account: $accountId',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: (!canAct || _busy)
                          ? null
                          : () => _run(() => _startOnboarding(franchiseId)),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                        foregroundColor: DesignTokens.foregroundColor,
                      ),
                      child: Text(
                        accountId == null || accountId.isEmpty
                            ? 'Set up card payments'
                            : 'Continue onboarding',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: (!canAct || _busy)
                          ? null
                          : () => _run(() => _refreshStatus(franchiseId)),
                      child: const Text('Refresh status'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Checkout fails closed when payments are not enabled. '
          'HQ dashboard card remains until cleanup (S8).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
