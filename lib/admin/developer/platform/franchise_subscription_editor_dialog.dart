import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';

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
  bool _cancelAtPeriodEnd = false;
  List<PlatformPlan> _plans = [];
  String? _paymentTokenId;
  String? _cardLast4;
  String? _cardBrand;
  String? _billingEmail;
  String? _paymentStatus;
  String? _receiptUrl;

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

    _selectedPlanId = sub?.platformPlanId;
    final validStatuses = ['active', 'paused', 'trialing', 'canceled'];
    _status = validStatuses.contains(sub?.status) ? sub!.status! : 'active';
    _cancelAtPeriodEnd = sub?.cancelAtPeriodEnd ?? false;
    _paymentTokenId = sub?.paymentTokenId;
    _cardLast4 = sub?.cardLast4;
    _cardBrand = sub?.cardBrand;
    _billingEmail = sub?.billingEmail;
    _paymentStatus = sub?.paymentStatus;
    _receiptUrl = sub?.receiptUrl;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await FirestoreService.getPlatformPlans();
      String? validSelectedId = _selectedPlanId;

      final planIds = plans.map((p) => p.id).toSet();
      if (validSelectedId != null && !planIds.contains(validSelectedId)) {
        validSelectedId = null; // Avoid assigning a non-existent plan
      }

      debugPrint('[DEBUG] Loaded ${plans.length} plans from Firestore');
      for (final p in plans) {
        debugPrint('[DEBUG] Plan ID: ${p.id}, name: ${p.name}');
      }
      debugPrint('[DEBUG] Current selected planId = $_selectedPlanId');

      setState(() {
        _plans = plans;

        // Ensure _selectedPlanId is only set if it's a valid option
        final matchingPlan = plans.where((p) => p.id == _selectedPlanId);
        if (_selectedPlanId == null || matchingPlan.isEmpty) {
          _selectedPlanId = null;
        }
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
      final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);
      final billingCycleInDays =
          selectedPlan.billingInterval == 'yearly' ? 365 : 30;
      final newSub = FranchiseSubscription(
        id: widget.subscription?.id ?? '',
        franchiseId: widget.franchiseId,
        platformPlanId: _selectedPlanId!,
        status: _status,
        startDate: _startDate,
        nextBillingDate: _startDate.add(Duration(days: billingCycleInDays)),
        billingCycleInDays: billingCycleInDays,
        isTrial: _isTrial,
        trialEndsAt: _isTrial ? _trialEndsAt : null,
        discountPercent: _discountPercent,
        customQuoteDetails: _customQuoteDetails,
        lastInvoiceId: widget.subscription?.lastInvoiceId,
        createdAt: widget.subscription?.createdAt,
        updatedAt: DateTime.now(),
        priceAtSubscription: widget.subscription?.priceAtSubscription ?? 0.0,
        subscribedAt: widget.subscription?.subscribedAt ?? DateTime.now(),
        cancelAtPeriodEnd: _cancelAtPeriodEnd,
        paymentTokenId: _paymentTokenId,
        cardLast4: _cardLast4,
        cardBrand: _cardBrand,
        billingEmail: _billingEmail,
        paymentStatus: _paymentStatus,
        receiptUrl: _receiptUrl,
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

    final validStatuses = ['active', 'paused', 'trialing', 'canceled'];
    final statusItems = validStatuses
        .map((s) => DropdownMenuItem(
              value: s,
              child: Text(loc.translateStatus(s)),
            ))
        .toList();

    if (!validStatuses.contains(_status)) {
      statusItems.insert(
        0,
        DropdownMenuItem(
          value: _status,
          enabled: false,
          child: Text('[Invalid status] $_status'),
        ),
      );
    }

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
                        (value == null || !_plans.any((p) => p.id == value))
                            ? loc.pleaseSelectAPlan
                            : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.status,
                      border: const OutlineInputBorder(),
                    ),
                    value: _status,
                    isExpanded: true,
                    items: statusItems,
                    onChanged: (value) {
                      if (value != null && validStatuses.contains(value)) {
                        setState(() => _status = value);
                      }
                    },
                    validator: (value) =>
                        value == null || !validStatuses.contains(value)
                            ? loc.pleaseSelectAPlan
                            : null,
                  ),
                  Tooltip(
                    message: (_status == 'paused' || _status == 'canceled')
                        ? loc.toggleLockedDueToStatus
                        : '',
                    child: SwitchListTile(
                      title: Text(loc.cancelAtPeriodEndToggle),
                      subtitle: Text(loc.cancelAtPeriodEndDescription),
                      value: _cancelAtPeriodEnd,
                      onChanged: (_status == 'paused' || _status == 'canceled')
                          ? null
                          : (val) {
                              setState(() {
                                _cancelAtPeriodEnd = val;
                              });
                            },
                      contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                      secondary: (_status == 'paused' || _status == 'canceled')
                          ? const Icon(Icons.lock_outline)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RoleGuard(
                    allowedRoles: ['platform_owner', 'developer'],
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _billingEmail,
                          decoration: InputDecoration(
                            labelText: loc.billingEmail,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (val) => _billingEmail = val.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _paymentTokenId,
                          decoration: const InputDecoration(
                            labelText: 'Payment Token (for debug)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => _paymentTokenId = val.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _cardLast4,
                          decoration: const InputDecoration(
                            labelText: 'Card Last 4',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _cardBrand,
                          decoration: const InputDecoration(
                            labelText: 'Card Brand',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
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
