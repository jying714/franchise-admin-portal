import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/models/franchise_subscription_model.dart';
import 'package:admin_portal/core/services/franchise_subscription_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/services/firestore_service.dart';

class SubscriptionStateToggler extends StatefulWidget {
  const SubscriptionStateToggler({super.key});

  @override
  State<SubscriptionStateToggler> createState() =>
      _SubscriptionStateTogglerState();
}

class _SubscriptionStateTogglerState extends State<SubscriptionStateToggler> {
  FranchiseSubscription? _selectedSubscription;
  String? _selectedState;
  bool _saving = false;

  final _states = ['active', 'paused', 'cancelled'];

  Future<void> _updateStatus() async {
    if (_selectedSubscription == null || _selectedState == null) return;
    setState(() => _saving = true);

    try {
      await FranchiseSubscriptionService().updateFranchiseSubscription(
        documentId: _selectedSubscription!.id,
        data: {
          'status': _selectedState,
          'active': _selectedState == 'active',
        },
      );

      await ErrorLogger.log(
        message: 'Manually updated subscription status',
        source: 'SubscriptionStateToggler',
        screen: 'subscription_dev_tools_screen',
        contextData: {
          'franchiseId': _selectedSubscription!.franchiseId,
          'newStatus': _selectedState,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericSavedSuccess),
          ),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update subscription status: $e',
        source: 'SubscriptionStateToggler',
        screen: 'subscription_dev_tools_screen',
        severity: 'error',
        stack: stack.toString(),
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<FranchiseSubscription>>(
      stream: FranchiseSubscriptionService().watchAllFranchiseSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subscriptions = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.toggleSubscriptionTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<FranchiseSubscription>(
              value: _selectedSubscription != null
                  ? subscriptions.firstWhere(
                      (s) => s.id == _selectedSubscription!.id,
                      orElse: () => subscriptions.first,
                    )
                  : null,
              items: subscriptions.map((sub) {
                return DropdownMenuItem(
                  value: sub,
                  child: Text('${sub.franchiseId} (${sub.status})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubscription = val;
                  _selectedState = val?.status;
                });
              },
              decoration: InputDecoration(
                labelText: loc.selectFranchise,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedState,
              items: _states.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedState = val),
              decoration: InputDecoration(
                labelText: loc.statusLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(loc.save),
              onPressed: _saving ? null : _updateStatus,
            ),
            const SizedBox(height: 20),
            if (_selectedSubscription != null) ...[
              Text(
                  '${loc.franchiseIdLabel}: ${_selectedSubscription!.franchiseId}'),
              Text(
                  '${loc.startDateLabel}: ${_selectedSubscription!.startDate.toIso8601String()}'),
              Text(
                  '${loc.nextBillingDateLabel}: ${_selectedSubscription!.nextBillingDate.toIso8601String()}'),
            ],
          ],
        );
      },
    );
  }
}
