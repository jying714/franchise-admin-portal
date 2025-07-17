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
import 'package:franchise_admin_portal/core/services/auth_service.dart';

class InviteAcceptScreen extends StatefulWidget {
  final String? inviteToken;
  const InviteAcceptScreen({super.key, this.inviteToken});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  Map<String, dynamic>? _inviteData;
  String? _error;
  bool _loading = false;
  bool _accepted = false;
  bool _isNewUser = false;
  final _pwController = TextEditingController();
  final _pw2Controller = TextEditingController();
  String? _effectiveToken;
  bool _didLoadToken = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pwController.dispose();
    _pw2Controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadToken) return;
    _didLoadToken = true;

    // Priority: Constructor, then arguments, then hash
    _effectiveToken = widget.inviteToken;
    if (_effectiveToken == null) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _effectiveToken = args['token'] as String?;
    }
    // As a final fallback, parse from hash for deep linking support:
    if (_effectiveToken == null || _effectiveToken!.isEmpty) {
      final hash = html.window.location.hash;
      if (hash.isNotEmpty) {
        final hashPart = hash.substring(1); // Remove leading #
        final questionMarkIndex = hashPart.indexOf('?');
        if (questionMarkIndex != -1 &&
            questionMarkIndex < hashPart.length - 1) {
          final queryString = hashPart.substring(questionMarkIndex + 1);
          final params = Uri.splitQueryString(queryString);
          _effectiveToken = params['token'];
        }
      }
    }
    if (_effectiveToken != null && _effectiveToken!.isNotEmpty) {
      Provider.of<AuthService>(context, listen: false)
          .saveInviteToken(_effectiveToken!);
      _fetchInvite(_effectiveToken!);
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
    print(
        '[InviteAcceptScreen] _acceptInvite() called, _isNewUser=$_isNewUser, inviteData=$_inviteData');
    setState(() {
      _loading = true;
      _error = null;
    });
    final loc = AppLocalizations.of(context)!;
    try {
      final inviteEmail = (_inviteData?['email'] as String?) ?? '';
      if (inviteEmail.isEmpty) {
        setState(() {
          _error = "Invitation email missing. Cannot register.";
          _loading = false;
        });
        return;
      }

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

        try {
          // Attempt to register user with Firebase Auth
          await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: inviteEmail,
            password: pw,
          );
        } on fb_auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // This user already exists—prompt to sign in instead
            setState(() {
              _error =
                  "This email is already registered. Please sign in to accept your invitation.";
              _loading = false;
            });
            return;
          } else {
            setState(() {
              _error = e.message ?? "Unknown error during registration.";
              _loading = false;
            });
            return;
          }
        }
      } else {
        // Not a new user—try to sign in automatically if possible
        final user = fb_auth.FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _error =
                "This email is already registered. Please sign in to accept your invitation.";
            _loading = false;
          });
          return;
        }
        // (Optional: You could check here that user.email == inviteEmail, if desired)
      }

      // Call cloud function to mark as accepted
      await FirestoreService().callAcceptInvitationFunction(_effectiveToken!);

      Navigator.of(context).pushReplacementNamed(
        '/franchise-onboarding',
        arguments: {'token': _effectiveToken!},
      );
      print(
          '[InviteAcceptScreen] Navigating to /franchise-onboarding with token=$_effectiveToken');
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Invite accept failed: $e',
        stack: st.toString(),
        source: 'InviteAcceptScreen',
        screen: 'invite_accept',
        severity: 'error',
        contextData: {'token': _effectiveToken},
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
    print('==== InviteAcceptScreen BUILD (top) ====');
    print('Dart: Uri.base: ${Uri.base.toString()}');
    print('JS: window.location.href: ${html.window.location.href}');
    print('JS: window.location.hash: ${html.window.location.hash}');

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    print(
        '_loading: $_loading, _accepted: $_accepted, _inviteData: $_inviteData');

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
    print('=== _buildInvitePanel called ===');
    print('_inviteData: $_inviteData');
    print('_error: $_error');
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: colorScheme.error, size: 36),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: colorScheme.error, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_inviteData == null) {
      print("DEBUG: _inviteData is null in _buildInvitePanel");
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loc.loadingInvite ?? "Loading invitation..."),
        ],
      );
    }

    // Null-safe extract fields (always provide a default)
    // Null-safe extract fields (always provide a default)
    final inviteEmailRaw = _inviteData?['email'];
    final inviteEmail = (inviteEmailRaw is String && inviteEmailRaw.isNotEmpty)
        ? inviteEmailRaw
        : 'Unknown';
    final inviteFranchiseName =
        (_inviteData?['franchiseName'] as String?) ?? '';
    final inviteStatus = (_inviteData?['status'] as String?) ?? 'unknown';

