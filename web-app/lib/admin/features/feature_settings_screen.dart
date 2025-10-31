import 'package:franchise_admin_portal/widgets/feature_toggle_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/models/user.dart'
    as admin_user;
import 'package:shared_core/src/core/services/audit_log_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:shared_core/src/core/providers/user_profile_notifier.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';

class FeatureSettingsScreen extends StatefulWidget {
  const FeatureSettingsScreen({super.key});

  @override
  State<FeatureSettingsScreen> createState() => _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends State<FeatureSettingsScreen> {
  bool _unauthorizedLogged = false;

  Future<void> _updateFeature(String key, bool value, admin_user.User user,
      Map<String, dynamic> meta) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localization missing! [debug]')),
      );
      return;
    }
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;

    if (!(user.isOwner || user.isAdmin || user.isDeveloper)) {
      await AuditLogService().addLog(
        franchiseId: franchiseId,
        userId: user.id,
        action: 'unauthorized_feature_toggle_attempt',
        targetType: 'feature_toggle',
        targetId: key,
        details: {
          'attemptedValue': value,
          'message': 'User with insufficient role tried to toggle feature.',
        },
      );
      await ErrorLogger.log(
        message: 'Unauthorized feature toggle attempt by ${user.email}',
        source: 'FeatureSettingsScreen',
        screen: 'FeatureSettingsScreen',
        severity: 'warning',
        contextData: {
          'roles': user.roles,
          'attemptedKey': key,
          'attemptedValue': value,
          'userId': user.id,
          'franchiseId': franchiseId,
        },
      );
      _showUnauthorizedDialog(loc);
      return;
    }

    if (meta['paid_service'] == true && !user.isDeveloper) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.paidFeatureAdminOnly)),
      );
      return;
    }

    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .updateFeatureToggle(franchiseId, key, value);
      await AuditLogService().addLog(
        franchiseId: franchiseId,
        userId: user.id,
        action: 'update_feature_toggle',
        targetType: 'feature_toggle',
        targetId: key,
        details: {'newValue': value},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.toggleUpdateFailed)),
      );
      rethrow;
    }
  }

  void _showUnauthorizedDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.unauthorizedTitle),
        content: Text(loc.unauthorizedFeatureChange),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId!;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final user = Provider.of<AdminUserProvider>(context, listen: false).user;

    // Not logged in
    if (user == null) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundColor,
        body: Row(
          children: [
            Expanded(
              flex: 11,
              child: Center(child: Text(loc.unauthorizedPleaseLogin)),
            ),
            Expanded(flex: 9, child: Container()),
          ],
        ),
      );
    }

    // Not allowed
    if (!(user.isOwner || user.isAdmin || user.isDeveloper)) {
      if (!_unauthorizedLogged) {
        _unauthorizedLogged = true;
        Future.microtask(() async {
          await AuditLogService().addLog(
            franchiseId: franchiseId,
            userId: user.id,
            action: 'unauthorized_feature_settings_access',
            targetType: 'feature_settings',
            targetId: '',
            details: {
              'message':
                  'User with insufficient role tried to access feature settings.',
            },
          );
          await ErrorLogger.log(
            message: 'Unauthorized feature settings access by ${user.email}',
            source: 'FeatureSettingsScreen',
            screen: 'FeatureSettingsScreen',
            severity: 'warning',
            contextData: {
              'roles': user.roles,
              'attempt': 'access',
              'userId': user.id,
              'franchiseId': franchiseId,
            },
          );
        });
      }
      return Scaffold(
        backgroundColor: DesignTokens.backgroundColor,
        body: Row(
          children: [
            Expanded(
              flex: 11,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 54, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      loc.unauthorizedNoPermission,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: Text(loc.returnToHome),
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 9, child: Container()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content column
          Expanded(
            flex: 11,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          loc.featureSettingsTitle,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Feature toggles with live updates and sections
                  Expanded(
                    child: FeatureToggleList(
                      franchiseId: franchiseId,
                      user: user,
                      onUpdateFeature: (key, value, user, meta) =>
                          _updateFeature(key, value, user, meta),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 9, child: Container()),
        ],
      ),
    );
  }
}


