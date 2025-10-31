import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Displayed when a menu item preview cannot be rendered.
/// Can be used in onboarding editors or debug contexts.
class PreviewMenuItemCardError extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const PreviewMenuItemCardError({
    Key? key,
    this.title = 'Preview Failed',
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: _buildErrorContent(context, loc),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: loc.retry,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red.shade800,
              ),
        ),
        if (onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(loc.retry),
              onPressed: onRetry,
            ),
          ),
      ],
    );
  }
}


