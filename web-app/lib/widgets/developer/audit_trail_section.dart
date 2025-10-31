import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../packages/shared_core/lib/src/core/providers/admin_user_provider.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class AuditTrailSection extends StatefulWidget {
  final String? franchiseId;
  const AuditTrailSection({Key? key, this.franchiseId}) : super(key: key);

  @override
  State<AuditTrailSection> createState() => _AuditTrailSectionState();
}

class _AuditTrailSectionState extends State<AuditTrailSection> {
  bool _loading = true;
  String? _errorMsg;
  List<AuditEntry> _entries = [];
  String? _filterType;
  String? _filterActor;

  @override
  void initState() {
    super.initState();
    _fetchAuditTrail();
  }

  @override
  void didUpdateWidget(covariant AuditTrailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _fetchAuditTrail();
    }
  }

  Future<void> _fetchAuditTrail() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with FirestoreService audit log query (by franchiseId/type/actor)
      await Future.delayed(const Duration(milliseconds: 500));
      _entries = [
        AuditEntry(
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
          type: 'MenuUpdate',
          description:
              'Updated price of “Deluxe Pizza” from \$15.99 to \$16.49',
          actor: 'jane@doughboys.com',
          franchiseId: widget.franchiseId == 'all'
              ? 'doughboyspizzeria'
              : widget.franchiseId,
        ),
        AuditEntry(
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
          type: 'OrderRefund',
          description: 'Issued refund for order #4562',
          actor: 'manager@doughboys.com',
          franchiseId: widget.franchiseId == 'all'
              ? 'doughboyspizzeria'
              : widget.franchiseId,
        ),
        AuditEntry(
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          type: 'UserPermission',
          description: 'Granted admin privileges to staff1@doughboys.com',
          actor: 'owner@doughboys.com',
          franchiseId: widget.franchiseId == 'all'
              ? 'doughboyspizzeria'
              : widget.franchiseId,
        ),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      await ErrorLogger.log(
        message: 'Failed to load audit trail: $e',
        stack: stack.toString(),
        source: 'AuditTrailSection',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
        contextData: {
          'franchiseId': widget.franchiseId,
        },
      );
    }
  }

  void _onTypeFilterChanged(String? newValue) {
    setState(() {
      _filterType = newValue;
    });
  }

  void _onActorFilterChanged(String? newValue) {
    setState(() {
      _filterActor = newValue;
    });
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

    final isAllFranchises = widget.franchiseId == 'all';

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

    // Extract unique types and actors for filters (for real: get from backend or unique on all entries)
    final types = _entries.map((e) => e.type).toSet().toList()..sort();
    final actors = _entries.map((e) => e.actor).toSet().toList()..sort();

    final filtered = _entries.where((entry) {
      final typeOk = _filterType == null || entry.type == _filterType;
      final actorOk = _filterActor == null || entry.actor == _filterActor;
      return typeOk && actorOk;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAllFranchises
                ? '${loc.auditTrailSectionTitle} — ${loc.allFranchisesLabel ?? "All Franchises"}'
                : '${loc.auditTrailSectionTitle} — ${widget.franchiseId}',
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
          const SizedBox(height: 18),
          _buildFilterRow(loc, types, actors, colorScheme, theme),
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
                        '${loc.auditTrailSectionError}\n$_errorMsg',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.primary),
                      tooltip: loc.reload,
                      onPressed: _fetchAuditTrail,
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            Center(child: Text(loc.auditTrailSectionEmpty))
          else
            _AuditTrailList(
              entries: filtered,
              colorScheme: colorScheme,
              loc: loc,
            ),
          const SizedBox(height: 32),
          _ComingSoonCard(
            icon: Icons.compare_arrows,
            title: loc.auditTrailSectionRevertComingSoon,
            subtitle: loc.auditTrailSectionRevertDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _ComingSoonCard(
            icon: Icons.auto_fix_high_outlined,
            title: loc.auditTrailSectionExplainComingSoon,
            subtitle: loc.auditTrailSectionExplainDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
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
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: loc.reload,
          onPressed: _fetchAuditTrail,
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
              '${loc.auditTrailSectionAt} ${entry.type} • ${_formatDateTime(entry.timestamp)}\n${loc.auditTrailSectionBy}: ${entry.actor}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing:
                entry.franchiseId != null ? Text(entry.franchiseId!) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            onTap: () {
              // TODO: Show full audit entry modal/details.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.comingSoon)),
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
