import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

class FranchiseSubscriptionEditorDialog extends StatefulWidget {
  final shared.FranchiseSubscription? subscription; // null if creating new
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

  List<shared.PlatformPlan> _plans = [];

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
      final service = Provider.of<shared.FranchiseSubscriptionService>(context,
          listen: false); // or Provider if in context
      final plans = await service.getPlatformPlans();

      setState(() {
        _plans = plans;

        // Validate selected plan
        if (_selectedPlanId != null &&
            !_plans.any((p) => p.id == _selectedPlanId)) {
          _selectedPlanId = null;
        }
      });
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to load platform plans: $e',
        stack: st.toString(),
        source: 'FranchiseSubscriptionEditorDialog',
        severity: 'error',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final service = Provider.of<shared.FranchiseSubscriptionService>(context,
          listen: false);
      final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);

      final billingCycleInDays =
          selectedPlan.billingInterval.toLowerCase() == 'yearly' ? 365 : 30;

      final newSub = shared.FranchiseSubscription(
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

      await service.saveFranchiseSubscription(newSub);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to save franchise subscription: $e',
        stack: st.toString(),
        source: 'FranchiseSubscriptionEditorDialog',
        severity: 'error',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
          child: Text('[Invalid] $_status'),
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
              child: SingleChildScrollView(
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
                      onChanged: (value) =>
                          setState(() => _selectedPlanId = value),
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
                    const SizedBox(height: 8),
                    Tooltip(
                      message: (_status == 'paused' || _status == 'canceled')
                          ? loc.toggleLockedDueToStatus
                          : '',
                      child: SwitchListTile(
                        title: Text(loc.cancelAtPeriodEndToggle),
                        subtitle: Text(loc.cancelAtPeriodEndDescription),
                        value: _cancelAtPeriodEnd,
                        onChanged: (_status == 'paused' ||
                                _status == 'canceled')
                            ? null
                            : (val) => setState(() => _cancelAtPeriodEnd = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RoleGuard(
                      allowedRoles: const ['platform_owner', 'developer'],
                      featureName: 'Franchise Subscription Editor',
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _billingEmail,
                            decoration: InputDecoration(
                              labelText: loc.billingEmail,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) => _billingEmail =
                                val.trim().isEmpty ? null : val.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _paymentTokenId,
                            decoration: const InputDecoration(
                              labelText: 'Payment Token (debug)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => _paymentTokenId =
                                val.trim().isEmpty ? null : val.trim(),
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
