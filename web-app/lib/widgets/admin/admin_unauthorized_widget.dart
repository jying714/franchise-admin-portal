import 'package:flutter/material.dart';

class AdminUnauthorizedWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onReturnHome;

  const AdminUnauthorizedWidget({
    Key? key,
    this.title,
    this.message,
    this.buttonText,
    this.onReturnHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? "Menu Editor"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 54, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message ??
                  "Unauthorized â€” You do not have permission to access this page.",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: Text(buttonText ?? "Return to Home"),
              onPressed: onReturnHome ??
                  () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
            ),
          ],
        ),
      ),
    );
  }
}


