import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _userId;
  String? _chatId;
  bool _isSupportOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initializeChat();
    _listenSupportOnline();
  }

  Future<void> _initializeChat() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    try {
      final chatId = await firestoreService.createOrGetUserChat(
        _userId!,
        franchiseId: franchiseId,
      );
      if (mounted) {
        setState(() {
          _chatId = chatId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenSupportOnline() {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    firestoreService.streamSupportOnline().listen((status) {
      if (mounted) {
        setState(() => _isSupportOnline = status);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _userId == null || _chatId == null) return;

    _controller.clear();

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    try {
      await firestoreService.sendMessage(
        franchiseId, // Positional first as per abstract/impl
        chatId: _chatId!,
        senderId: _userId!,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final localize = AppLocalizations.of(context)!;

    if (_userId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Text(
            localize.mustSignInForChat,
            style: TextStyle(
              fontSize: shared.DesignTokens.bodyFontSize,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
        ),
      );
    }

    if (_isLoading || _chatId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(localize),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Padding(
            padding: shared.UiConfig.defaultPadding,
            child: Text(
              _isSupportOnline
                  ? localize.supportIsOnline('Doughboys Pizzeria')
                  : localize.supportWillReplySoon('Doughboys Pizzeria'),
              style: TextStyle(
                fontSize: shared.DesignTokens.bodyFontSize,
                color: _isSupportOnline
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: shared.UiConfig.fontWeightMedium,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<shared.Message>>(
              stream:
                  firestoreService.streamChatMessages(franchiseId, _chatId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      localize.noMessages,
                      style: TextStyle(
                        fontSize: shared.DesignTokens.bodyFontSize,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: shared.UiConfig.defaultPadding,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.senderId == _userId;
                    return _MessageBubble(message: message, isUser: isUser);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: shared.UiConfig.defaultPadding,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localize.typeYourMessage,
                      hintStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.formFieldRadius),
                      ),
                      counterText: '',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: shared.DesignTokens.bodyFontSize,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                    size: shared.DesignTokens.iconSize,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localize) =>
      FranchiseAppBar(
        title: localize.chatSupportTitle,
        showLogo: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      );
}

class _MessageBubble extends StatelessWidget {
  final shared.Message message;
  final bool isUser;

  const _MessageBubble(
      {super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: shared.UiConfig.defaultPadding,
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary.withAlpha(51)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: shared.DesignTokens.bodyFontSize,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: shared.DesignTokens.captionFontSize,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
