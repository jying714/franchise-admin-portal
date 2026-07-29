import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/developer/impersonation_dialog.dart';

class ImpersonationToolsSection extends StatefulWidget {
  final String? franchiseId;
  const ImpersonationToolsSection({Key? key, this.franchiseId})
      : super(key: key);

  @override
  State<ImpersonationToolsSection> createState() =>
      _ImpersonationToolsSectionState();
}

bool _isConcreteFranchiseId(String? id) =>
    id != null &&
    id.isNotEmpty &&
    id != 'unknown' &&
    id != 'default' &&
    id != 'all';

class _ImpersonationToolsSectionState extends State<ImpersonationToolsSection> {
  bool _loading = false;
  String? _errorMsg;
  List<UserSummary> _users = [];
  String _search = '';
  UserSummary? _previewUser;
  final List<ImpersonationRecord> _recentPreviews = [];

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  @override
  void didUpdateWidget(covariant ImpersonationToolsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _previewUser = null;
      _fetchUserList();
    }
  }

  Future<void> _fetchUserList() async {
    if (!_isConcreteFranchiseId(widget.franchiseId)) {
      setState(() {
        _users = [];
        _loading = false;
        _errorMsg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final fs = Provider.of<shared.FirestoreService>(context, listen: false);
      final users = await fs.allUsers(franchiseId: widget.franchiseId).first;
      final summaries = users.map((u) {
        final role = u.roles.isNotEmpty ? u.roles.first : 'user';
        return UserSummary(
          id: u.id,
          email: u.email,
          role: role,
        );
      }).toList()
        ..sort((a, b) => a.email.compareTo(b.email));
      setState(() {
        _users = summaries;
        _loading = false;
      });
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
        _users = [];
      });
      shared.ErrorLogger.log(
        message: 'Failed to fetch user list: $e',
        stack: stack.toString(),
        source: 'ImpersonationToolsSection',
        severity: 'warning',
        contextData: {
          'franchiseId': widget.franchiseId,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  void _startPreview(UserSummary user) {
    // Phase A: UI-only. Does NOT call updateUserClaims or issue tokens.
    setState(() {
      _previewUser = user;
      _recentPreviews.insert(
        0,
        ImpersonationRecord(
          userEmail: user.email,
          timestamp: DateTime.now(),
        ),
      );
      if (_recentPreviews.length > 10) {
        _recentPreviews.removeRange(10, _recentPreviews.length);
      }
    });
    shared.ErrorLogger.log(
      message: 'Preview session started (UI-only): ${user.email}',
      source: 'ImpersonationToolsSection',
      severity: 'info',
      contextData: {
        'franchiseId': widget.franchiseId,
        'previewUserId': user.id,
        'previewUserRole': user.role,
        'mode': 'preview_only',
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preview only — viewing as ${user.email} (${user.role}). Auth claims unchanged. Use the dashboard switcher to open HQ/Admin chrome.',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _exitPreview() {
    setState(() => _previewUser = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview cleared.')),
    );
  }

  Future<void> _openImpersonationDialog(
      BuildContext context, String franchiseId) async {
    final user = await showDialog<ImpersonationUser>(
      context: context,
      builder: (ctx) => ImpersonationDialog(franchiseId: franchiseId),
    );
    if (user != null) {
      // TODO: Start impersonation session using user data.
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

    // Developer-only guard (multi-role array)
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.impersonationToolsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.impersonationToolsDesc,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (!_isConcreteFranchiseId(widget.franchiseId))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a franchise to preview users for that tenant.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_previewUser != null) ...[
              MaterialBanner(
                content: Text(
                  'Viewing as ${_previewUser!.email} (${_previewUser!.role}) · ${widget.franchiseId} (preview)',
                ),
                leading: Icon(Icons.visibility, color: colorScheme.primary),
                actions: [
                  TextButton(
                    onPressed: _exitPreview,
                    child: const Text('Exit preview'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_errorMsg != null)
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
                          '${loc.impersonationToolsLoadError}\n$_errorMsg',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: colorScheme.primary),
                        tooltip: loc.reload,
                        onPressed: _fetchUserList,
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: loc.impersonationToolsSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    onChanged: (txt) => setState(() => _search = txt),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                  label: Text(loc.reload),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                  onPressed: _fetchUserList,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            if (!_loading && _users.isNotEmpty)
              _UserList(
                users: _users,
                search: _search,
                onImpersonate: _startPreview,
                impersonatedUser: _previewUser,
                loc: loc,
                colorScheme: colorScheme,
              ),
            if (!_loading && _users.isEmpty && _errorMsg == null)
              Center(child: Text(loc.impersonationToolsNoUsersFound)),
            const SizedBox(height: 30),
            _RecentImpersonationsCard(
              records: _recentPreviews,
              loc: loc,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            Text(
              'Phase A is UI-only. Use the header dashboard switcher to open HQ/Admin. Auth claims are not modified.',
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

class _UserList extends StatelessWidget {
  final List<UserSummary> users;
  final String search;
  final void Function(UserSummary) onImpersonate;
  final UserSummary? impersonatedUser;
  final AppLocalizations loc;
  final ColorScheme colorScheme;

  const _UserList({
    required this.users,
    required this.search,
    required this.onImpersonate,
    required this.impersonatedUser,
    required this.loc,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = users
        .where((u) =>
            u.email.toLowerCase().contains(search.toLowerCase()) ||
            u.role.toLowerCase().contains(search.toLowerCase()))
        .toList();
    if (filtered.isEmpty) {
      return Center(child: Text(loc.impersonationToolsNoUsersFound));
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final user = filtered[idx];
          final isActive = impersonatedUser?.id == user.id;
          return ListTile(
            leading: Icon(Icons.person,
                color: isActive ? colorScheme.primary : colorScheme.outline),
            title: Text(user.email),
            subtitle: Text('${loc.impersonationToolsRoleLabel}: ${user.role}'),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.switch_account_outlined),
              label: Text(isActive ? 'Previewing' : 'Preview'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? colorScheme.secondary : colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: isActive ? null : () => onImpersonate(user),
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

class _RecentImpersonationsCard extends StatelessWidget {
  final List<ImpersonationRecord> records;
  final AppLocalizations loc;
  final ColorScheme colorScheme;

  const _RecentImpersonationsCard({
    required this.records,
    required this.loc,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return Container();
    return Card(
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.outline, size: 24),
                const SizedBox(width: 8),
                Text(
                  loc.impersonationToolsRecentImpersonations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...records.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                      '${r.userEmail}  â€”  ${_formatDateTime(r.timestamp)}'),
                )),
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

// --- Simple DTOs for mock/demo. Replace with your actual user model/record.
class UserSummary {
  final String id;
  final String email;
  final String role;
  UserSummary({required this.id, required this.email, required this.role});
}

class ImpersonationRecord {
  final String userEmail;
  final DateTime timestamp;
  ImpersonationRecord({required this.userEmail, required this.timestamp});
}
