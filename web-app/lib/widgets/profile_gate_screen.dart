import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

// Web-only conditional import for html
import 'dart:html' as html if (dart.library.html) 'dart:html';

import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart'; // Concrete impl
import '../config/design_tokens.dart';
import '../config/branding_config.dart';
import '../config/ui_config.dart';

class ProfileGateScreen extends StatefulWidget {
  const ProfileGateScreen({super.key});

  @override
  State<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends State<ProfileGateScreen> {
  Timer? _timer;
  bool _timedOut = false;
  bool _claimsRefreshed = false;
  bool _retrying = false;
  static const _timeoutSeconds = 10;

  late UserProfileNotifier _profileNotifier;
  late shared.AdminUserProvider _adminUserProvider;

  String? _getInviteToken() {
    if (!kIsWeb) return null;
    try {
      return html.window.localStorage['invite_token'];
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _profileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      _adminUserProvider =
          Provider.of<shared.AdminUserProvider>(context, listen: false);

      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;

      if (fbUser != null &&
          _profileNotifier.user == null &&
          !_profileNotifier.loading) {
        _profileNotifier.listenToUser(fbUser.uid);
        _startTimeout();
      }
    });
  }

  void _startTimeout() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      if (mounted) {
        setState(() => _timedOut = true);
        shared.ErrorLogger.log(
          message: 'Profile load timed out after $_timeoutSeconds seconds',
          source: 'ProfileGateScreen',
          severity: 'warning',
        );
      }
    });
  }

  Future<void> _logError(String message,
      {Object? error, StackTrace? stack}) async {
    shared.ErrorLogger.log(
      message: message,
      source: 'ProfileGateScreen',
      stack: stack?.toString(),
      severity: 'error',
      contextData: {if (error != null) 'error': error.toString()},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _timedOut = false;
      _claimsRefreshed = false;
      _retrying = true;
    });

    _profileNotifier.reload();
    _startTimeout();

    setState(() => _retrying = false);
  }

  Future<void> _forceClaimsAndReload(AppLocalizations loc) async {
    if (!mounted) return;
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
      }
      if (kIsWeb) {
        html.window.location.reload();
      }
    } catch (e, stack) {
      await _logError('Failed to refresh claims/token', error: e, stack: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(loc.claimsRefreshFailed ?? 'Failed to sync permissions'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final notifier = Provider.of<UserProfileNotifier>(context);
    final user = notifier.user;
    final error = notifier.lastError;
    final isLoading = notifier.loading && !_timedOut;

    // Onboarding redirect
    if (user != null &&
        (user.completeProfile == null || user.completeProfile == false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/franchise-onboarding',
            arguments: {'token': _getInviteToken()},
          );
        }
      });
      return _loadingScreen(
          "Redirecting to franchise onboarding...", theme, colorScheme);
    }

    final roles = user?.roles ?? [];
    final hasRoles = roles.isNotEmpty;

    if (user != null && user.status == 'active') {
      if (!hasRoles) {
        if (!_claimsRefreshed) {
          _claimsRefreshed = true;
          _forceClaimsAndReload(loc);
        }
        return _loadingScreen(
            loc.syncingRolesPleaseWait ?? "Syncing permissions...",
            theme,
            colorScheme);
      }

      // Sync to AdminUserProvider
      if (_adminUserProvider.user != user) {
        _adminUserProvider.user = user;
      }

      // Role routing
      if (roles.contains(shared.User.rolePlatformOwner)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            Navigator.of(context)
                .pushReplacementNamed('/platform-owner/dashboard');
        });
        return _loadingScreen(
            "Redirecting to Platform Owner Dashboard...", theme, colorScheme);
      } else if (roles.contains(shared.User.roleHqOwner) ||
          roles.contains(shared.User.roleHqManager)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            Navigator.of(context).pushReplacementNamed('/hq-owner/dashboard');
        });
        return _loadingScreen(
            "Redirecting to HQ Dashboard...", theme, colorScheme);
      } else if (roles.contains(shared.User.roleDeveloper)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            Navigator.of(context).pushReplacementNamed('/developer/dashboard');
        });
        return _loadingScreen(
            "Redirecting to Developer Dashboard...", theme, colorScheme);
      } else if (roles.contains(shared.User.roleOwner) ||
          roles.contains(shared.User.roleManager)) {
        final franchiseIds = user.franchiseIds ?? [];
        if (franchiseIds.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              Navigator.of(context).pushReplacementNamed('/franchise-selector');
          });
          return _loadingScreen(
              "Select a franchise to manage...", theme, colorScheme);
        } else if (franchiseIds.isNotEmpty) {
          Provider.of<shared.FranchiseProvider>(context, listen: false)
              .setFranchiseId(franchiseIds.first);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              Navigator.of(context).pushReplacementNamed('/admin/dashboard');
          });
          return _loadingScreen("Redirecting...", theme, colorScheme);
        }
      }
    }

    if (_timedOut && user == null) {
      return _errorScreen(
        msg: loc.profileLoadTimeout ?? "Profile load timed out",
        details: loc.tryAgainOrContactSupport ??
            "Please try again or contact support.",
        onRetry: _retry,
        theme: theme,
        colorScheme: colorScheme,
        loc: loc,
      );
    }

    if (error != null) {
      return _errorScreen(
        msg: loc.profileLoadFailed ?? "Failed to load profile",
        details: error.toString(),
        onRetry: _retry,
        theme: theme,
        colorScheme: colorScheme,
        loc: loc,
      );
    }

    return _loadingScreen(
        loc.loadingProfileAndPermissions ??
            "Loading profile and permissions...",
        theme,
        colorScheme);
  }

  Widget _loadingScreen(String msg, ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (BrandingConfig.logoUrl?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Image.network(
                  BrandingConfig.logoUrl!,
                  height: 78,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Image.asset(BrandingConfig.logoMain, height: 78),
                ),
              ),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(msg, style: UiConfig.titleStyle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _errorScreen({
    required String msg,
    required String details,
    required VoidCallback onRetry,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppLocalizations loc,
  }) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.adminCardRadius)),
            margin: const EdgeInsets.all(16),
            elevation: DesignTokens.adminCardElevation,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 24),
                  Text(msg,
                      style: UiConfig.titleStyle
                          .copyWith(color: colorScheme.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(details,
                      style: UiConfig.bodyStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.tryAgain ?? "Try Again"),
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
