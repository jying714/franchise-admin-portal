import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/core/models/promo.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/services/audit_log_service.dart';
import 'package:doughboys_pizzeria_final/widgets/loading_shimmer_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/empty_state_widget.dart';
import 'package:doughboys_pizzeria_final/admin/promo_management/promo_form_dialog.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';

class PromoManagementScreen extends StatelessWidget {
  const PromoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context);

    // Only owner, admin, manager can manage promos. Staff can view.
    if (user == null ||
        !(user.isOwner || user.isAdmin || user.isManager || user.isStaff)) {
      return _unauthorizedScaffold(context);
    }

    final canEdit = user.isOwner || user.isAdmin || user.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Promo Management"),
        backgroundColor: DesignTokens.adminPrimaryColor,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => PromoFormDialog(
                    onSave: (promo) async {
                      await firestoreService.addPromo(promo);
                      await AuditLogService().addLog(
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
      body: StreamBuilder<List<Promo>>(
        stream: firestoreService.getPromotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              title: "No Promotions",
              message: "No promotions yet.",
              // imageAsset: 'assets/images/admin_empty.png',
            );
          }
          final promos = snapshot.data!;
          return ListView.separated(
            itemCount: promos.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final promo = promos[i];
              return ListTile(
                title:
                    Text(promo.name.isNotEmpty ? promo.name : 'Untitled Promo'),
                subtitle: Text(promo.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PromoFormDialog(
                              promo: promo,
                              onSave: (updated) async {
                                await firestoreService.updatePromo(updated);
                                await AuditLogService().addLog(
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                            context, firestoreService, promo.id, user),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService service,
      String promoId, User user) {
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
              await service.deletePromotion(promoId);
              await AuditLogService().addLog(
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
      appBar: AppBar(
        title: const Text("Promo Management"),
      ),
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
