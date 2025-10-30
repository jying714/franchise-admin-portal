// File: lib/widgets/profile_gate_screen.dart
import 'dart:async';
import 'dart:html' as html; // Web reload
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/models/user.dart' as admin_user;
import '../core/services/firestore_service.dart';
import '../core/providers/admin_user_provider.dart';
import '../core/providers/user_profile_notifier.dart';
import '../config/design_tokens.dart';
import '../config/branding_config.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class ProfileGateScreen extends StatefulWidget {
  const ProfileGateScreen({Key? key}) : super(key: key);

  @override
  State<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends State<ProfileGateScreen> {
  Timer? _timer;
  bool _timedOut = false;
  bool _claimsRefreshed = false;
  bool _retrying = false;
  static const _timeoutSeconds = 10;
  late FirestoreService _firestoreService;
  late UserProfileNotifier _profileNotifier;
  admin_user.User? _lastSetUser;

  String? _getInviteToken() {
    // If you save the invite token in localStorage after invite-accept
    try {
      return html.window.localStorage['invite_token'];
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _profileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;

      print('[ProfileGateScreen] initState START');
      print('[ProfileGateScreen] Firebase user: $fbUser');
      print('[ProfileGateScreen] Current profile: ${_profileNotifier.user}');
      print('[ProfileGateScreen] Is loading: ${_profileNotifier.loading}');

      // Defensive: Avoid triggering reload if already loading or loaded
      if (fbUser != null) {
        if (_profileNotifier.user == null && !_profileNotifier.loading) {
          print(
              '[ProfileGateScreen] ⏳ No user loaded, starting listenToUser...');
          _profileNotifier.listenToUser(_firestoreService, fbUser.uid);
          _startTimeout();
        } else if (_profileNotifier.user != null) {
          print(
              '[ProfileGateScreen] ✅ User already loaded. No need to reload.');
        } else if (_profileNotifier.loading) {
          print('[ProfileGateScreen] ⏳ Already loading. No action taken.');
        }
      } else {
        print(
            '[ProfileGateScreen] ⚠️ Firebase user is null. Cannot load profile.');
      }
    });
  }

  void _startTimeout() {
    _timer?.cancel();
    print(
        '[ProfileGateScreen] Starting profile load timeout ($_timeoutSeconds seconds)');
    _timer = Timer(Duration(seconds: _timeoutSeconds), () async {
      setState(() => _timedOut = true);
      print(
          '[ProfileGateScreen] Profile load timed out after $_timeoutSeconds seconds');
      await _logError('Profile load timed out after $_timeoutSeconds seconds');
    });
  }

  Future<void> _logError(String message,
      {Object? error, StackTrace? stack}) async {
    try {
      await ErrorLogger.log(
        message: message,
        source: 'profile_gate_screen',
        stack: stack?.toString(),
        severity: 'error',
        screen: 'ProfileGateScreen',
        contextData: {
          if (error != null) 'error': error.toString(),
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    print('[ProfileGateScreen] Retry pressed. Restarting load and timeout.');
    setState(() {
      _timedOut = false;
      _claimsRefreshed = false;
      _retrying = true;
    });
    _profileNotifier.reload();
    _startTimeout();
    setState(() {
      _retrying = false;
    });
  }

  // Modular dashboard section handler
  Future<void> _navigateToDashboard(
      admin_user.User user, AppLocalizations loc) async {
    print(
        '[ProfileGateScreen] Navigating with user: ${user.email} -> ${user.roles}');
    final roles = user.roles ?? <String>[];
    print(
        '[ProfileGateScreen] _navigateToDashboard: roles=$roles, status=${user.status}');
    if (user.status != 'active') {
      print(
          '[ProfileGateScreen] Navigating to /unauthorized (status: ${user.status})');
      Navigator.of(context).pushReplacementNamed('/unauthorized');
      return;
    }
    // HQ roles are handled in build(), so no need to check here!
    if (roles.contains(admin_user.User.roleDeveloper)) {
      print('[ProfileGateScreen] Navigating to /developer/dashboard');
      Navigator.of(context).pushReplacementNamed('/developer/dashboard');
    } else if (roles.contains(admin_user.User.roleOwner) ||
        roles.contains(admin_user.User.roleManager)) {
      print('[ProfileGateScreen] Navigating to /admin/dashboard');
      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
    } else {
      print('[ProfileGateScreen] No recognized role. roles=$roles');
      await _logError('User has no recognized role', error: roles);
      _showErrorSnack(loc.noValidRoleFound, Theme.of(context));
    }
  }

  void _showErrorSnack(String msg, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: theme.colorScheme.error),
    );
  }

  Future<void> _forceClaimsAndReload(AppLocalizations loc) async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force refresh
      }
      if (kIsWeb) {
        html.window.location.reload();
      }
    } catch (e, stack) {
      await _logError('Failed to refresh claims/token', error: e, stack: stack);
      _showErrorSnack(loc.claimsRefreshFailed, Theme.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loc == null) {
      return _loadingScreen("Loading localization...", theme, colorScheme,
          showSpinner: true);
    }

    final notifier = Provider.of<UserProfileNotifier>(context);
    final user = notifier.user;
    final error = notifier.lastError;
    final isLoading = notifier.loading && !_timedOut;

    print('[ProfileGateScreen] DEBUG TRACE: user=${user?.toString()}');
    print('[ProfileGateScreen] User profile loaded: '
        'email=${user?.email}, '
        'isActive=${user?.isActive}, '
        'roles=${user?.roles}, '
        'franchiseIds=${user?.franchiseIds}, '
        'defaultFranchise=${user?.defaultFranchise}');

    // === Onboarding: Detect incomplete profile ===
    if (user != null &&
        (user.completeProfile == null || user.completeProfile == false)) {
      print(
          '[ProfileGateScreen] User profile incomplete, redirecting to onboarding.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(
          '/franchise-onboarding',
          arguments: {'token': _getInviteToken()},
        );
      });
      return _loadingScreen(
          "Redirecting to franchise onboarding...", theme, colorScheme,
          showSpinner: true);
    }

    // === Defensive Fix: Wait for roles if user is active but claims not yet applied ===
    final roles = user?.roles ?? [];
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isAlreadyAtDashboard = [
      '/admin/dashboard',
      '/platform-owner/dashboard',
      '/hq-owner/dashboard',
      '/developer/dashboard',
    ].any((r) => currentRoute.startsWith(r));

    print('[ProfileGateScreen] Current route: $currentRoute');
    print('[ProfileGateScreen] isAlreadyAtDashboard: $isAlreadyAtDashboard');
    final hasRoles = roles.isNotEmpty;

    if (user != null && user.status == 'active') {
      if (!hasRoles) {
        print(
            '[ProfileGateScreen] ⚠️ User is active, but roles are missing. Will wait for claim sync.');
        if (!_claimsRefreshed) {
          setState(() => _claimsRefreshed = true);
          _forceClaimsAndReload(loc);
        }
        return _loadingScreen(loc.syncingRolesPleaseWait, theme, colorScheme,
            showSpinner: true);
      }

      if (_lastSetUser != user) {
        _lastSetUser = user;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<AdminUserProvider>(context, listen: false).user = user;
        });
      }

      print(
          '[ProfileGateScreen] User loaded: email=${user.email}, roles=$roles, isActive=${user.isActive}');

      if (roles.contains('platform_owner')) {
        final route = ModalRoute.of(context)?.settings.name;
        final isOnCorrectDashboard =
            route != null && route.startsWith('/platform-owner/dashboard');

        print('[ProfileGateScreen] Detected platform_owner. '
            'currentRoute=$route, isOnCorrectDashboard=$isOnCorrectDashboard');

        if (!isOnCorrectDashboard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushReplacementNamed('/platform-owner/dashboard');
          });
          return _loadingScreen(
              loc.redirectingToPlatformOwnerDashboard ?? "Redirecting...",
              theme,
              colorScheme,
              showSpinner: true);
        }
      } else if (roles.contains('hq_owner') || roles.contains('hq_manager')) {
        print(
            '[ProfileGateScreen] Detected hq_owner/hq_manager role, routing to /hq-owner/dashboard');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/hq-owner/dashboard');
        });
        return _loadingScreen(
            loc.redirectingToOwnerHQDashboard ??
                "Redirecting to HQ Dashboard...",
            theme,
            colorScheme,
            showSpinner: true);
      } else if (roles.contains('developer')) {
        print(
            '[ProfileGateScreen] === Developer detected, redirecting to /developer/dashboard ===');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/developer/dashboard');
        });
        return _loadingScreen(
            loc.redirectingToDeveloperDashboard ??
                "Redirecting to Developer Dashboard...",
            theme,
            colorScheme,
            showSpinner: true);
      } else if (roles.contains('owner') || roles.contains('manager')) {
        final franchiseIds = user.franchiseIds ?? [];
        print('[ProfileGateScreen] OWNER/MANAGER: franchiseIds=$franchiseIds');

        if (franchiseIds.length > 1) {
          print(
              '[ProfileGateScreen] Franchise selection required, showing FranchiseSelectorScreen. '
              'franchiseIds=$franchiseIds, '
              'selectedFranchiseId=${Provider.of<FranchiseProvider>(context, listen: false).franchiseId}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushReplacementNamed('/developer/select-franchise');
          });
          return _loadingScreen(
              loc.selectFranchiseToManage ?? "Select a franchise to manage...",
              theme,
              colorScheme,
              showSpinner: true);
        } else if (franchiseIds.length == 1) {
          print(
              '[ProfileGateScreen] Admin/manager role detected, routing to AdminDashboardScreen. '
              'selectedFranchiseId=${Provider.of<FranchiseProvider>(context, listen: false).franchiseId}');
          Provider.of<FranchiseProvider>(context, listen: false)
              .setFranchiseId(franchiseIds.first);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/admin/dashboard');
          });
          return _loadingScreen(
              loc.redirecting ?? "Redirecting...", theme, colorScheme,
              showSpinner: true);
        } else {
          print('[ProfileGateScreen] No franchises found for owner/manager');
          _showErrorSnack("No franchises found in your profile.", theme);
          return _errorScreen(
            msg: "No franchises found in your profile.",
            details: "",
            onRetry: _retry,
            theme: theme,
            colorScheme: colorScheme,
            loc: loc,
            icon: Icons.error_outline,
          );
        }
      } else {
        print('[ProfileGateScreen] No valid role found, showing error');
        _showErrorSnack(loc.noValidRoleFound, theme);
        return _errorScreen(
          msg: loc.noValidRoleFound,
          details: "",
          onRetry: _retry,
          theme: theme,
          colorScheme: colorScheme,
          loc: loc,
          icon: Icons.error_outline,
        );
      }
    }

    if (_timedOut && user == null) {
      print('[ProfileGateScreen] State: Timed out, user is null.');
      return _errorScreen(
        msg: loc.profileLoadTimeout,
        details: loc.tryAgainOrContactSupport,
        onRetry: _retry,
        theme: theme,
        colorScheme: colorScheme,
        loc: loc,
        icon: Icons.timer_off,
      );
    }

    if (error != null) {
      print('[ProfileGateScreen] State: Error detected - $error');
      return _errorScreen(
        msg: loc.profileLoadFailed,
        details: error.toString(),
        onRetry: _retry,
        theme: theme,
        colorScheme: colorScheme,
        loc: loc,
        icon: Icons.error_outline,
      );
    }

    if (user != null && (user.roles == null || user.roles!.isEmpty)) {
      print('[ProfileGateScreen] Profile loaded, roles is null or empty! '
          'User: ${user.email}, roles: ${user.roles}, status: ${user.status}');
      if (!_claimsRefreshed) {
        setState(() => _claimsRefreshed = true);
        _forceClaimsAndReload(loc);
      }
      return _loadingScreen(loc.syncingRolesPleaseWait, theme, colorScheme,
          showSpinner: true);
    }

    print('[ProfileGateScreen] Default: show loading with branding');
    return _loadingScreen(loc.loadingProfileAndPermissions, theme, colorScheme,
        showSpinner: true);
  }

  // === Loading State UI ===
  Widget _loadingScreen(String msg, ThemeData theme, ColorScheme colorScheme,
      {bool showSpinner = false}) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (BrandingConfig.logoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Image.network(
                  BrandingConfig.logoUrl,
                  height: 78,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    BrandingConfig.logoMain,
                    height: 78,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (showSpinner) const CircularProgressIndicator(),
            if (showSpinner) const SizedBox(height: 24),
            Text(
              msg,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // === Error State UI ===
  Widget _errorScreen({
    required String msg,
    required String details,
    required VoidCallback onRetry,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppLocalizations loc,
    IconData? icon,
  }) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            elevation: DesignTokens.adminCardElevation,
            color: colorScheme.errorContainer.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon ?? Icons.error_outline,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: 24),
                  Text(msg,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: colorScheme.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(details,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.tryAgain),
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

  // === Future Feature Placeholder Section ===
  Widget _futureFeatureSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        Icon(Icons.lightbulb_outline, color: colorScheme.secondary, size: 26),
        const SizedBox(height: 8),
        Text(
          loc.futureFeaturesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(loc.futureFeaturesBody,
            style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
