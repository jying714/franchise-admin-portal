import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/feature_config.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class FeatureSettingsScreen extends StatefulWidget {
  const FeatureSettingsScreen({super.key});

  @override
  State<FeatureSettingsScreen> createState() => _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends State<FeatureSettingsScreen> {
  bool _unauthorizedLogged = false; // Prevent duplicate audit log entries

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updateFeature(
      String key, bool value, admin_user.User user) async {
    final loc = AppLocalizations.of(context)!;
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;

    if (!user.isOwner) {
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
      _showUnauthorizedDialog(loc);
      return;
    }
    await Provider.of<FirestoreService>(context, listen: false)
        .updateFeatureToggle(franchiseId, key, value);
    await AuditLogService().addLog(
      franchiseId: franchiseId,
      userId: user.id,
      action: 'update_feature_toggle',
      targetType: 'feature_toggle',
      targetId: key,
      details: {
        'newValue': value,
      },
    );
    setState(() {});
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
    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<admin_user.User?>(context);

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
    if (!user.isOwner) {
      if (!_unauthorizedLogged) {
        _unauthorizedLogged = true;
        Future.microtask(() {
          AuditLogService().addLog(
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

    // Allowed (owner)
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
                  // Feature toggles
                  Expanded(
                    child: FutureBuilder<Map<String, bool>>(
                      future: FeatureConfig.instance.load(franchiseId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LoadingShimmerWidget();
                        }
                        final toggles = snapshot.data!;
                        if (toggles.isEmpty) {
                          return Center(child: Text(loc.noFeaturesFound));
                        }
                        return ListView(
                          children: toggles.keys.map((key) {
                            return SwitchListTile(
                              title: Text(loc.featureDisplayName(key)),
                              value: toggles[key] ?? false,
                              onChanged: (val) =>
                                  _updateFeature(key, val, user),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel placeholder
          Expanded(
            flex: 9,
            child: Container(),
          ),
        ],
      ),
    );
  }
}
