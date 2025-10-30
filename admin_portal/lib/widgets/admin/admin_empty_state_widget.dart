import 'package:flutter/material.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/config/design_tokens.dart';

class AdminEmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? imageAsset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const AdminEmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.imageAsset,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null && imageAsset!.isNotEmpty)
              Image.asset(
                imageAsset!,
                width: 140,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: 72, color: colorScheme.secondary),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.adminButtonRadius),
                    ),
                  ),
                  onPressed: onAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
