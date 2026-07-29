import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class FeatureTogglesSection extends StatefulWidget {
  final String? franchiseId;

  const FeatureTogglesSection({super.key, this.franchiseId});

  @override
  State<FeatureTogglesSection> createState() => _FeatureTogglesSectionState();
}

bool _isConcreteFranchiseId(String? id) =>
    id != null &&
    id.isNotEmpty &&
    id != 'unknown' &&
    id != 'default' &&
    id != 'all';

enum _FeatureToggleScope { franchise, global }

class _FeatureTogglesSectionState extends State<FeatureTogglesSection> {
  bool _loading = true;
  String? _errorMsg;
  List<FeatureToggle> _toggles = [];
  _FeatureToggleScope _scope = _FeatureToggleScope.franchise;

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

  List<FeatureToggle> _mapFromDoc(Map<String, dynamic> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) {
      final enabled = e.value == true || e.value == 'true' || e.value == 1;
      return FeatureToggle(
        key: e.key,
        name: e.key,
        description: 'config/features → ${e.key}',
        enabled: enabled,
      );
    }).toList();
  }

  Future<void> _fetchFeatureToggles() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final fs = Provider.of<shared.FirestoreService>(context, listen: false);

      if (_scope == _FeatureToggleScope.global) {
        final data = await fs.getGlobalFeatureToggles();
        setState(() {
          _toggles = _mapFromDoc(data);
          _loading = false;
        });
        return;
      }

      if (!_isConcreteFranchiseId(widget.franchiseId)) {
        setState(() {
          _toggles = [];
          _loading = false;
          _errorMsg = null;
        });
        return;
      }

      final data = await fs.getFranchiseFeatureToggles(widget.franchiseId!);
      setState(() {
        _toggles = _mapFromDoc(data);
        _loading = false;
      });
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
        _toggles = [];
      });

      shared.ErrorLogger.log(
        message: 'Failed to load feature toggles: $e',
        stack: stack.toString(),
        source: 'FeatureTogglesSection',
        severity: 'warning',
        contextData: {
          'franchiseId': widget.franchiseId,
          'scope': _scope.name,
        },
      );
    }
  }

  Future<void> _setFeatureToggle(FeatureToggle toggle, bool enabled) async {
    if (_scope != _FeatureToggleScope.franchise ||
        !_isConcreteFranchiseId(widget.franchiseId)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update feature toggle?'),
        content: Text(
          'Set "${toggle.key}" to ${enabled ? "enabled" : "disabled"} '
          'for franchise ${widget.franchiseId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final fs = Provider.of<shared.FirestoreService>(context, listen: false);
      await fs.updateFeatureToggle(
        widget.franchiseId!,
        toggle.key,
        enabled,
      );
      setState(() {
        _toggles = _toggles
            .map((ft) =>
                ft.key == toggle.key ? ft.copyWith(enabled: enabled) : ft)
            .toList();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${toggle.key} → $enabled'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      shared.ErrorLogger.log(
        message: 'Feature toggle updated: ${toggle.key} -> $enabled',
        source: 'FeatureTogglesSection',
        severity: 'info',
        contextData: {
          'franchiseId': widget.franchiseId,
          'featureKey': toggle.key,
          'enabled': enabled,
          'event': 'feature_toggle',
        },
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update feature toggle: $e',
        stack: stack.toString(),
        source: 'FeatureTogglesSection',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'featureKey': toggle.key,
          'enabled': enabled,
        },
      );
      if (!mounted) return;
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
      return const Scaffold(
        body: Center(child: Text('Localization missing')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final adminUser = Provider.of<shared.AdminUserProvider>(context).user;
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

    final readOnly = _scope == _FeatureToggleScope.global;
    final needsFranchise = _scope == _FeatureToggleScope.franchise &&
        !_isConcreteFranchiseId(widget.franchiseId);
    final titleSuffix = _scope == _FeatureToggleScope.global
        ? 'Global (read-only)'
        : (_isConcreteFranchiseId(widget.franchiseId)
            ? widget.franchiseId!
            : 'Select a franchise');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc.featureTogglesSectionTitle} — $titleSuffix',
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
          const SizedBox(height: 16),
          SegmentedButton<_FeatureToggleScope>(
            segments: const [
              ButtonSegment<_FeatureToggleScope>(
                value: _FeatureToggleScope.franchise,
                label: Text('Franchise'),
                icon: Icon(Icons.store_outlined),
              ),
              ButtonSegment<_FeatureToggleScope>(
                value: _FeatureToggleScope.global,
                label: Text('Global'),
                icon: Icon(Icons.public),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: (set) {
              if (set.isEmpty) return;
              setState(() => _scope = set.first);
              _fetchFeatureToggles();
            },
          ),
          const SizedBox(height: 20),
          if (needsFranchise)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a franchise to view and edit franchise feature toggles.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_loading)
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
              isAllFranchises: readOnly,
            ),
          if (readOnly) ...[
            const SizedBox(height: 12),
            Text(
              'Global platform features are read-only in Developer Dashboard v1.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
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
