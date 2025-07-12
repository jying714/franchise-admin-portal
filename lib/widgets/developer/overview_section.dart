import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class OverviewSection extends StatefulWidget {
  final String? franchiseId;
  const OverviewSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  bool _loading = true;
  String? _errorMsg;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(covariant OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // Fetch your analytics, revenue, order stats, and system health here.
      // Placeholder: Replace with FirestoreService or your stats service.
      // Example: FirestoreService().getDashboardStats(franchiseId)
      await Future.delayed(
          const Duration(milliseconds: 600)); // Simulate network

      // Placeholder: Example stats structure, replace with real query!
      _stats = {
        'orders': widget.franchiseId == 'all' ? 2417 : 317,
        'revenue': widget.franchiseId == 'all' ? 126876.25 : 13824.50,
        'lastSync': DateTime.now().subtract(const Duration(minutes: 7)),
        'uniqueCustomers': widget.franchiseId == 'all' ? 893 : 123,
        'topSeller': 'Deluxe Pizza',
        'avgOrderValue': 42.37,
        'appVersion': '1.0.7',
        'systemHealth': 'ok', // 'ok', 'warning', 'error'
      };

      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      firestoreService.logError(
        widget.franchiseId,
        message: 'Failed to fetch dashboard stats: $e',
        stackTrace: stack.toString(),
        source: 'OverviewSection',
        severity: 'warning',
        screen: 'DeveloperDashboardScreen',
        contextData: {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;
    final isAllFranchises = widget.franchiseId == 'all';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAllFranchises
                ? '${loc.dashboardOverview} — ${loc.allFranchisesLabel ?? "All Franchises"}'
                : '${loc.dashboardOverview} — ${widget.franchiseId}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            Center(child: CircularProgressIndicator(color: colorScheme.primary))
          else if (_errorMsg != null)
            Card(
              color: colorScheme.errorContainer,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${loc.dashboardErrorLoadingStats}\n$_errorMsg',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.primary),
                      tooltip: loc.reload,
                      onPressed: _fetchStats,
                    )
                  ],
                ),
              ),
            )
          else ...[
            _DashboardStatCards(
                stats: _stats!,
                loc: loc,
                colorScheme: colorScheme,
                theme: theme,
                isAllFranchises: isAllFranchises),

            const SizedBox(height: 28),

            // System Health Card
            _SystemHealthCard(
              health: _stats!['systemHealth'] as String,
              lastSync: _stats!['lastSync'] as DateTime,
              colorScheme: colorScheme,
              loc: loc,
            ),

            const SizedBox(height: 32),

            // Developer-only insights
            if (isDeveloper) ...[
              _DeveloperInsightCards(
                  theme: theme,
                  colorScheme: colorScheme,
                  loc: loc,
                  franchiseId: widget.franchiseId),
              const SizedBox(height: 28),
            ],

            // Future features/expansion areas
            _ComingSoonCard(
              icon: Icons.trending_up,
              title: loc.analyticsTrendsComingSoon,
              subtitle: loc.analyticsTrendsDesc,
              colorScheme: colorScheme,
              theme: theme,
            ),
            _ComingSoonCard(
              icon: Icons.lightbulb_outline,
              title: loc.aiInsightsComingSoon,
              subtitle: loc.aiInsightsDesc,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

// Modular stat cards row
class _DashboardStatCards extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isAllFranchises;

  const _DashboardStatCards({
    required this.stats,
    required this.loc,
    required this.colorScheme,
    required this.theme,
    required this.isAllFranchises,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      children: [
        _StatCard(
          icon: Icons.attach_money,
          label: loc.dashboardRevenue,
          value: stats['revenue'].toStringAsFixed(2),
          color: colorScheme.primary,
          isCurrency: true,
        ),
        _StatCard(
          icon: Icons.shopping_bag,
          label: loc.dashboardOrders,
          value: stats['orders'].toString(),
          color: colorScheme.secondary,
        ),
        _StatCard(
          icon: Icons.group,
          label: loc.dashboardUniqueCustomers,
          value: stats['uniqueCustomers'].toString(),
          color: colorScheme.tertiary ?? colorScheme.primary,
        ),
        _StatCard(
          icon: Icons.star,
          label: loc.dashboardTopSeller,
          value: stats['topSeller'] ?? '-',
          color: colorScheme.primary,
        ),
        _StatCard(
          icon: Icons.trending_up,
          label: loc.dashboardAvgOrderValue,
          value: stats['avgOrderValue'].toStringAsFixed(2),
          color: colorScheme.primary,
          isCurrency: true,
        ),
        _StatCard(
          icon: Icons.app_settings_alt,
          label: loc.dashboardAppVersion,
          value: stats['appVersion'] ?? '-',
          color: colorScheme.outline,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isCurrency;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isCurrency ? '\$${value}' : value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  final String health;
  final DateTime lastSync;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _SystemHealthCard({
    required this.health,
    required this.lastSync,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String statusLabel;

    if (health == 'ok') {
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
      statusLabel = loc.dashboardHealthGood;
    } else if (health == 'warning') {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
      statusLabel = loc.dashboardHealthWarning;
    } else {
      icon = Icons.error_outline;
      iconColor = Colors.red;
      statusLabel = loc.dashboardHealthError;
    }

    return Card(
      color: colorScheme.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      elevation: DesignTokens.adminCardElevation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 34),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.dashboardLastSync}: ${_formatDateTime(lastSync)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: loc.reload,
              onPressed: () {
                // Optionally, lift this callback via a prop to reload stats.
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DeveloperInsightCards extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final String? franchiseId;

  const _DeveloperInsightCards({
    required this.theme,
    required this.colorScheme,
    required this.loc,
    this.franchiseId,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: Insert real developer insights as built.
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      children: [
        Card(
          color: colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 30),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.developerMetricsComingSoon,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      loc.developerMetricsDesc,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Add more developer-only cards as real features roll out
      ],
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surfaceVariant.withOpacity(0.86),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.outline, size: 34),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
