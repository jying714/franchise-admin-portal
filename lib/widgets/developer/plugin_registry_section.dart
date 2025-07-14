import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/developer/plugin_config_dialog.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class PluginRegistrySection extends StatefulWidget {
  final String? franchiseId;
  const PluginRegistrySection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<PluginRegistrySection> createState() => _PluginRegistrySectionState();
}

class _PluginRegistrySectionState extends State<PluginRegistrySection> {
  bool _loading = true;
  String? _errorMsg;
  List<PluginIntegration> _plugins = [];

  @override
  void initState() {
    super.initState();
    _fetchPlugins();
  }

  @override
  void didUpdateWidget(covariant PluginRegistrySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchPlugins();
    }
  }

  Future<void> _fetchPlugins() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService fetch for plugins by franchiseId
      await Future.delayed(const Duration(milliseconds: 500));
      _plugins = [
        PluginIntegration(
          key: 'mailchimp',
          name: 'Mailchimp',
          description: 'Customer marketing & email campaigns.',
          enabled: widget.franchiseId == 'all' ? false : true,
          status: 'connected',
          lastSync: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PluginIntegration(
          key: 'slack_alerts',
          name: 'Slack Alerts',
          description: 'Order and error notifications in Slack.',
          enabled: false,
          status: 'disconnected',
          lastSync: null,
        ),
        PluginIntegration(
          key: 'custom_delivery',
          name: 'Custom Delivery Provider',
          description: 'Integrate with a 3rd-party delivery API.',
          enabled: false,
          status: 'error',
          lastSync: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      await ErrorLogger.log(
        message: 'Failed to load plugins: $e',
        stack: stack.toString(),
        source: 'PluginRegistrySection',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
        contextData: {
          'franchiseId': widget.franchiseId,
        },
      );
    }
  }

  Future<void> _togglePlugin(PluginIntegration plugin, bool enabled) async {
    try {
      // TODO: Implement actual plugin enable/disable logic in FirestoreService
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() {
        _plugins = _plugins
            .map((p) => p.key == plugin.key ? p.copyWith(enabled: enabled) : p)
            .toList();
      });
      await ErrorLogger.log(
        message: 'Plugin toggled: ${plugin.key} -> $enabled',
        source: 'PluginRegistrySection',
        screen: 'DeveloperDashboardScreen',
        severity: 'info',
        contextData: {
          'franchiseId': widget.franchiseId,
          'pluginKey': plugin.key,
          'enabled': enabled,
        },
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to toggle plugin: $e',
        stack: stack.toString(),
        source: 'PluginRegistrySection',
        screen: 'DeveloperDashboardScreen',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'pluginKey': plugin.key,
          'enabled': enabled,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update plugin: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
                ? '${loc.pluginRegistrySectionTitle} — ${loc.allFranchisesLabel ?? "All Franchises"}'
                : '${loc.pluginRegistrySectionTitle} — ${widget.franchiseId}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.pluginRegistrySectionDesc,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
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
                        '${loc.pluginRegistrySectionError}\n$_errorMsg',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.primary),
                      tooltip: loc.reload,
                      onPressed: _fetchPlugins,
                    ),
                  ],
                ),
              ),
            )
          else if (_plugins.isEmpty)
            Center(child: Text(loc.pluginRegistrySectionEmpty))
          else
            _PluginList(
              plugins: _plugins,
              onToggle: _togglePlugin,
              colorScheme: colorScheme,
              loc: loc,
              isAllFranchises: isAllFranchises,
            ),
          const SizedBox(height: 34),
          _ComingSoonCard(
            icon: Icons.analytics_outlined,
            title: loc.pluginRegistrySectionMonitoringComingSoon,
            subtitle: loc.pluginRegistrySectionMonitoringDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _ComingSoonCard(
            icon: Icons.extension_rounded,
            title: loc.pluginRegistrySectionMarketplaceComingSoon,
            subtitle: loc.pluginRegistrySectionMarketplaceDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _PluginList extends StatelessWidget {
  final List<PluginIntegration> plugins;
  final void Function(PluginIntegration, bool) onToggle;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final bool isAllFranchises;

  const _PluginList({
    required this.plugins,
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
        itemCount: plugins.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final plugin = plugins[idx];
          return ListTile(
            leading: Icon(Icons.extension, color: colorScheme.outline),
            title: Text(plugin.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plugin.description),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      plugin.status == 'connected'
                          ? Icons.check_circle_outline
                          : plugin.status == 'error'
                              ? Icons.error
                              : Icons.link_off,
                      size: 18,
                      color: plugin.status == 'connected'
                          ? Colors.green
                          : plugin.status == 'error'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      plugin.status == 'connected'
                          ? loc.pluginRegistrySectionStatusConnected
                          : plugin.status == 'error'
                              ? loc.pluginRegistrySectionStatusError
                              : loc.pluginRegistrySectionStatusDisconnected,
                      style: TextStyle(
                        color: plugin.status == 'connected'
                            ? Colors.green
                            : plugin.status == 'error'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (plugin.lastSync != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${loc.pluginRegistrySectionLastSync}: ${_formatDateTime(plugin.lastSync!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ]
                  ],
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isAllFranchises
                    ? Tooltip(
                        message: loc.pluginRegistrySectionNoGlobalToggle,
                        child: Switch(
                          value: plugin.enabled,
                          onChanged: null,
                        ),
                      )
                    : Switch(
                        value: plugin.enabled,
                        onChanged: (v) => onToggle(plugin, v),
                      ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip:
                      loc.pluginRegistrySectionConfigureButton, // Add to ARB!
                  onPressed: () {
                    final franchiseId =
                        Provider.of<FranchiseProvider>(context, listen: false)
                            .franchiseId;
                    showDialog(
                      context: context,
                      builder: (_) => PluginConfigDialog(
                        pluginId: plugin.key,
                        franchiseId: franchiseId,
                        initialConfig: <String,
                            dynamic>{}, // Replace with actual config when available
                      ),
                    );
                  },
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

class PluginIntegration {
  final String key;
  final String name;
  final String description;
  final bool enabled;
  final String status; // connected, error, disconnected
  final DateTime? lastSync;

  PluginIntegration({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
    required this.status,
    required this.lastSync,
  });

  PluginIntegration copyWith({
    String? key,
    String? name,
    String? description,
    bool? enabled,
    String? status,
    DateTime? lastSync,
  }) {
    return PluginIntegration(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
