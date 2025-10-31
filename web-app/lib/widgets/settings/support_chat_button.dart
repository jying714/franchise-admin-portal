import 'package:flutter/material.dart';

class SupportChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support chat coming soon!')));
      },
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text("Support Chat"),
    );
  }
}


