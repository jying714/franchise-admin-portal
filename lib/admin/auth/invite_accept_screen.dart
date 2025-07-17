import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/profile/franchise_onboarding_screen.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'dart:html' as html;

class InviteAcceptScreen extends StatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  String? _token;
  Map<String, dynamic>? _inviteData;
  String? _error;
  bool _loading = false;
  bool _accepted = false;
  bool _isNewUser = false;
  final _pwController = TextEditingController();
  final _pw2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('==== InviteAcceptScreen INIT ====');
    print('Dart: Uri.base: ${Uri.base.toString()}');
    // Extra: Print window location in web
    print('JS: window.location.href: ${html.window.location.href}');
    print('JS: window.location.hash: ${html.window.location.hash}');
    _loadToken();
  }

  @override
  void dispose() {
    _pwController.dispose();
    _pw2Controller.dispose();
    super.dispose();
  }

  void _loadToken() {
    // Parse the token from the hash fragment if needed
    final hash = html.window.location.hash; // e.g. #/invite-accept?token=...
    print('[InviteAcceptScreen] window.location.hash: $hash');
    String? token;
    if (hash.isNotEmpty) {
      final uri = Uri.parse(hash.substring(1)); // Remove the leading #
      token = uri.queryParameters['token'];
    }
    print('[InviteAcceptScreen] Extracted token from hash: $token');
    setState(() {
      _token = token;
    });
    if (token != null && token.isNotEmpty) {
      _fetchInvite(token);
    } else {
      setState(() {
        _loading = false;
        _error = "No invitation token in the URL.";
      });
    }
  }

  Future<void> _fetchInvite(String token) async {
    setState(() {
      _loading = true;
      _error = null;
      _inviteData = null;
    });
    print('[InviteAcceptScreen] _fetchInvite: token=$token');
    try {
      final doc = await Provider.of<FirestoreService>(context, listen: false)
          .getFranchiseeInvitationByToken(token);
      print('[InviteAcceptScreen] Fetched doc: $doc');
      if (doc == null) {
        print('[InviteAcceptScreen] No invite found for token');
        setState(() => _error = "Invitation not found or expired."); // fallback
        return;
      }
      if (doc['status'] == 'revoked') {
        setState(() => _error = "Invitation was revoked.");
        return;
      }
      if (doc['status'] == 'accepted') {
        setState(() => _error = "Invitation already accepted.");
        return;
      }
      setState(() {
        _inviteData = doc;
        _isNewUser = doc['isNewUser'] == true;
      });
    } catch (e, st) {
      print('[InviteAcceptScreen] Exception: $e\n$st');
      await ErrorLogger.log(
        message: 'Invite fetch failed: $e',
        stack: st.toString(),
        source: 'InviteAcceptScreen',
        screen: 'invite_accept',
        severity: 'error',
        contextData: {'token': token},
      );
      setState(() {
        _error = "Failed to load invitation data.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptInvite() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loc = AppLocalizations.of(context)!;
    try {
      // Password validation if new user
      if (_isNewUser) {
        final pw = _pwController.text.trim();
        final pw2 = _pw2Controller.text.trim();
        if (pw.length < 8) {
          setState(() {
            _error = loc.passwordTooShort;
            _loading = false;
          });
          return;
        }
        if (pw != pw2) {
          setState(() {
            _error = loc.passwordsDoNotMatch;
            _loading = false;
          });
          return;
        }
        // Register user with Firebase Auth
        await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _inviteData!['email'],
          password: pw,
        );
      } else {
        // If not new user, user should sign in manually
        final user = fb_auth.FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _error = loc.signInRequiredToAcceptInvite;
            _loading = false;
          });
          return;
        }
        // (Optional: check user.email == _inviteData!['email'])
      }

      // Call cloud function to mark as accepted
      await FirestoreService().callAcceptInvitationFunction(_token!);

      Navigator.of(context).pushReplacementNamed(
        '/franchise-onboarding',
        arguments: {'token': _token},
      );
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Invite accept failed: $e',
        stack: st.toString(),
        source: 'InviteAcceptScreen',
        screen: 'invite_accept',
        severity: 'error',
        contextData: {'token': _token},
      );
      setState(() {
        _error = AppLocalizations.of(context)!.inviteAcceptFailed;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('==== InviteAcceptScreen BUILD ====');
    print('Dart: Uri.base: ${Uri.base.toString()}');
    print('JS: window.location.href: ${html.window.location.href}');
    print('JS: window.location.hash: ${html.window.location.hash}');

    final uri = Uri.base;
    final token = uri.queryParameters['token'];

    // If the token has changed or is not yet loaded, trigger loading.
    if (token != null && token.isNotEmpty && token != _token && !_loading) {
      print('[InviteAcceptScreen] Detected new token in build: $token');
      // This is safe because setState will trigger a rebuild, but since _loading will be true, it will not loop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadToken();
      });
    }

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(loc.acceptInvitation ?? "Accept Invitation"),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.94),
            borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.11),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _loading
              ? const LoadingShimmerWidget()
              : _accepted
                  ? _buildAccepted(loc, colorScheme)
                  : _buildInvitePanel(loc, colorScheme, theme),
        ),
      ),
    );
  }

  Widget _buildInvitePanel(
      AppLocalizations loc, ColorScheme colorScheme, ThemeData theme) {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: colorScheme.error, size: 36),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium!.copyWith(
                color: colorScheme.error, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_inviteData == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loc.loadingInvite ?? "Loading invitation..."),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_unread, color: colorScheme.primary, size: 40),
        const SizedBox(height: 16),
        Text(
          loc.inviteWelcome(_inviteData!['email']),
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        if (_inviteData!['franchiseName'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              loc.inviteForFranchise(_inviteData!['franchiseName']),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.secondary),
            ),
          ),
        const SizedBox(height: 18),
        if (_isNewUser) ...[
          Text(
            loc.inviteSetPassword,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pwController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: loc.password,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pw2Controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: loc.confirmPassword,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (!_isNewUser)
          Text(
            loc.inviteAcceptExisting,
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _acceptInvite,
          icon: const Icon(Icons.check_circle),
          label: Text(loc.acceptInvitation ?? "Accept Invitation"),
        ),
      ],
    );
  }

  Widget _buildAccepted(AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, color: colorScheme.primary, size: 44),
        const SizedBox(height: 14),
        Text(
          loc.inviteAcceptedTitle,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontSize: 20),
        ),
        const SizedBox(height: 7),
        Text(
          loc.inviteAcceptedDesc,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: Text(loc.goToDashboard ?? "Go to Dashboard"),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/dashboard', (route) => false);
          },
        ),
      ],
    );
  }
}
