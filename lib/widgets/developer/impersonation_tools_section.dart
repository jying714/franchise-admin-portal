import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/developer/impersonation_dialog.dart';

class ImpersonationToolsSection extends StatefulWidget {
  final String franchiseId;
  const ImpersonationToolsSection({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<ImpersonationToolsSection> createState() =>
      _ImpersonationToolsSectionState();
}

class _ImpersonationToolsSectionState extends State<ImpersonationToolsSection> {
  bool _loading = false;
  String? _errorMsg;
  List<UserSummary> _users = [];
  String _search = '';
  UserSummary? _selectedUser;
  List<ImpersonationRecord> _recentImpersonations = [];

  @override
  void initState() {
    super.initState();
    _fetchUserList();
    _fetchRecentImpersonations();
  }

  Future<void> _fetchUserList() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      // TODO: Replace with real FirestoreService user query, filtered by franchiseId
      await Future.delayed(const Duration(milliseconds: 500));
      // Placeholder users; replace with real query results
      _users = [
        UserSummary(id: 'user1', email: 'jane@doughboys.com', role: 'owner'),
        UserSummary(id: 'user2', email: 'staff1@doughboys.com', role: 'staff'),
        UserSummary(id: 'user3', email: 'driver@doughboys.com', role: 'driver'),
      ];
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Failed to fetch user list: $e',
        stackTrace: stack.toString(),
        source: 'ImpersonationToolsSection',
        screen: 'ImpersonationToolsSection',
        errorType: e.runtimeType.toString(),
        severity: 'warning',
        contextData: {},
      );
    }
  }

  Future<void> _fetchRecentImpersonations() async {
    try {
      // TODO: Replace with real FirestoreService query for recent impersonations
      await Future.delayed(const Duration(milliseconds: 300));
      // Placeholder impersonations
      _recentImpersonations = [
        ImpersonationRecord(
            userEmail: 'jane@doughboys.com',
            timestamp: DateTime.now().subtract(const Duration(hours: 2))),
        ImpersonationRecord(
            userEmail: 'driver@doughboys.com',
            timestamp: DateTime.now().subtract(const Duration(days: 1))),
      ];
      setState(() {});
    } catch (e, stack) {
      // Non-blocking; just log error
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Failed to fetch impersonation records: $e',
        stackTrace: stack.toString(),
        source: 'ImpersonationToolsSection',
        screen: 'ImpersonationToolsSection',
        errorType: e.runtimeType.toString(),
        severity: 'info',
        contextData: {},
      );
    }
  }

  Future<void> _impersonateUser(UserSummary user) async {
    try {
      // TODO: Implement real impersonation logic with backend/service
      await Future.delayed(const Duration(milliseconds: 400));
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Impersonation started: ${user.email}',
        source: 'ImpersonationToolsSection',
        screen: 'ImpersonationToolsSection',
        errorType: 'impersonation',
        severity: 'info',
        contextData: {
          'impersonatedUserId': user.id,
          'impersonatedUserRole': user.role,
        },
      );
      setState(() {
        _selectedUser = user;
        _recentImpersonations.insert(
            0,
            ImpersonationRecord(
              userEmail: user.email,
              timestamp: DateTime.now(),
            ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.email} impersonated.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e, stack) {
      setState(() => _selectedUser = null);
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Impersonation failed: $e',
        stackTrace: stack.toString(),
        source: 'ImpersonationToolsSection',
        screen: 'ImpersonationToolsSection',
        errorType: e.runtimeType.toString(),
        severity: 'error',
        contextData: {
          'impersonatedUserId': user.id,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impersonation failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminUser = Provider.of<AdminUserProvider>(context).user;

    // Developer-only guard
    if (adminUser == null || adminUser.role != 'developer') {
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

          // User search/filter
          if (_users.isNotEmpty) ...[
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
          ],

          if (_loading)
            Center(
                child: CircularProgressIndicator(color: colorScheme.primary)),

          // User list to impersonate
          if (!_loading && _users.isNotEmpty)
            _UserList(
              users: _users,
              search: _search,
              onImpersonate: _impersonateUser,
              impersonatedUser: _selectedUser,
              loc: loc,
              colorScheme: colorScheme,
            ),

          if (!_loading && _users.isEmpty && _errorMsg == null)
            Center(child: Text(loc.impersonationToolsNoUsersFound)),

          const SizedBox(height: 30),

          // Recent impersonations
          _RecentImpersonationsCard(
            records: _recentImpersonations,
            loc: loc,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 30),

          // Future features/expansion areas
          _ComingSoonCard(
            icon: Icons.admin_panel_settings,
            title: loc.impersonationToolsAuditTrailComingSoon,
            subtitle: loc.impersonationToolsAuditTrailDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _ComingSoonCard(
            icon: Icons.security,
            title: loc.impersonationToolsRolePreviewComingSoon,
            subtitle: loc.impersonationToolsRolePreviewDesc,
            colorScheme: colorScheme,
            theme: theme,
          ),
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
              label: Text(isActive
                  ? loc.impersonationToolsImpersonating
                  : loc.impersonationToolsImpersonate),
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
                      '${r.userEmail}  —  ${_formatDateTime(r.timestamp)}'),
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
