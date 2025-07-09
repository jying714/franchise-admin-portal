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

class PromoManagementScreen extends StatelessWidget {
  const PromoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId!;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<admin_user.User?>(context);

    // Only owner, admin, manager can manage promos. Staff can view.
    if (user == null ||
        !(user.isOwner || user.isAdmin || user.isManager || user.isStaff)) {
      return _unauthorizedScaffold(context);
    }

    final canEdit = user.isOwner || user.isAdmin || user.isManager;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content column
          Expanded(
            flex: 11,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
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
                            icon: const Icon(Icons.add, color: Colors.black87),
                            tooltip: "Add Promotion",
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PromoFormDialog(
                                  onSave: (promo) async {
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
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Promo list
                  Expanded(
                    child: StreamBuilder<List<Promo>>(
                      stream: firestoreService.getPromotions(franchiseId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingShimmerWidget();
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
                                              await firestoreService
                                                  .updatePromo(
                                                      franchiseId, updated);
                                              await AuditLogService().addLog(
                                                franchiseId: franchiseId,
                                                userId: user.id,
                                                action: 'update_promo',
                                                targetType: 'promo',
                                                targetId: updated.id,
                                                details: {'name': updated.name},
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _confirmDelete(context,
                                          firestoreService, promo.id, user),
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
          // Right panel placeholder
          Expanded(
            flex: 9,
            child: Container(),
          ),
        ],
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
                      .franchiseId!;
              await service.deletePromotion(franchiseId, promoId);
              await AuditLogService().addLog(
                franchiseId: franchiseId,
                userId: user.id,
                action: 'delete_promo',
                targetType: 'promo',
                targetId: promoId,
                details: {},
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _unauthorizedScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 54, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "Unauthorized — You do not have permission to access this page.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text("Return to Home"),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
