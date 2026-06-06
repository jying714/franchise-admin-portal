import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/chat/admin_chat_detail_dialog.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class ChatManagementScreen extends StatelessWidget {
  const ChatManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requireAnyRole: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin'
      ],
      featureName: 'chat_management_screen',
      child: SubscriptionAccessGuard(
        child: const ChatManagementScreenContent(),
      ),
    );
  }
}

class ChatManagementScreenContent extends StatefulWidget {
  const ChatManagementScreenContent({super.key});

  @override
  State<ChatManagementScreenContent> createState() =>
      _ChatManagementScreenContentState();
}

class _ChatManagementScreenContentState
    extends State<ChatManagementScreenContent> {
  @override
  Widget build(BuildContext context) {
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final adminUserProvider =
        Provider.of<shared.AdminUserProvider>(context, listen: false);
    final user = adminUserProvider.user;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                        Text(
                          loc.chatManagementTitle,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<shared.Chat>>(
                      stream: firestoreService.getSupportChats(franchiseId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingShimmerWidget();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return EmptyStateWidget(
                            title: loc.noChatsTitle,
                            message: loc.noChatsMessage,
                            iconData: Icons.forum_outlined,
                            isAdmin: true,
                          );
                        }
                        final chats = snapshot.data!;
                        return ListView.separated(
                          itemCount: chats.length,
                          separatorBuilder: (_, __) => Divider(
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          itemBuilder: (context, i) {
                            final chat = chats[i];
                            return ListTile(
                              title: Text(
                                chat.userName ?? loc.unknownUser,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                chat.lastMessage,
                                style: TextStyle(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.75),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete,
                                    color: colorScheme.error),
                                tooltip: loc.deleteChatTooltip,
                                onPressed: () => _confirmDelete(
                                  context,
                                  firestoreService,
                                  chat.id,
                                  user,
                                  loc,
                                  colorScheme,
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AdminChatDetailDialog(
                                    franchiseId: franchiseId,
                                    chatId: chat.id,
                                    userName: chat.userName ?? loc.unknownUser,
                                  ),
                                );
                              },
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
          const Expanded(flex: 9, child: SizedBox()),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    shared.FirestoreService service,
    String chatId,
    shared.User? user,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          loc.deleteChatTitle,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          loc.deleteChatConfirmMessage,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              await service.deleteSupportChat(franchiseId, chatId);
              if (user != null) {
                final auditService =
                    Provider.of<shared.AuditLogService>(context, listen: false);
                await auditService.addLog(
                  franchiseId: franchiseId,
                  userId: user.id,
                  action: 'delete_support_chat',
                  targetType: 'support_chat',
                  targetId: chatId,
                  details: {'message': 'Support chat thread deleted by admin.'},
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
  }
}
