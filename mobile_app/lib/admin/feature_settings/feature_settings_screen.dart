import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/config/feature_config.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/widgets/loading_shimmer_widget.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart';
import 'package:doughboys_pizzeria_final/core/services/audit_log_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeatureSettingsScreen extends StatefulWidget {
  const FeatureSettingsScreen({super.key});

  @override
  State<FeatureSettingsScreen> createState() => _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends State<FeatureSettingsScreen> {
  late Future<Map<String, bool>> _featureToggles;
  bool _unauthorizedLogged = false; // Prevent duplicate audit log entries

  @override
  void initState() {
    super.initState();
    _featureToggles = FeatureConfig.instance.load();
  }

  Future<void> _updateFeature(String key, bool value, User user) async {
    final loc = AppLocalizations.of(context)!;

    if (!user.isOwner) {
      await AuditLogService().addLog(
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
        .updateFeatureToggle(key, value);
    await AuditLogService().addLog(
      userId: user.id,
      action: 'update_feature_toggle',
      targetType: 'feature_toggle',
      targetId: key,
      details: {
        'newValue': value,
      },
    );
    setState(() {
      _featureToggles = FeatureConfig.instance.load();
    });
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
    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<User?>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.featureSettingsTitle),
          backgroundColor: DesignTokens.adminPrimaryColor,
        ),
        body: Center(child: Text(loc.unauthorizedPleaseLogin)),
      );
    }

    if (!user.isOwner) {
      if (!_unauthorizedLogged) {
        _unauthorizedLogged = true;
        Future.microtask(() {
          AuditLogService().addLog(
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
        appBar: AppBar(
          title: Text(loc.featureSettingsTitle),
          backgroundColor: DesignTokens.adminPrimaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                loc.unauthorizedNoPermission,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: Text(loc.returnToHome),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.featureSettingsTitle),
        backgroundColor: DesignTokens.adminPrimaryColor,
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: _featureToggles,
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
                onChanged: (val) => _updateFeature(key, val, user),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
