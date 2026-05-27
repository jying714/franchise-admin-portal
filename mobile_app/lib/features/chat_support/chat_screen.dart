import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/src/core/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        Provider.of<FranchiseProvider>(context, listen: false);
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
        Provider.of<FranchiseProvider>(context, listen: false);
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
            backgroundColor: UiConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: true);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final localize = AppLocalizations.of(context)!;

    if (_userId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: UiConfig.backgroundColorDark,
        body: Center(
          child: Text(
            localize.mustSignInForChat,
            style: TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: UiConfig.textColorDark,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: UiConfig.fontWeightMedium,
            ),
          ),
        ),
      );
    }

    if (_isLoading || _chatId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: UiConfig.backgroundColorDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(localize),
      backgroundColor: UiConfig.backgroundColorDark,
      body: Column(
        children: [
          Padding(
            padding: UiConfig.defaultPadding,
            child: Text(
              _isSupportOnline
                  ? localize.supportIsOnline('Doughboys Pizzeria')
                  : localize.supportWillReplySoon('Doughboys Pizzeria'),
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: _isSupportOnline
                    ? UiConfig.successColor
                    : UiConfig.disabledTextColor,
                fontWeight: UiConfig.fontWeightMedium,
                fontFamily: DesignTokens.fontFamily,
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
                        fontSize: DesignTokens.bodyFontSize,
                        color: UiConfig.disabledTextColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: UiConfig.defaultPadding,
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
            padding: UiConfig.defaultPadding,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localize.typeYourMessage,
                      hintStyle: TextStyle(color: UiConfig.hintTextColor),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                      counterText: '',
                    ),
                    style: TextStyle(
                      color: UiConfig.textColorDark,
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: UiConfig.facebookColor,
                    size: DesignTokens.iconSize,
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

  AppBar _buildAppBar(AppLocalizations localize) => AppBar(
        title: Text(
          localize.chatSupportTitle,
          style: TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: UiConfig.foregroundColorDark,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.facebookColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
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
        padding: UiConfig.defaultPadding,
        decoration: BoxDecoration(
          color: isUser
              ? UiConfig.accentColor.withAlpha(51)
              : UiConfig.surfaceColorDark,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: UiConfig.textColorDark,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: DesignTokens.captionFontSize,
                color: UiConfig.hintTextColor,
                fontFamily: DesignTokens.fontFamily,
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
