import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class ImpersonationDialog extends StatefulWidget {
  final String franchiseId;
  const ImpersonationDialog({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<ImpersonationDialog> createState() => _ImpersonationDialogState();
}

class _ImpersonationDialogState extends State<ImpersonationDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;
  List<ImpersonationUser> _users = [];
  ImpersonationUser? _selectedUser;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers([String? query]) async {
    setState(() {
      _loading = true;
      _errorMsg = null;
      _users = [];
    });
    try {
      // TODO: Replace with real FirestoreService user query, optionally using [query].
      await Future.delayed(const Duration(milliseconds: 400));
      final all = [
        ImpersonationUser(
            id: '1',
            email: 'demo@doughboys.com',
            name: 'Demo Customer',
            role: 'customer'),
        ImpersonationUser(
            id: '2',
            email: 'manager@doughboys.com',
            name: 'Franchise Manager',
            role: 'manager'),
        ImpersonationUser(
            id: '3',
            email: 'dev@doughboys.com',
            name: 'Developer User',
            role: 'developer'),
        ImpersonationUser(
            id: '4',
            email: 'testuser@doughboys.com',
            name: 'Test User',
            role: 'customer'),
      ];
      if (query != null && query.trim().isNotEmpty) {
        _users = all
            .where((u) =>
                u.email.toLowerCase().contains(query.trim().toLowerCase()) ||
                u.name.toLowerCase().contains(query.trim().toLowerCase()))
            .toList();
      } else {
        _users = all;
      }
      setState(() => _loading = false);
    } catch (e, stack) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
      Provider.of<FirestoreService>(context, listen: false).logError(
        widget.franchiseId,
        message: 'Failed to fetch users for impersonation: $e',
        stackTrace: stack.toString(),
        source: 'ImpersonationDialog',
        screen: 'DeveloperDashboardScreen',
        severity: 'warning',
        contextData: {},
      );
    }
  }

  void _onSearchChanged() {
    _fetchUsers(_searchController.text);
  }

  void _onImpersonate(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.impersonationDialogSelectUserFirst)),
      );
      return;
    }
    // TODO: Wire in actual impersonation logic, update provider/session, redirect as needed.
    Navigator.of(context).pop(_selectedUser);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${loc.impersonationDialogSuccessPrefix} ${_selectedUser!.email}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.switch_account,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    loc.impersonationDialogTitle,
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
              const SizedBox(height: 12),
              _SecurityNotice(loc: loc, colorScheme: colorScheme, theme: theme),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.impersonationDialogSearchHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.formFieldRadius),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (_) => _onSearchChanged(),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${loc.impersonationDialogError}\n$_errorMsg',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.error),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: _users.isEmpty
                      ? Center(child: Text(loc.impersonationDialogNoUsersFound))
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final user = _users[idx];
                            final isSelected = user == _selectedUser;
                            return ListTile(
                              leading: Icon(
                                user.role == 'manager'
                                    ? Icons.manage_accounts
                                    : user.role == 'developer'
                                        ? Icons.code
                                        : Icons.account_circle,
                                color: colorScheme.outline,
                              ),
                              title: Text('${user.name} (${user.email})'),
                              subtitle: Text(user.role),
                              selected: isSelected,
                              selectedTileColor:
                                  colorScheme.primary.withOpacity(0.06),
                              onTap: () => setState(() => _selectedUser = user),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          },
                        ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: Text(loc.impersonationDialogButton),
                onPressed: _selectedUser != null
                    ? () => _onImpersonate(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.adminButtonRadius),
                  ),
                  textStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _ComingSoonCard(
                icon: Icons.shield,
                title: loc.impersonationDialogAuditTrailComingSoon,
                subtitle: loc.impersonationDialogAuditTrailDesc,
                colorScheme: colorScheme,
                theme: theme,
              ),
              _ComingSoonCard(
                icon: Icons.settings_suggest,
                title: loc.impersonationDialogAdvancedToolsComingSoon,
                subtitle: loc.impersonationDialogAdvancedToolsDesc,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SecurityNotice({
    required this.loc,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.errorContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.formFieldRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: colorScheme.error, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.impersonationDialogSecurityNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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

class ImpersonationUser {
  final String id;
  final String email;
  final String name;
  final String role;

  ImpersonationUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });
}
