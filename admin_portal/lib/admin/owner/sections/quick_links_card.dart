// 📁 lib/admin/owner/sections/quick_links_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:provider/provider.dart';

class QuickLinksCard extends StatelessWidget {
  const QuickLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AdminUserProvider>().user;
    if (!(user?.isPlatformOwner ?? false) && !(user?.isDeveloper ?? false)) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    void _navigateSafely(String route) {
      try {
        Navigator.pushNamed(context, route);
      } catch (e, stack) {
        ErrorLogger.log(
          message: 'quick_links_navigation_failed',
          source: 'QuickLinksCard',
          screen: 'platform_owner_dashboard',
          severity: 'error',
          contextData: {
            'exception': e.toString(),
            'stackTrace': stack.toString(),
            'route': route,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.genericErrorOccurred)),
        );
      }
    }

    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  loc.quickLinksLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _QuickLinkTile(
                  icon: Icons.payment,
                  label: loc.platformPlansTitle,
                  onTap: () => _navigateSafely('/platform/plans'),
                ),
                _QuickLinkTile(
                  icon: Icons.subscriptions,
                  label: loc.franchiseSubscriptionsTitle,
                  onTap: () => _navigateSafely('/platform/subscriptions'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.featureComingSoon('Add/remove dashboards, billing console'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        backgroundColor: colorScheme.secondaryContainer,
        avatar: Icon(icon, color: colorScheme.onSecondaryContainer, size: 20),
        label: Text(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
