import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/admin/promo/promo_form_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/utils/user_permissions.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_unauthorized_widget.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';

class PromoManagementScreen extends StatelessWidget {
  const PromoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final user = userNotifier.user;
    final loading = userNotifier.loading;

    print('[PROMO SCREEN] Build called');
    print(
        'Current user: $user, roles: ${user?.roles}, isDeveloper: ${user?.isDeveloper}, loading: $loading');
    print('[PROMO SCREEN] franchiseId: $franchiseId');

    if (loading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canEdit = true;

    return RoleGuard(
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin'
      ],
      featureName: 'promo_management_screen',
      screen: 'PromoManagementScreen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: DesignTokens.backgroundColor,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GracePeriodBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Promo Management",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const Spacer(),
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.black87),
                                tooltip: "Add Promotion",
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => PromoFormDialog(
                                      onSave: (promo) async {
                                        try {
                                          await firestoreService.addPromo(
                                              franchiseId, promo);
                                          await AuditLogService().addLog(
                                            franchiseId: franchiseId,
                                            userId: user.id,
                                            action: 'add_promo',
                                            targetType: 'promo',
                                            targetId: promo.id,
                                            details: {'name': promo.name},
                                          );
                                        } catch (e, stack) {
                                          await ErrorLogger.log(
                                            message: e.toString(),
                                            source: 'promo_management_screen',
                                            screen: 'PromoManagementScreen',
                                            stack: stack.toString(),
                                            contextData: {
                                              'franchiseId': franchiseId,
                                              'userId': user.id,
                                              'promoId': promo.id,
                                              'operation': 'add',
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Promo>>(
                          stream: firestoreService.getPromos(franchiseId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingShimmerWidget();
                            }
                            if (snapshot.hasError) {
                              return const EmptyStateWidget(
                                title: "Error loading promos",
                                message: "Please try again later.",
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const EmptyStateWidget(
                                title: "No Promotions",
                                message: "No promotions yet.",
                              );
                            }
                            final promos = snapshot.data!;
                            return ListView.separated(
                              itemCount: promos.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, i) {
                                final promo = promos[i];
                                return ListTile(
                                  title: Text(promo.name.isNotEmpty
                                      ? promo.name
                                      : 'Untitled Promo'),
                                  subtitle: Text(promo.description),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (canEdit)
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => PromoFormDialog(
                                                promo: promo,
                                                onSave: (updated) async {
                                                  try {
                                                    await firestoreService
                                                        .updatePromo(
                                                            franchiseId,
                                                            updated);
                                                    await AuditLogService()
                                                        .addLog(
                                                      franchiseId: franchiseId,
                                                      userId: user.id,
                                                      action: 'update_promo',
                                                      targetType: 'promo',
                                                      targetId: updated.id,
                                                      details: {
                                                        'name': updated.name
                                                      },
                                                    );
                                                  } catch (e, stack) {
                                                    await ErrorLogger.log(
                                                      message: e.toString(),
                                                      source:
                                                          'promo_management_screen',
                                                      screen:
                                                          'PromoManagementScreen',
                                                      stack: stack.toString(),
                                                      contextData: {
                                                        'franchiseId':
                                                            franchiseId,
                                                        'userId': user.id,
                                                        'promoId': updated.id,
                                                        'operation': 'update',
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      if (canEdit)
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _confirmDelete(
                                              context,
                                              firestoreService,
                                              promo.id,
                                              user),
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
                ),
              ),
              Expanded(
                flex: 9,
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService service,
      String promoId, admin_user.User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Promotion"),
        content: const Text("Are you sure you want to delete this promotion?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final franchiseId =
                  Provider.of<FranchiseProvider>(context, listen: false)
                      .franchiseId;
              try {
                await service.deletePromo(franchiseId, promoId);
                await AuditLogService().addLog(
                  franchiseId: franchiseId,
                  userId: user.id,
                  action: 'delete_promo',
                  targetType: 'promo',
                  targetId: promoId,
                  details: {},
                );
              } catch (e, stack) {
                await ErrorLogger.log(
                  message: e.toString(),
                  source: 'promo_management_screen',
                  screen: 'PromoManagementScreen',
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
