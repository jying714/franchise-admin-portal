import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:cloud_firestore/cloud_firestore.dart';

class SchemaBrowserSection extends StatefulWidget {
  final String? franchiseId;
  const SchemaBrowserSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<SchemaBrowserSection> createState() => _SchemaBrowserSectionState();
}

bool _isConcreteFranchiseId(String? id) =>
    id != null &&
    id.isNotEmpty &&
    id != 'unknown' &&
    id != 'default' &&
    id != 'all';

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
      _selectedSchemaId = null;
      _fetchSchemas();
    }
  }

  Future<void> _fetchSchemas() async {
    if (!_isConcreteFranchiseId(widget.franchiseId)) {
      setState(() {
        _schemas = [];
        _selectedSchemaId = null;
        _loading = false;
        _errorMsg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final franchiseId = widget.franchiseId!;
    final now = DateTime.now();
    final db = FirebaseFirestore.instance;

    Future<SchemaSummary> inventory(
      String collectionId, {
      bool isConfigDoc = false,
      String? configDocId,
    }) async {
      try {
        if (isConfigDoc) {
          final doc = await db
              .collection('franchises')
              .doc(franchiseId)
              .collection('config')
              .doc(configDocId ?? 'features')
              .get();
          final data = doc.data() ?? <String, dynamic>{};
          final keys = data.keys.toList()..sort();
          return SchemaSummary(
            id: 'config/${configDocId ?? 'features'}',
            name: 'config/${configDocId ?? 'features'}',
            version: 'keys=${keys.length}',
            updatedAt: now,
            status: keys.isEmpty ? 'empty' : 'active',
            docCount: keys.length,
            sampleFieldKeys:
                keys.isEmpty ? '(no sample doc)' : keys.take(24).join(', '),
          );
        }

        final col = db
            .collection('franchises')
            .doc(franchiseId)
            .collection(collectionId);
        final snap = await col.limit(50).get();
        final count = snap.docs.length;
        final sample = snap.docs.isEmpty
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(snap.docs.first.data());
        final keys = sample.keys.toList()..sort();
        return SchemaSummary(
          id: collectionId,
          name: collectionId,
          version: count >= 50 ? 'count≥50 (sample)' : 'count=$count',
          updatedAt: now,
          status: count == 0 ? 'empty' : 'active',
          docCount: count,
          sampleFieldKeys:
              keys.isEmpty ? '(no sample doc)' : keys.take(24).join(', '),
        );
      } catch (e, stack) {
        shared.ErrorLogger.log(
          message: 'SchemaBrowser inventory $collectionId failed: $e',
          stack: stack.toString(),
          source: 'SchemaBrowserSection',
          severity: 'warning',
          contextData: {'franchiseId': franchiseId},
        );
        return SchemaSummary(
          id: collectionId,
          name: collectionId,
          version: 'error',
          updatedAt: now,
          status: 'error',
          docCount: 0,
          sampleFieldKeys: e.toString(),
        );
      }
    }

    try {
      final list = <SchemaSummary>[
        await inventory('menu_items'),
        await inventory('categories'),
        await inventory('ingredient_metadata'),
        await inventory('promotions'),
        await inventory('config', isConfigDoc: true, configDocId: 'features'),
      ];

      if (!mounted) return;
      setState(() {
        _schemas = list;
        _loading = false;
        _errorMsg = null;
      });
    } catch (e, stack) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
        _schemas = [];
      });
      shared.ErrorLogger.log(
        message: 'Failed to load schemas: $e',
        stack: stack.toString(),
        source: 'SchemaBrowserSection',
        severity: 'warning',
        contextData: {'franchiseId': widget.franchiseId},
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

    final needsFranchise = !_isConcreteFranchiseId(widget.franchiseId);
    final titleSuffix =
        needsFranchise ? 'Select a franchise' : widget.franchiseId!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.schemaBrowserSectionTitle} — $titleSuffix',
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
                          'Select a franchise to inspect per-tenant collections.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading)
              Center(
                  child: CircularProgressIndicator(color: colorScheme.primary))
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
            else ...[
              _SchemaList(
                schemas: _schemas,
                onSelect: (id) => setState(() => _selectedSchemaId = id),
                colorScheme: colorScheme,
                loc: loc,
                selectedId: _selectedSchemaId,
              ),
              const SizedBox(height: 24),
              if (_selectedSchemaId != null)
                _SchemaDetailCard(
                  schema: _schemas.firstWhere((s) => s.id == _selectedSchemaId),
                  loc: loc,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
            ],
          ],
        ),
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
            subtitle: Text(
              '${schema.docCount} docs · ${schema.status}',
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
              'Document count: ${schema.docCount}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sample field keys:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              schema.sampleFieldKeys,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
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

class SchemaSummary {
  final String id;
  final String name;
  final String version;
  final DateTime updatedAt;
  final String status; // active, empty
  final int docCount;
  final String sampleFieldKeys;

  SchemaSummary({
    required this.id,
    required this.name,
    required this.version,
    required this.updatedAt,
    required this.status,
    required this.docCount,
    required this.sampleFieldKeys,
  });
}
