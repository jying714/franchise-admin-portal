import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/

class AuditTrailSection extends StatefulWidget {
  final String? franchiseId;
  const AuditTrailSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<AuditTrailSection> createState() => _AuditTrailSectionState();
}

enum _AuditSourceMode { franchise, global }

bool _isConcreteFranchiseId(String? id) =>
    id != null &&
    id.isNotEmpty &&
    id != 'unknown' &&
    id != 'default' &&
    id != 'all';

class _AuditTrailSectionState extends State<AuditTrailSection> {
  String? _filterType;
  String? _filterActor;
  _AuditSourceMode _sourceMode = _AuditSourceMode.global;

  void _onTypeFilterChanged(String? newValue) {
    setState(() => _filterType = newValue);
  }

  void _onActorFilterChanged(String? newValue) {
    setState(() => _filterActor = newValue);
  }

  void _onSourceModeChanged(_AuditSourceMode mode) {
    setState(() => _sourceMode = mode);
  }

  Stream<List<shared.AuditLog>>? _auditStream(shared.FirestoreService fs) {
    if (_sourceMode == _AuditSourceMode.global) {
      return fs.auditLogsStreamGlobal();
    }
    if (!_isConcreteFranchiseId(widget.franchiseId)) {
      return null;
    }
    return fs.auditLogsStreamFranchise(widget.franchiseId!);
  }

  AuditEntry _toEntry(shared.AuditLog log) {
    final actor = (log.userEmail != null && log.userEmail!.isNotEmpty)
        ? log.userEmail!
        : (log.userId.isNotEmpty ? log.userId : 'unknown');
    final description = [
      log.action,
      if (log.targetType.isNotEmpty) log.targetType,
      if (log.targetId.isNotEmpty) log.targetId,
      if (log.details != null && log.details!.isNotEmpty) log.details,
    ].join(' · ');
    return AuditEntry(
      timestamp: log.timestamp,
      type: log.action.isNotEmpty ? log.action : log.targetType,
      description: description.isNotEmpty ? description : log.id,
      actor: actor,
      franchiseId: widget.franchiseId,
    );
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

    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final needsFranchise = _sourceMode == _AuditSourceMode.franchise &&
        !_isConcreteFranchiseId(widget.franchiseId);
    final titleSuffix = _sourceMode == _AuditSourceMode.global
        ? 'Global'
        : (_isConcreteFranchiseId(widget.franchiseId)
            ? widget.franchiseId!
            : 'Select a franchise');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.auditTrailSectionTitle} — $titleSuffix',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.auditTrailSectionDesc,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ToggleButtons(
              isSelected: [
                _sourceMode == _AuditSourceMode.franchise,
                _sourceMode == _AuditSourceMode.global,
              ],
              onPressed: (index) {
                _onSourceModeChanged(
                  index == 0
                      ? _AuditSourceMode.franchise
                      : _AuditSourceMode.global,
                );
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Franchise'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 18),
                      SizedBox(width: 6),
                      Text('Global'),
                    ],
                  ),
                ),
              ],
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
                          'Select a franchise to view franchise audit logs.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<List<shared.AuditLog>>(
                stream: _auditStream(fs),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    shared.ErrorLogger.log(
                      message:
                          'Failed to stream audit trail: ${snapshot.error}',
                      source: 'AuditTrailSection',
                      severity: 'warning',
                      contextData: {
                        'franchiseId': widget.franchiseId,
                        'sourceMode': _sourceMode.name,
                      },
                    );
                    return Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${loc.auditTrailSectionError}\n${snapshot.error}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }

                  final entries = (snapshot.data ?? const <shared.AuditLog>[])
                      .map(_toEntry)
                      .toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  final types = entries.map((e) => e.type).toSet().toList()
                    ..sort();
                  final actors = entries.map((e) => e.actor).toSet().toList()
                    ..sort();

                  final filtered = entries.where((entry) {
                    final typeOk =
                        _filterType == null || entry.type == _filterType;
                    final actorOk =
                        _filterActor == null || entry.actor == _filterActor;
                    return typeOk && actorOk;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterRow(loc, types, actors, colorScheme, theme),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        Center(child: Text(loc.auditTrailSectionEmpty))
                      else
                        _AuditTrailList(
                          entries: filtered,
                          colorScheme: colorScheme,
                          loc: loc,
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppLocalizations loc, List<String> types,
      List<String> actors, ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        Text('${loc.auditTrailSectionTypeFilter}:',
            style: theme.textTheme.titleMedium),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: _filterType,
          hint: Text(loc.auditTrailSectionFilterAny),
          items: [
            DropdownMenuItem(
                value: null, child: Text(loc.auditTrailSectionFilterAny)),
            ...types.map(
                (type) => DropdownMenuItem(value: type, child: Text(type))),
          ],
          onChanged: _onTypeFilterChanged,
        ),
        const SizedBox(width: 24),
        Text('${loc.auditTrailSectionActorFilter}:',
            style: theme.textTheme.titleMedium),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: _filterActor,
          hint: Text(loc.auditTrailSectionFilterAny),
          items: [
            DropdownMenuItem(
                value: null, child: Text(loc.auditTrailSectionFilterAny)),
            ...actors.map(
                (actor) => DropdownMenuItem(value: actor, child: Text(actor))),
          ],
          onChanged: _onActorFilterChanged,
        ),
      ],
    );
  }
}

class _AuditTrailList extends StatelessWidget {
  final List<AuditEntry> entries;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _AuditTrailList({
    required this.entries,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final entry = entries[idx];
          return ListTile(
            leading: Icon(Icons.timeline, color: colorScheme.outline),
            title: Text(entry.description),
            subtitle: Text(
              '${loc.auditTrailSectionAt} ${entry.type} â€¢ ${_formatDateTime(entry.timestamp)}\n${loc.auditTrailSectionBy}: ${entry.actor}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing:
                entry.franchiseId != null ? Text(entry.franchiseId!) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(entry.type),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      '${entry.description}\n\n'
                      'Actor: ${entry.actor}\n'
                      'When: ${_formatDateTime(entry.timestamp)}\n'
                      'Franchise: ${entry.franchiseId ?? '—'}',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
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

class AuditEntry {
  final DateTime timestamp;
  final String type;
  final String description;
  final String actor;
  final String? franchiseId;

  AuditEntry({
    required this.timestamp,
    required this.type,
    required this.description,
    required this.actor,
    this.franchiseId,
  });
}
