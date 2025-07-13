// File: lib/widgets/profile_gate_screen.dart
import 'dart:async';
import 'dart:html' as html; // Web reload
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import '../core/services/firestore_service.dart';
import '../core/providers/admin_user_provider.dart';
import '../widgets/user_profile_notifier.dart';
import '../config/design_tokens.dart';
import '../config/branding_config.dart';

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
  AppLocalizations get loc => AppLocalizations.of(context)!;
  ThemeData get theme => Theme.of(context);
  ColorScheme get colorScheme => theme.colorScheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print(
          '[ProfileGateScreen] initState: Triggering UserProfileNotifier.reload()');
      _profileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // Defensive: Always start user profile stream if Firebase user exists and not yet started
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null && _profileNotifier.user == null) {
        _profileNotifier.listenToUser(_firestoreService, fbUser.uid);
      } else {
        _profileNotifier.reload();
      }
      _startTimeout();
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
      await _firestoreService.logError(
        'unknown',
        message: message,
        source: 'profile_gate_screen',
        stackTrace: stack?.toString(),
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
  Future<void> _navigateToDashboard(admin_user.User user) async {
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
      _showErrorSnack(loc.noValidRoleFound);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
    );
  }

  Future<void> _forceClaimsAndReload() async {
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
      _showErrorSnack(loc.claimsRefreshFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UserProfileNotifier>(context);
    final user = notifier.user;
    final error = notifier.lastError;
    final isLoading = notifier.loading && !_timedOut;
    print(
        '[ProfileGateScreen] build: user=${user?.email}, roles=${user?.roles}, isActive=${user?.isActive}, error=$error, loading=$isLoading, timedOut=$_timedOut');

    // === HQ OWNER/MANAGER REDIRECT ===
    final hqRoles = ['hq_owner', 'hq_manager'];
    if (user != null && user.roles.any((r) => hqRoles.contains(r))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/hq-owner/dashboard') {
          Navigator.of(context).pushReplacementNamed('/hq-owner/dashboard');
        }
      });
      // While redirecting, show a loading/redirecting message.
      return _loadingScreen(
          loc.redirectingToOwnerHQDashboard ?? "Redirecting to HQ Dashboard...",
          showSpinner: true);
    }

    // 1. Timeout error UI
    if (_timedOut && user == null) {
      print('[ProfileGateScreen] State: Timed out, user is null.');
      return _errorScreen(
        msg: loc.profileLoadTimeout,
        details: loc.tryAgainOrContactSupport,
        onRetry: _retry,
        icon: Icons.timer_off,
      );
    }

    // 2. Explicit error UI
    if (error != null) {
      print('[ProfileGateScreen] State: Error detected - $error');
      return _errorScreen(
        msg: loc.profileLoadFailed,
        details: error.toString(),
        onRetry: _retry,
        icon: Icons.error_outline,
      );
    }

    // 3. If profile loaded, but claims/roles missing
    if (user != null && (user.roles == null || user.roles!.isEmpty)) {
      print(
          '[ProfileGateScreen] Profile loaded, roles is null or empty! User: ${user.email}, roles: ${user.roles}, status: ${user.status}');
      // Attempt to force claims refresh (once), then reload page
      if (!_claimsRefreshed) {
        setState(() => _claimsRefreshed = true);
        _forceClaimsAndReload();
      }
      return _loadingScreen(loc.syncingRolesPleaseWait, showSpinner: true);
    }

    // 4. Profile loaded, roles present, developer-only guard
    if (user != null && user.roles != null && user.roles!.isNotEmpty) {
      print(
          '[ProfileGateScreen] Profile loaded and roles present. roles=${user.roles}, user.status=${user.status}');
      // If dev, show extra info/tools
      if (user.roles!.contains('developer')) {
        return _dashboardSection(
          context,
          child: _devSection(user, notifier),
          info: loc.redirectingToDeveloperDashboard,
        );
      }
      // For non-dev, just modular dashboard logic
      _navigateToDashboard(user);
      return _dashboardSection(
        context,
        info: loc.redirecting,
      );
    }

    // 5. Default: show loading with branding
    return _loadingScreen(loc.loadingProfileAndPermissions, showSpinner: true);
  }

  // === Dashboard Section Modular ===
  Widget _dashboardSection(BuildContext context,
      {Widget? child, String? info}) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.adminCardRadius),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              elevation: DesignTokens.adminCardElevation,
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (BrandingConfig.logoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Image.network(
                          BrandingConfig.logoUrl,
                          height: 68,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (info != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          info,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (child != null) child,
                    // === Placeholder for future features ===
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: _futureFeatureSection(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === Developer-Only Section ===
  Widget _devSection(admin_user.User user, UserProfileNotifier notifier) {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Icon(Icons.terminal, size: 42, color: colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          loc.developerMode,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(loc.devPanelDesc, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        // Debug info
        if (fbUser != null)
          SelectableText('Firebase UID: ${fbUser.uid}',
              style: theme.textTheme.bodySmall),
        SelectableText('Profile roles: ${user.roles?.join(", ")}',
            style: theme.textTheme.bodySmall),
        SelectableText('Active: ${user.status == 'active'}',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          icon: const Icon(Icons.sync),
          label: Text(loc.forceClaimsRefresh),
          onPressed: _forceClaimsAndReload,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(loc.signOut),
          onPressed: () async {
            await fb_auth.FirebaseAuth.instance.signOut();
            if (kIsWeb) html.window.location.reload();
          },
        ),
        const SizedBox(height: 18),
        if (_retrying) const CircularProgressIndicator(),
      ],
    );
  }

  // === Loading State UI ===
  Widget _loadingScreen(String msg, {bool showSpinner = false}) {
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
