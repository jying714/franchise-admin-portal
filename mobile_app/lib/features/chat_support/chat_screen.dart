// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/models/message.dart';
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
  bool isSupportOnline = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initializeChat();
    _listenSupportOnline();
  }

  void _initializeChat() async {
    if (_userId == null) return;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final chatId = await firestoreService.createOrGetUserChat();
    setState(() {
      _chatId = chatId;
    });
  }

  void _listenSupportOnline() {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    firestoreService.streamSupportOnline().listen((status) {
      setState(() {
        isSupportOnline = status;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage(FirestoreService firestoreService) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _userId == null || _chatId == null) return;
    _controller.clear();

    await firestoreService.sendMessage(
      chatId: _chatId!,
      senderId: _userId!,
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final localize = AppLocalizations.of(context)!;

    if (_userId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: DesignTokens.backgroundColorDark,
        body: Center(
          child: Text(
            localize.mustSignInForChat,
            style: TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: DesignTokens.textColorDark,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_chatId == null) {
      return Scaffold(
        appBar: _buildAppBar(localize),
        backgroundColor: DesignTokens.backgroundColorDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(localize),
      backgroundColor: DesignTokens.backgroundColorDark,
      body: Column(
        children: [
          Padding(
            padding: DesignTokens.gridPadding,
            child: Text(
              isSupportOnline
                  ? localize.supportIsOnline(BrandingConfig.franchiseName)
                  : localize.supportWillReplySoon(BrandingConfig.franchiseName),
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: isSupportOnline
                    ? DesignTokens.successTextColor
                    : DesignTokens.disabledTextColor,
                fontWeight: FontWeight.w600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: firestoreService.streamChatMessages(_chatId!),
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
                        color: DesignTokens.disabledTextColor,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.senderId == _userId;
                    return _MessageBubble(
                      message: message,
                      isUser: isUser,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: DesignTokens.gridPadding,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localize.typeYourMessage,
                      hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                      counterText: '',
                    ),
                    style: TextStyle(
                      color: DesignTokens.textColorDark,
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: DesignTokens.facebookColor,
                    size: DesignTokens.iconSize,
                  ),
                  onPressed: () => _sendMessage(firestoreService),
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
            color: DesignTokens.foregroundColorDark,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.facebookColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColorDark),
      );
}

/// --- Custom message bubble widget for UI clarity
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // Optionally, display an avatar if you later add image URLs to Message model.
    // final String? avatarUrl = message.senderImageUrl; // Uncomment if available

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: DesignTokens.cardPadding,
        decoration: BoxDecoration(
          color: isUser
              ? DesignTokens.secondaryTextColor.withAlpha(51) // ~20% opacity
              : DesignTokens.surfaceColorDark,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If you ever add avatars to Message, uncomment and wire up below:
            // if (!isUser && avatarUrl != null && avatarUrl.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 8),
            //     child: NetworkImageWidget(
            //       imageUrl: avatarUrl,
            //       fallbackAsset: BrandingConfig.defaultAvatarIcon,
            //       width: 32,
            //       height: 32,
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //   ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.textColorDark,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: DesignTokens.captionFontSize,
                      color: DesignTokens.hintTextColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  if (isUser && message.status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        message.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: message.status == 'read'
                              ? DesignTokens.successColor
                              : DesignTokens.hintTextColor,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                ],
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
