import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class FeatureTogglesSection extends StatefulWidget {
  final String? franchiseId;
  const FeatureTogglesSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<FeatureTogglesSection> createState() => _FeatureTogglesSectionState();
}

class _FeatureTogglesSectionState extends State<FeatureTogglesSection> {
  bool _loading = true;
  String? _errorMsg;
  List<FeatureToggle> _toggles = [];

  @override
  void initState() {
    super.initState();
    _fetchFeatureToggles();
  }

  @override
  void didUpdateWidget(covariant FeatureTogglesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchFeatureToggles();
    }
  }

  Future<void> _fetchFeatureToggles() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService feature toggle fetch
      await Future.delayed(const Duration(milliseconds: 500));
      _toggles = [
        FeatureToggle(
          key: 'bulk_order_upload',
          name: 'Bulk Order Upload',
          description: 'Enable uploading orders via CSV/Excel.',
          enabled: widget.franchiseId == 'all' ? false : true,
        ),
        FeatureToggle(
          key: 'experimental_ai_recommendations',
          name: 'AI Menu Recommendations',
          description: 'Show AI-driven menu suggestions to users.',
          enabled: false,
        ),
        FeatureToggle(
          key: 'beta_coupon_engine',
          name: 'Beta Coupon Engine',
          description: 'Test new discount/coupon engine.',
          enabled: false,
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      await ErrorLogger.log(
        message: 'Failed to load feature toggles: $e',
        stack: stack.toString(),
        source: 'FeatureTogglesSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
        contextData: {
          'franchiseId': widget.franchiseId,
        },
      );
    }
  }

  Future<void> _setFeatureToggle(FeatureToggle toggle, bool enabled) async {
    try {
      // TODO: Persist feature toggle change with FirestoreService
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() {
        _toggles = _toggles
            .map((ft) =>
                ft.key == toggle.key ? ft.copyWith(enabled: enabled) : ft)
            .toList();
      });
      await ErrorLogger.log(
        message: 'Feature toggle updated: ${toggle.key} -> $enabled',
        source: 'FeatureTogglesSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'info',
        contextData: {
          'franchiseId': widget.franchiseId,
          'featureKey': toggle.key,
          'enabled': enabled,
          'event': 'feature_toggle',
        },
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update feature toggle: $e',
        stack: stack.toString(),
        source: 'FeatureTogglesSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'featureKey': toggle.key,
          'enabled': enabled,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update toggle: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;

    if (!isDeveloper) {
      return Center(
        child: Text(
          loc.unauthorizedAccess,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final isAllFranchises = widget.franchiseId == 'all';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAllFranchises
                ? '${loc.featureTogglesSectionTitle} — ${loc.allFranchisesLabel ?? "All Franchises"}'
                : '${loc.featureTogglesSectionTitle} — ${widget.franchiseId}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.featureTogglesSectionDesc,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (_loading)
            Center(child: CircularProgressIndicator(color: colorScheme.primary))
          else if (_errorMsg != null)
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${loc.featureTogglesSectionError}\n$_errorMsg',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.primary),
                      tooltip: loc.reload,
                      onPressed: _fetchFeatureToggles,
                    ),
                  ],
                ),
              ),
            )
          else if (_toggles.isEmpty)
            Center(child: Text(loc.featureTogglesSectionEmpty))
          else
            _FeatureToggleList(
              toggles: _toggles,
              onToggle: _setFeatureToggle,
              colorScheme: colorScheme,
              loc: loc,
              isAllFranchises: isAllFranchises,
            ),
          const SizedBox(height: 34),
          _ComingSoonCard(
            icon: Icons.analytics,
            title: loc.featureTogglesSectionAuditTrailComingSoon,
            subtitle: loc.featureTogglesSectionAuditTrailDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _ComingSoonCard(
            icon: Icons.lightbulb_outline,
            title: loc.featureTogglesSectionAIBasedComingSoon,
            subtitle: loc.featureTogglesSectionAIBasedDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _FeatureToggleList extends StatelessWidget {
  final List<FeatureToggle> toggles;
  final void Function(FeatureToggle, bool) onToggle;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final bool isAllFranchises;

  const _FeatureToggleList({
    required this.toggles,
    required this.onToggle,
    required this.colorScheme,
    required this.loc,
    required this.isAllFranchises,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: toggles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final toggle = toggles[idx];
          return ListTile(
            leading: Icon(Icons.settings, color: colorScheme.outline),
            title: Text(toggle.name),
            subtitle: Text(toggle.description),
            trailing: isAllFranchises
                ? Tooltip(
                    message: loc.featureTogglesSectionNoGlobalToggle,
                    child: Switch(
                      value: toggle.enabled,
                      onChanged: null,
                    ),
                  )
                : Switch(
                    value: toggle.enabled,
                    onChanged: (v) => onToggle(toggle, v),
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
          );
        },
      ),
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
      color: colorScheme.surfaceVariant.withOpacity(0.87),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.outline, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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

class FeatureToggle {
  final String key;
  final String name;
  final String description;
  final bool enabled;

  FeatureToggle({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
  });

  FeatureToggle copyWith({
    String? key,
    String? name,
    String? description,
    bool? enabled,
  }) {
    return FeatureToggle(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }
}
