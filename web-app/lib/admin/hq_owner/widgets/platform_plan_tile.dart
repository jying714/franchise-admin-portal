import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../packages/shared_core/lib/src/core/models/platform_plan_model.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/tight_section_card.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/role_guard.dart';
import 'package:provider/provider.dart';
import '../../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';
import 'mock_payment_form.dart';
import 'mock_payment_data.dart';
import '../../../../../packages/shared_core/lib/src/core/models/franchise_subscription_model.dart';
import '../../../../../packages/shared_core/lib/src/core/services/franchise_subscription_service.dart';

class PlatformPlanTile extends StatefulWidget {
  final PlatformPlan plan;
  final bool isExpanded;
  final VoidCallback onExpand;
  final Function() onPlanUpdated;

  const PlatformPlanTile({
    Key? key,
    required this.plan,
    required this.isExpanded,
    required this.onExpand,
    required this.onPlanUpdated,
  }) : super(key: key);

  @override
  State<PlatformPlanTile> createState() => _PlatformPlanTileState();
}

class _PlatformPlanTileState extends State<PlatformPlanTile> {
  String? _selectedInterval;
  MockPaymentData? _paymentInfo;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'platform_owner', 'developer'],
      child: TightSectionCard(
        title: widget.plan.name,
        icon: Icons.credit_card,
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(loc, colorScheme, textTheme),
            const SizedBox(height: 8),
            _buildFeatureChips(colorScheme, textTheme),
            if (widget.isExpanded) ...[
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.plan.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(widget.plan.description,
                            style: textTheme.bodyMedium),
                      ),
                    DropdownButtonFormField<String>(
                      value: _selectedInterval,
                      decoration: InputDecoration(
                        labelText: loc.billingInterval,
                        border: const OutlineInputBorder(),
                      ),
                      items: ['monthly', 'yearly'].map((interval) {
                        return DropdownMenuItem(
                          value: interval,
                          child: Text(
                              interval == 'monthly' ? loc.monthly : loc.yearly),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedInterval = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? loc.fieldRequired : null,
                    ),
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) {
                        final showPaymentForm = widget.plan.requiresPayment &&
                            _selectedInterval != null;
                        debugPrint(
                            'requiresPayment: ${widget.plan.requiresPayment}, interval: $_selectedInterval');

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: showPaymentForm
                              ? Column(
                                  key: const ValueKey('payment-form'),
                                  children: [
                                    MockPaymentForm(
                                      onValidated: (paymentData) {
                                        setState(() {
                                          _paymentInfo = paymentData;
                                        });
                                      },
                                    ),
                                    if (_paymentInfo != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${AppLocalizations.of(context)!.paymentValidated}: ${_paymentInfo!.maskedCardString}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: () {
                          if (_selectedInterval == null) {
                            return loc.selectBillingIntervalFirst;
                          }
                          if (widget.plan.requiresPayment &&
                              _paymentInfo == null) {
                            return loc.completePaymentToContinue;
                          }
                          return '';
                        }(),
                        child: ElevatedButton(
                          onPressed: _isSubmitting || !_canSubmit()
                              ? null
                              : _submitSelectedPlan,
                          child: _isSubmitting
                              ? const CircularProgressIndicator.adaptive()
                              : Text(loc.selectPlan),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${widget.plan.price.toStringAsFixed(2)} / ${widget.plan.billingInterval}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (widget.plan.isCustom)
          Chip(
            label: Text(loc.customPlan),
            backgroundColor: colorScheme.secondaryContainer,
          ),
        IconButton(
          onPressed: widget.onExpand,
          icon: Icon(
            widget.isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChips(ColorScheme colorScheme, TextTheme textTheme) {
    return Wrap(
      spacing: 6,
      runSpacing: -4,
      children: widget.plan.features
          .map((feature) => Chip(
                visualDensity: VisualDensity.compact,
                label: Text(feature, style: textTheme.labelSmall),
                backgroundColor: colorScheme.surfaceVariant,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ))
          .toList(),
    );
  }

  bool _canSubmit() {
    if (_selectedInterval == null) return false;
    if (widget.plan.requiresPayment && _paymentInfo == null) return false;
    return true;
  }

  Future<void> _submitSelectedPlan() async {
    final loc = AppLocalizations.of(context)!;
    final franchiseId =
        context.read<AdminUserProvider>().user?.defaultFranchise;

    if (!_formKey.currentState!.validate() || !_canSubmit()) return;

    if (franchiseId == null || franchiseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.genericErrorOccurred),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final nextBilling = now.add(const Duration(days: 30));
      final billingCycleInDays = _selectedInterval == 'yearly' ? 365 : 30;

      final subscription = FranchiseSubscription(
        id: franchiseId,
        franchiseId: franchiseId,
        platformPlanId: widget.plan.id,
        status: 'active',
        startDate: now,
        nextBillingDate: nextBilling,
        billingCycleInDays: billingCycleInDays,
        isTrial: false,
        discountPercent: 0,
        priceAtSubscription: widget.plan.price,
        billingInterval: _selectedInterval!,
        planSnapshot: {
          'name': widget.plan.name,
          'price': widget.plan.price,
          'billingInterval': widget.plan.billingInterval,
          'features': widget.plan.features,
          'isCustom': widget.plan.isCustom,
          'maskedCardString': _paymentInfo?.maskedCardString ?? '',
        },
        cancelAtPeriodEnd: false,
        createdAt: now,
        updatedAt: now,
        subscribedAt: now,
        lastInvoiceId: null,
        trialEndsAt: null,
        customQuoteDetails: null,
        lastActivity: now,
        autoRenew: true,
        hasOverdueInvoice: false,
      );

      await FranchiseSubscriptionService().subscribeFranchiseToPlan(
        franchiseId: franchiseId,
        plan: widget.plan,
      );

      widget.onPlanUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.subscriptionUpdated)),
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Plan subscription failed',
        stack: stack.toString(),
        source: 'PlatformPlanTile',
        screen: 'available_platform_plans_screen',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.genericErrorOccurred),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
