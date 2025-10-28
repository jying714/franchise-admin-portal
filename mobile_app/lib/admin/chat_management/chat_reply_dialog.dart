import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';

class ChatReplyDialog extends StatefulWidget {
  final String chatId;
  final VoidCallback? onReplied;
  const ChatReplyDialog({super.key, required this.chatId, this.onReplied});

  @override
  State<ChatReplyDialog> createState() => _ChatReplyDialogState();
}

class _ChatReplyDialogState extends State<ChatReplyDialog> {
  final _controller = TextEditingController();
  bool isSending = false;

  Future<void> _sendReply() async {
    final reply = _controller.text.trim();
    if (reply.isEmpty) return;
    setState(() => isSending = true);
    await FirestoreService().sendMessage(
      chatId: widget.chatId,
      senderId: 'admin', // You may want to use the actual admin/staff ID
      content: reply,
    );
    if (!mounted) return;
    setState(() => isSending = false);
    if (widget.onReplied != null) widget.onReplied!();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reply to Chat'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'Enter your reply'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: isSending ? null : _sendReply,
          child: isSending
              ? const CircularProgressIndicator()
              : const Text('Send'),
        ),
      ],
    );
  }
}
