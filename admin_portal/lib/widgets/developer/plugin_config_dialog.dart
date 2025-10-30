import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class PluginConfigDialog extends StatefulWidget {
  final String pluginId;
  final String franchiseId;
  final Map<String, dynamic>? initialConfig;

  const PluginConfigDialog({
    Key? key,
    required this.pluginId,
    required this.franchiseId,
    this.initialConfig,
  }) : super(key: key);

  @override
  State<PluginConfigDialog> createState() => _PluginConfigDialogState();
}

class _PluginConfigDialogState extends State<PluginConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _config;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.initialConfig ?? {});
  }

  void _updateField(String key, dynamic value) {
    setState(() {
      _config[key] = value;
    });
  }

  Future<void> _saveConfig() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Save config to Firestore/service, using pluginId + franchiseId
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _loading = false);
      Navigator.of(context).pop(_config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.pluginConfigDialogSaved)),
      );
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      await ErrorLogger.log(
        message: 'Failed to save plugin config: $e',
        stack: stack.toString(),
        source: 'PluginConfigDialog',
        screen: 'PluginConfigDialog',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'pluginId': widget.pluginId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      // Fallback UI for missing localization:
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;
    final isDeveloper = adminUser?.roles.contains('developer') ?? false;

    if (!isDeveloper) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              loc.unauthorizedAccess,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminDialogRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.extension, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${loc.pluginConfigDialogTitle} — ${widget.pluginId}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: loc.closeButtonLabel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.pluginConfigDialogDesc,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      '${loc.pluginConfigDialogError}\n$_errorMsg',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.error),
                    ),
                  ),
                // ---- Dynamic config fields (demo structure, replace with your real schema) ----
                ..._config.keys.map((key) =>
                    _buildField(key, _config[key], loc, theme, colorScheme)),
                if (_config.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      loc.pluginConfigDialogNoFields,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ),
                // Future/expansion area for plugin-specific field editors here
                const SizedBox(height: 12),
                if (_loading)
                  Center(child: CircularProgressIndicator())
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.undo),
                        label: Text(loc.cancelButtonLabel),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(loc.pluginConfigDialogSaveButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.adminButtonRadius),
                          ),
                          textStyle: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _saveConfig,
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                _ComingSoonCard(
                  icon: Icons.history,
                  title: loc.pluginConfigDialogHistoryComingSoon,
                  subtitle: loc.pluginConfigDialogHistoryDesc,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _ComingSoonCard(
                  icon: Icons.security,
                  title: loc.pluginConfigDialogValidationComingSoon,
                  subtitle: loc.pluginConfigDialogValidationDesc,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String key,
    dynamic value,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        decoration: InputDecoration(
          labelText: key,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.formFieldRadius),
          ),
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceVariant,
        ),
        onChanged: (val) => _updateField(key, val),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.outline, size: 26),
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
                  const SizedBox(height: 3),
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
