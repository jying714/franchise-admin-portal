import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/promo/promo_form_dialog.dart';
import 'package:franchise_admin_portal/admin/promo/promo_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/promo/promo_banners_panel.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service_impl.dart';

class PromoManagementScreen extends StatefulWidget {
  const PromoManagementScreen({super.key});

  @override
  State<PromoManagementScreen> createState() => _PromoManagementScreenState();
}

class _PromoManagementScreenState extends State<PromoManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openAddPromo(
    BuildContext context, {
    required shared.FirestoreService firestoreService,
    required String franchiseId,
    required shared.User user,
  }) async {
    final choice = await showDialog<PromoTemplateChoice>(
      context: context,
      builder: (_) => const PromoTemplatePickerDialog(),
    );
    if (choice == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => PromoFormDialog(
        initialType: choice.type,
        preferDaypart: choice.preferDaypart,
        onSave: (promo) async {
          try {
            await firestoreService.addPromo(franchiseId, promo);
            await AuditLogServiceImpl().addLog(
              franchiseId: franchiseId,
              userId: user.id,
              action: 'add_promo',
              targetType: 'promo',
              targetId: promo.id,
              details: {'name': promo.name},
            );
          } catch (e, stack) {
            shared.ErrorLogger.log(
              message: e.toString(),
              source: 'promo_management_screen',
              stack: stack.toString(),
              contextData: {
                'franchiseId': franchiseId,
                'userId': user.id,
                'promoId': promo.id,
                'operation': 'add',
              },
            );
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _openEditPromo(
    BuildContext context, {
    required shared.Promo promo,
    required shared.FirestoreService firestoreService,
    required String franchiseId,
    required shared.User user,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PromoFormDialog(
        promo: promo,
        onSave: (updated) async {
          try {
            await firestoreService.updatePromo(franchiseId, updated);
            await AuditLogServiceImpl().addLog(
              franchiseId: franchiseId,
              userId: user.id,
              action: 'update_promo',
              targetType: 'promo',
              targetId: updated.id,
              details: {'name': updated.name},
            );
          } catch (e, stack) {
            shared.ErrorLogger.log(
              message: e.toString(),
              source: 'PromoManagementScreen',
              stack: stack.toString(),
              contextData: {
                'franchiseId': franchiseId,
                'userId': user.id,
                'promoId': updated.id,
                'operation': 'update',
              },
            );
            rethrow;
          }
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    shared.FirestoreService service,
    String promoId,
    shared.User user,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Promotion',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete this promotion?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final franchiseId =
                  Provider.of<shared.FranchiseProvider>(context, listen: false)
                      .franchiseId;
              try {
                await service.deletePromo(franchiseId, promoId);
                await AuditLogServiceImpl().addLog(
                  franchiseId: franchiseId,
                  userId: user.id,
                  action: 'delete_promo',
                  targetType: 'promo',
                  targetId: promoId,
                  details: {},
                );
              } catch (e, stack) {
                shared.ErrorLogger.log(
                  message: e.toString(),
                  source: 'promo_management_screen',
                  stack: stack.toString(),
                  contextData: {
                    'franchiseId': franchiseId,
                    'userId': user.id,
                    'promoId': promoId,
                    'operation': 'delete',
                  },
                );
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _promoSubtitle(shared.Promo promo) {
    final parts = <String>[];
    if (promo.code.isNotEmpty) {
      parts.add(promo.code);
    }
    if (promo.discount > 0) {
      if (promo.type == shared.PromoType.percent ||
          promo.type.toLowerCase() == 'percent') {
        parts.add('${promo.discount.toStringAsFixed(0)}% off');
      } else {
        parts.add('\$${promo.discount.toStringAsFixed(2)} off');
      }
    }
    if (promo.description.trim().isNotEmpty) {
      parts.add(promo.description.trim());
    }
    parts.add(promo.active ? 'Active' : 'Inactive');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final franchiseId = context.watch<shared.FranchiseProvider>().franchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final userProvider = context.watch<shared.AdminUserProvider>();
    final user = userProvider.user;
    final loading = userProvider.loading;

    if (user == null) {
      if (loading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return const Scaffold(
        body: Center(child: Text('Unauthorized — No admin user')),
      );
    }

    const canEdit = true;

    return RoleGuard(
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin',
      ],
      featureName: 'promo_management_screen',
      screen: 'PromoManagementScreen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GracePeriodBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Promotions',
                          style: TextStyle(
                            color: colorScheme.onBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Text(
                        'Discount codes and marketing banners for this franchise.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TabBar(
                        controller: _tabs,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor:
                            colorScheme.onSurface.withValues(alpha: 0.65),
                        indicatorColor: colorScheme.primary,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.local_offer_outlined, size: 18),
                            text: 'Codes',
                          ),
                          Tab(
                            icon: Icon(Icons.view_carousel_outlined, size: 18),
                            text: 'Banners',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            // —— Codes ——
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Promo codes',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (canEdit)
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: colorScheme.onSurface,
                                        ),
                                        tooltip: 'Add promo code',
                                        onPressed: () => _openAddPromo(
                                          context,
                                          firestoreService: firestoreService,
                                          franchiseId: franchiseId,
                                          user: user,
                                        ),
                                      ),
                                  ],
                                ),
                                Expanded(
                                  child: StreamBuilder<List<shared.Promo>>(
                                    stream:
                                        firestoreService.getPromos(franchiseId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const LoadingShimmerWidget();
                                      }
                                      if (snapshot.hasError) {
                                        return const EmptyStateWidget(
                                          title: 'Error loading promos',
                                          message: 'Please try again later.',
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const EmptyStateWidget(
                                          title: 'No Promotions',
                                          message: 'No promotions yet.',
                                        );
                                      }
                                      final promos = List<shared.Promo>.from(
                                          snapshot.data!)
                                        ..sort((a, b) {
                                          final bySort = a.sortOrder
                                              .compareTo(b.sortOrder);
                                          if (bySort != 0) return bySort;
                                          return a.name
                                              .toLowerCase()
                                              .compareTo(b.name.toLowerCase());
                                        });
                                      return ListView.separated(
                                        itemCount: promos.length,
                                        separatorBuilder: (_, __) => Divider(
                                          color: colorScheme.outline,
                                        ),
                                        itemBuilder: (context, i) {
                                          final promo = promos[i];
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: promo.active
                                                  ? DesignTokens.primaryColor
                                                      .withValues(alpha: 0.15)
                                                  : colorScheme
                                                      .surfaceContainerHighest,
                                              child: Icon(
                                                Icons.local_offer_outlined,
                                                color: promo.active
                                                    ? DesignTokens.primaryColor
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              promo.name.isNotEmpty
                                                  ? promo.name
                                                  : 'Untitled Promo',
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _promoSubtitle(promo),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (canEdit)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'Edit',
                                                    onPressed: () =>
                                                        _openEditPromo(
                                                      context,
                                                      promo: promo,
                                                      firestoreService:
                                                          firestoreService,
                                                      franchiseId: franchiseId,
                                                      user: user,
                                                    ),
                                                  ),
                                                if (canEdit)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Delete',
                                                    onPressed: () =>
                                                        _confirmDelete(
                                                      context,
                                                      firestoreService,
                                                      promo.id,
                                                      user,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // —— Banners ——
                            PromoBannersPanel(
                              franchiseId: franchiseId,
                              canEdit: canEdit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(flex: 9, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
