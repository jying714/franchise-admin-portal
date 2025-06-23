import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/chat/admin_chat_detail_dialog.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/core/models/chat.dart';

class ChatManagementScreen extends StatelessWidget {
  const ChatManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context);

    // --- Role enforcement (owner/admin/manager only) ---
    if (user == null || !(user.isOwner || user.isAdmin || user.isManager)) {
      Future.microtask(() {
        AuditLogService().addLog(
          userId: user?.id ?? 'unknown',
          action: 'unauthorized_chat_management_access',
          targetType: 'support_chat',
          targetId: '',
          details: {
            'message':
                'User tried to access chat management without permission.'
          },
        );
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chat Management"),
          backgroundColor: DesignTokens.adminPrimaryColor,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Management"),
        backgroundColor: DesignTokens.adminPrimaryColor,
      ),
      body: StreamBuilder<List<Chat>>(
        stream: firestoreService.getSupportChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              title: "No Chats",
              message: "No support chats yet.",
              imageAsset: 'assets/images/admin_empty.png',
            );
          }
          final chats = snapshot.data!;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final chat = chats[i];
              return ListTile(
                title: Text(chat.userName ?? 'Unknown User'),
                subtitle: Text(chat.lastMessage),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _confirmDelete(context, firestoreService, chat.id, user),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AdminChatDetailDialog(
                        chatId: chat.id,
                        userName: chat.userName ?? 'Unknown User'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService service,
      String chatId, User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Chat"),
        content:
            const Text("Are you sure you want to delete this chat thread?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await service.deleteSupportChat(chatId);
              await AuditLogService().addLog(
                userId: user.id,
                action: 'delete_support_chat',
                targetType: 'support_chat',
                targetId: chatId,
                details: {'message': 'Support chat thread deleted by admin.'},
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
