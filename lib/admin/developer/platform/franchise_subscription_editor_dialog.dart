import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscriptions_model.dart';
import 'package:provider/provider.dart';

class FranchiseSubscriptionEditorDialog extends StatefulWidget {
  final FranchiseSubscription? subscription; // null if creating new
  final String franchiseId;

  const FranchiseSubscriptionEditorDialog({
    super.key,
    required this.franchiseId,
    this.subscription,
  });

  @override
  State<FranchiseSubscriptionEditorDialog> createState() =>
      _FranchiseSubscriptionEditorDialogState();
}

class _FranchiseSubscriptionEditorDialogState
    extends State<FranchiseSubscriptionEditorDialog> {
  late DateTime _startDate;
  late DateTime _nextBillingDate;
  bool _isTrial = false;
  DateTime? _trialEndsAt;
  int _discountPercent = 0;
  String? _customQuoteDetails;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlanId;
  String _status = 'active';

  List<PlatformPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;

    _startDate = sub?.startDate ?? DateTime.now();
    _nextBillingDate =
        sub?.nextBillingDate ?? _startDate.add(const Duration(days: 30));
    _isTrial = sub?.isTrial ?? false;
    _trialEndsAt = sub?.trialEndsAt;
    _discountPercent = sub?.discountPercent ?? 0;
    _customQuoteDetails = sub?.customQuoteDetails;

    _selectedPlanId = sub?.planId;
    _status = sub?.status ?? 'active';

    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await FirestoreService.getPlatformPlans();
      setState(() {
        _plans = plans;
      });
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to load platform plans: $e',
        stack: st.toString(),
        source: 'FranchiseSubscriptionEditorDialog',
        screen: 'franchise_subscription_editor',
        severity: 'error',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context)!;
    final fs = context.read<FirestoreService>();

    try {
      final newSub = FranchiseSubscription(
        id: widget.subscription?.id ?? '',
        franchiseId: widget.franchiseId,
        planId: _selectedPlanId!,
        status: _status,
        startDate: _startDate,
        nextBillingDate: _nextBillingDate,
        isTrial: _isTrial,
        trialEndsAt: _isTrial ? _trialEndsAt : null,
        discountPercent: _discountPercent,
        customQuoteDetails: _customQuoteDetails,
        lastInvoiceId: widget.subscription?.lastInvoiceId,
        createdAt: widget.subscription?.createdAt,
        updatedAt: DateTime.now(),
      );

      await fs.saveFranchiseSubscription(newSub);
      Navigator.of(context).pop(true); // Signal success
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to save franchise subscription: $e',
        stack: st.toString(),
        source: 'FranchiseSubscriptionEditorDialog',
        screen: 'franchise_subscription_editor',
        severity: 'error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.saveFailed)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.subscription == null
          ? loc.addSubscription
          : loc.editSubscription),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.plan,
                      border: const OutlineInputBorder(),
                    ),
                    value: _selectedPlanId,
                    isExpanded: true,
                    items: _plans
                        .map((p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedPlanId = value);
                    },
                    validator: (value) =>
                        value == null ? loc.pleaseSelectAPlan : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.status,
                      border: const OutlineInputBorder(),
                    ),
                    value: _status,
                    items: [
                      DropdownMenuItem(
                          value: 'active',
                          child: Text(loc.subscriptionStatus_active)),
                      DropdownMenuItem(
                          value: 'paused',
                          child: Text(loc.subscriptionStatus_paused)),
                      DropdownMenuItem(
                          value: 'trialing',
                          child: Text(loc.subscriptionStatus_trialing)),
                      DropdownMenuItem(
                          value: 'canceled',
                          child: Text(loc.subscriptionStatus_canceled)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(loc.save),
        ),
      ],
    );
  }
}
