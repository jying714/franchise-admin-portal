import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/developer/platform/franchise_subscription_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/categories/bulk_action_bar.dart';

final shared.DashboardSection franchiseSubscriptionsSection =
    shared.DashboardSection(
  key: 'franchiseSubscriptions',
  title: 'Franchise Subscriptions',
  icon: Icons.subscriptions,
  builder: (_) => const FranchiseSubscriptionsSection(),
  sidebarOrder: 100,
);

class FranchiseSubscriptionsSection extends StatefulWidget {
  const FranchiseSubscriptionsSection({super.key});

  @override
  State<FranchiseSubscriptionsSection> createState() =>
      _FranchiseSubscriptionsSectionState();
}

class _FranchiseSubscriptionsSectionState
    extends State<FranchiseSubscriptionsSection> {
  late Future<List<shared.FranchiseSubscription>> _subsFuture;
  final Set<String> _selectedIds = {};
  bool _isBulkMode = false;
  List<shared.FranchiseSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _subsFuture = _loadSubscriptions();
  }

  Future<List<shared.FranchiseSubscription>> _loadSubscriptions() async {
    try {
      final service = Provider.of<shared.FranchiseSubscriptionService>(
        context,
        listen: false,
      );
      final result = await service.getAllFranchiseSubscriptions();
      _subs = result;
      return result;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'load_franchise_subscriptions_failed',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionsSection',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );
      return [];
    }
  }

  void _confirmDelete(String subId, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDeleteTitle),
        content: Text(loc.confirmDeleteDescription),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = Provider.of<shared.FranchiseSubscriptionService>(
          context,
          listen: false,
        );
        await service.deleteFranchiseSubscription(subId);
        if (mounted) {
          setState(() => _subsFuture = _loadSubscriptions());
        }
      } catch (e, st) {
        shared.ErrorLogger.log(
          message: 'Failed to delete subscription: $e',
          stack: st.toString(),
          source: 'FranchiseSubscriptionsSection',
          severity: 'error',
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(loc.deleteFailed)));
        }
      }
    }
  }

  void _handleBulkDelete() async {
    final loc = AppLocalizations.of(context)!;
    final idsToDelete = _selectedIds.toList();
    final subsToRestore = [..._subs.where((s) => idsToDelete.contains(s.id))];

    try {
      final service = Provider.of<shared.FranchiseSubscriptionService>(
        context,
        listen: false,
      );
      await service.deleteManyFranchiseSubscriptions(idsToDelete);

      if (mounted) {
        setState(() {
          _subsFuture = _loadSubscriptions();
          _selectedIds.clear();
          _isBulkMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.bulkDeleteSuccess(idsToDelete.length.toString())),
          action: SnackBarAction(
            label: loc.undo,
            onPressed: () async {
              for (final sub in subsToRestore) {
                await service.saveFranchiseSubscription(sub);
              }
              if (mounted) setState(() => _subsFuture = _loadSubscriptions());
            },
          ),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.deleteFailed)));
      }
    }
  }

  void _openEditorDialog(shared.FranchiseSubscription sub) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FranchiseSubscriptionEditorDialog(
        franchiseId: sub.franchiseId,
        subscription: sub,
      ),
    );
    if (result == true && mounted) {
      setState(() => _subsFuture = _loadSubscriptions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = context.watch<shared.AdminUserProvider>().user;

    if (!(user?.isDeveloper == true || user?.isPlatformOwner == true)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<shared.FranchiseSubscription>>(
      future: _subsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final subs = snapshot.data ?? [];
        _subs = subs;

        if (subs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(loc.noSubscriptionsFound),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isBulkMode
                ? BulkActionBar(
                    selectedCount: _selectedIds.length,
                    onBulkDelete: _handleBulkDelete,
                    onClearSelection: () {
                      setState(() {
                        _selectedIds.clear();
                        _isBulkMode = false;
                      });
                    },
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: Text(loc.enableBulkSelect),
                      onPressed: () => setState(() => _isBulkMode = true),
                    ),
                  ),
            const SizedBox(height: 12),
            ...subs.map((sub) => _buildSubscriptionCard(sub, loc, theme)),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(
    shared.FranchiseSubscription sub,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final selected = _selectedIds.contains(sub.id);

    return CheckboxListTile(
      value: selected,
      onChanged: _isBulkMode
          ? (checked) {
              setState(() {
                if (checked == true) {
                  _selectedIds.add(sub.id);
                } else {
                  _selectedIds.remove(sub.id);
                }
              });
            }
          : null,
      title: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${loc.franchiseIdLabel}: ${sub.franchiseId}',
                      style: theme.textTheme.titleSmall),
                  const Spacer(),
                  if (!_isBulkMode) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: loc.editSubscription,
                      onPressed: () => _openEditorDialog(sub),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: loc.deleteSubscription,
                      onPressed: () => _confirmDelete(sub.id, loc),
                    ),
                  ],
                  Chip(
                    label: Text(loc.translateStatus(sub.status)),
                    backgroundColor: shared.UiConfig.statusColor(sub.status,
                        theme), // ensure this exists in shared.shared.AppConfig
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${loc.planIdLabel}: ${sub.platformPlanId}'),
              const SizedBox(height: 4),
              if (sub.isTrial)
                Text(
                    '${loc.trialEndsLabel}: ${shared.AppConfig.formatDate(sub.trialEndsAt)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    )),
              const SizedBox(height: 8),
              Text(
                  '${loc.nextBillingLabel}: ${shared.AppConfig.formatDate(sub.nextBillingDate)}'),
              const SizedBox(height: 4),
              if (sub.discountPercent > 0)
                Text('${loc.discountLabel}: ${sub.discountPercent}%',
                    style: theme.textTheme.labelSmall),
              const SizedBox(height: 12),
              Text(
                loc.featureComingSoon('Subscription settings'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