// Centralized invite account logic
    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    print('currentUser: $currentUser');
    final inviteUidRaw = _inviteData?['invitedUserId'];
    print('inviteUidRaw: $inviteUidRaw');
    final inviteUid = (inviteUidRaw is String && inviteUidRaw.isNotEmpty)
        ? inviteUidRaw
        : null;
    print('inviteUid: $inviteUid');
    final inviteEmailLower = inviteEmail.toLowerCase();
    final userEmailLower = (currentUser?.email ?? '').toLowerCase();
    final isLoggedIn = currentUser != null;
    print('isLoggedIn: $isLoggedIn');
    final isUidMatch = isLoggedIn &&
        inviteUid != null &&
        currentUser != null &&
        currentUser.uid == inviteUid;

    final isEmailMatch = isLoggedIn && userEmailLower == inviteEmailLower;
    print('inviteEmail: $inviteEmail');
    print('inviteUid: $inviteUid');
    print('currentUser: $currentUser');
    print('currentUser.uid: ${currentUser?.uid}');
    print('isLoggedIn: $isLoggedIn');
    print('isUidMatch: $isUidMatch');
    print('isEmailMatch: $isEmailMatch');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_unread, color: colorScheme.primary, size: 40),
        const SizedBox(height: 16),
        Text(
          loc.inviteWelcome(inviteEmail),
          style: (theme.textTheme.titleLarge ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        if (inviteFranchiseName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              loc.inviteForFranchise(inviteFranchiseName),
              style: (theme.textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: colorScheme.secondary),
            ),
          ),
        const SizedBox(height: 18),
        if (_isNewUser) ...[
          Text(
            loc.inviteSetPassword,
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
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
          Builder(
            builder: (context) {
              // Case 1: Signed in and correct UID (invited user)
              if (isLoggedIn && isUidMatch) {
                return Text(
                  "You are signed in with the invited account. Click accept to continue.",
                  style: theme.textTheme.bodyMedium ?? const TextStyle(),
                  textAlign: TextAlign.center,
                );
              }
              // Case 2: Signed in, correct email, but UID mismatch (edge case: merged Google/social login, etc.)
              if (isLoggedIn && isEmailMatch && !isUidMatch) {
                return Column(
                  children: [
                    Text(
                      "You are signed in with the correct email, but not the invited account. If this is intentional, contact support.",
                      style: theme.textTheme.bodyMedium ?? const TextStyle(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Switch Account"),
                      onPressed: () async {
                        await fb_auth.FirebaseAuth.instance.signOut();
                        Provider.of<AuthService>(context, listen: false)
                            .saveInviteToken(_effectiveToken ?? '');
                        Navigator.of(context).pushNamed(
                          '/sign-in',
                          arguments: {'token': _effectiveToken},
                        );
                      },
                    ),
                  ],
                );
              }
              // Case 3: Not signed in
              return Column(
                children: [
                  Text(
                    "It looks like your email is already registered. Please sign in to accept this invitation and continue onboarding.",
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Sign In"),
                    onPressed: () {
                      Provider.of<AuthService>(context, listen: false)
                          .saveInviteToken(_effectiveToken ?? '');
                      Navigator.of(context).pushNamed(
                        '/sign-in',
                        arguments: {'token': _effectiveToken},
                      );
                    },
                  ),
                ],
              );
            },
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
