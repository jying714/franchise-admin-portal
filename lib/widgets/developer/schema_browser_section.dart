import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class SchemaBrowserSection extends StatefulWidget {
  final String franchiseId;
  const SchemaBrowserSection({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<SchemaBrowserSection> createState() => _SchemaBrowserSectionState();
}

class _SchemaBrowserSectionState extends State<SchemaBrowserSection> {
  bool _loading = true;
  String? _errorMsg;
  List<SchemaSummary> _schemas = [];
  String? _selectedSchemaId;

  @override
  void initState() {
    super.initState();
    _fetchSchemas();
  }

  @override
  void didUpdateWidget(covariant SchemaBrowserSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchSchemas();
    }
  }

  Future<void> _fetchSchemas() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService call for schema metadata
      await Future.delayed(const Duration(milliseconds: 500));
      _schemas = [
        SchemaSummary(
          id: 'menu',
          name: 'Menu',
          version: 'v3',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: 'active',
        ),
        SchemaSummary(
          id: 'category',
          name: 'Category',
          version: 'v2',
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
          status: 'deprecated',
        ),
        SchemaSummary(
          id: 'modifier',
          name: 'Modifier',
          version: 'v1',
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          status: 'active',
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Failed to load schemas: $e',
        stackTrace: stack.toString(),
        source: 'SchemaBrowserSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
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
    final isDeveloper = adminUser?.role == 'developer';

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
                ? '${loc.schemaBrowserSectionTitle} — ${loc.allFranchisesLabel ?? "All Franchises"}'
                : '${loc.schemaBrowserSectionTitle} — ${widget.franchiseId}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.schemaBrowserSectionDesc,
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
                        '${loc.schemaBrowserSectionError}\n$_errorMsg',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.primary),
                      tooltip: loc.reload,
                      onPressed: _fetchSchemas,
                    ),
                  ],
                ),
              ),
            )
          else if (_schemas.isEmpty)
            Center(child: Text(loc.schemaBrowserSectionEmpty))
          else
            _SchemaList(
              schemas: _schemas,
              onSelect: (id) => setState(() => _selectedSchemaId = id),
              colorScheme: colorScheme,
              loc: loc,
              selectedId: _selectedSchemaId,
            ),
          const SizedBox(height: 32),
          if (_selectedSchemaId != null)
            _SchemaDetailCard(
              schema: _schemas.firstWhere((s) => s.id == _selectedSchemaId),
              loc: loc,
              theme: theme,
              colorScheme: colorScheme,
            ),
          const SizedBox(height: 32),
          _ComingSoonCard(
            icon: Icons.compare_arrows,
            title: loc.schemaBrowserSectionDiffsComingSoon,
            subtitle: loc.schemaBrowserSectionDiffsDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _ComingSoonCard(
            icon: Icons.check_circle_outline,
            title: loc.schemaBrowserSectionValidationComingSoon,
            subtitle: loc.schemaBrowserSectionValidationDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _SchemaList extends StatelessWidget {
  final List<SchemaSummary> schemas;
  final ValueChanged<String> onSelect;
  final ColorScheme colorScheme;
  final AppLocalizations loc;
  final String? selectedId;

  const _SchemaList({
    required this.schemas,
    required this.onSelect,
    required this.colorScheme,
    required this.loc,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: schemas.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final schema = schemas[idx];
          final isActive = selectedId == schema.id;
          return ListTile(
            leading: Icon(Icons.schema, color: colorScheme.outline),
            title: Text('${schema.name} (${schema.version})'),
            subtitle: Row(
              children: [
                Text(
                    '${loc.schemaBrowserSectionUpdated}: ${_formatDateTime(schema.updatedAt)}'),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: schema.status == 'active'
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    schema.status == 'active'
                        ? loc.schemaBrowserSectionStatusActive
                        : loc.schemaBrowserSectionStatusDeprecated,
                    style: TextStyle(
                      color: schema.status == 'active'
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            trailing: isActive
                ? Icon(Icons.arrow_right, color: colorScheme.primary)
                : null,
            onTap: () => onSelect(schema.id),
            selected: isActive,
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

class _SchemaDetailCard extends StatelessWidget {
  final SchemaSummary schema;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _SchemaDetailCard({
    required this.schema,
    required this.loc,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Replace placeholder with full schema fields, JSON, versioning, etc.
    return Card(
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.schemaBrowserSectionSchemaDetails}: ${schema.name} (${schema.version})',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${loc.schemaBrowserSectionLastUpdated}: ${_formatDateTime(schema.updatedAt)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              loc.schemaBrowserSectionDetailsPlaceholder,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.outline,
              ),
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

class SchemaSummary {
  final String id;
  final String name;
  final String version;
  final DateTime updatedAt;
  final String status; // active, deprecated

  SchemaSummary({
    required this.id,
    required this.name,
    required this.version,
    required this.updatedAt,
    required this.status,
  });
}
