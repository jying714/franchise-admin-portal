import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/app_config.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/models/enriched/enriched_franchise_subscription.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/admin/owner/widgets/franchise_subscription_summary.dart';
import 'package:admin_portal/admin/owner/widgets/franchise_subscription_expanded_detail.dart';
import 'package:admin_portal/admin/developer/platform/franchise_subscription_editor_dialog.dart';
import 'package:provider/provider.dart';

class FranchiseSubscriptionListTile extends StatefulWidget {
  final EnrichedFranchiseSubscription enriched;
  final VoidCallback? onRefreshRequested;

  const FranchiseSubscriptionListTile({
    super.key,
    required this.enriched,
    this.onRefreshRequested,
  });

  @override
  State<FranchiseSubscriptionListTile> createState() =>
      _FranchiseSubscriptionListTileState();
}

class _FranchiseSubscriptionListTileState
    extends State<FranchiseSubscriptionListTile> {
  bool _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  Future<void> _editSubscription(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => FranchiseSubscriptionEditorDialog(
          franchiseId: widget.enriched.franchiseId,
          subscription: widget.enriched.subscription,
        ),
      );
      if (result == true && widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'edit_subscription_failed',
        source: 'FranchiseSubscriptionListTile',
        screen: 'franchise_subscription_list_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': widget.enriched.franchiseId,
          'subscriptionId': widget.enriched.subscription.id,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.editSubscriptionFailed),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthorized =
        user?.isDeveloper == true || user?.isPlatformOwner == true;
    if (!isAuthorized) return const SizedBox.shrink();

    final enriched = widget.enriched;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: enriched.isInvoiceOverdue
                ? colorScheme.error
                : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: DesignTokens.adminCardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary + optional inline warning text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FranchiseSubscriptionSummary(
                          subscription: enriched.subscription,
                        ),
                        if (enriched.isInvoiceOverdue)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              loc.paymentOverdueWarning,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Actions + badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (enriched.isInvoiceOverdue)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: colorScheme.error),
                              const SizedBox(width: 4),
                              Text(
                                loc.overdueBadge, // "Overdue"
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: loc.editSubscription,
                        onPressed: () => _editSubscription(context),
                      ),
                      IconButton(
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: colorScheme.primary,
                        ),
                        tooltip: _expanded
                            ? loc.hideDetailsTooltip
                            : loc.showDetailsTooltip,
                        onPressed: _toggleExpanded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FranchiseSubscriptionExpandedDetail(
                  enriched: enriched,
                ),
              ),
            if (!_expanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  loc.featureComingSoon(loc.subscriptionInsights),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
