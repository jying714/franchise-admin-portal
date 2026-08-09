import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/profile/franchise_onboarding_screen.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _effectiveToken;
  bool _didLoadToken = false;
  bool _emailRegistered = false;

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
      _fetchInvite(_effectiveToken!);
    } else {
      setState(() {
        _loading = false;
        _error = "No invitation token in the URL.";
      });
    }
  }

  Future<void> _acceptPortalStaffInvite({
    required String token,
    required fb_auth.User currentUser,
    required String inviteEmail,
  }) async {
    final authEmail = (currentUser.email ?? '').trim().toLowerCase();
    final expected = inviteEmail.trim().toLowerCase();
    if (authEmail.isEmpty || authEmail != expected) {
      throw StateError(
        'Sign in with the invited email ($expected) to accept.',
      );
    }

    final data = _inviteData ?? const <String, dynamic>{};
    final franchiseId = (data['franchiseId'] as String?)?.trim() ?? '';
    if (franchiseId.isEmpty) {
      throw StateError('Invitation is missing franchiseId.');
    }

    final role = (data['role'] as String?)?.trim();
    final rolesRaw = data['roles'];
    final roles = <String>[];
    if (rolesRaw is List) {
      for (final r in rolesRaw) {
        final s = r.toString().trim();
        if (s.isNotEmpty) roles.add(s);
      }
    }
    if (role != null && role.isNotEmpty && !roles.contains(role)) {
      roles.add(role);
    }
    if (roles.isEmpty) {
      roles.add('manager');
    }

    final displayName = (data['name'] as String?)?.trim() ?? '';
    final uid = currentUser.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final inviteRef = FirebaseFirestore.instance
        .collection('franchisee_invitations')
        .doc(token);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) {
        throw StateError('Invitation not found.');
      }
      final inv = inviteSnap.data() ?? {};
      final status = (inv['status'] as String?)?.trim() ?? '';
      if (status == 'accepted') {
        return;
      }
      if (status == 'revoked' || status == 'expired') {
        throw StateError('Invitation is $status.');
      }

      tx.set(
        userRef,
        {
          'id': uid,
          'email': expected,
          if (displayName.isNotEmpty) 'name': displayName,
          // arrayUnion so existing "customer" is kept and "manager" is added
          'roles': FieldValue.arrayUnion(roles),
          'franchiseIds': FieldValue.arrayUnion([franchiseId]),
          'defaultFranchise': franchiseId,
          'isActive': true,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        inviteRef,
        {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'acceptedByUserId': uid,
          'invitedUserId': uid,
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _fetchInvite(String token) async {
    setState(() {
      _loading = true;
      _error = null;
      _inviteData = null;
    });
    try {
      final doc =
          await Provider.of<shared.FirestoreService>(context, listen: false)
              .getFranchiseeInvitationByToken(token);
      if (doc == null) {
        setState(() => _error = "Invitation not found or expired.");
        return;
      }
      if (doc['status'] == 'revoked') {
        setState(() => _error = "Invitation was revoked.");
        return;
      }
      if (doc['status'] == 'accepted') {
        final current = fb_auth.FirebaseAuth.instance.currentUser;
        final inviteEmail =
            ((doc['email'] as String?) ?? '').trim().toLowerCase();
        final authEmail = (current?.email ?? '').trim().toLowerCase();
        final acceptedBy = (doc['acceptedByUserId'] as String?)?.trim();
        final isInvitee = current != null &&
            ((authEmail.isNotEmpty && authEmail == inviteEmail) ||
                (acceptedBy != null && acceptedBy == current.uid));

        if (isInvitee) {
          if (!mounted) return;
          await _exitInviteToApp();
          return;
        }

        setState(() => _error = "Invitation already accepted.");
        return;
      }
      await Provider.of<shared.AuthService>(context, listen: false)
          .saveInviteToken(token);
      if (!mounted) return;
      setState(() {
        _inviteData = doc;
      });
      final inviteEmail = (doc['email'] as String?) ?? '';
      bool emailRegistered = false;
      if (inviteEmail.isNotEmpty) {
        try {
          final methods = await fb_auth.FirebaseAuth.instance
              .fetchSignInMethodsForEmail(inviteEmail);
          emailRegistered = methods.isNotEmpty;
        } catch (e) {
          // Optionally, log error but do not block UI
        }
      }
      setState(() {
        _emailRegistered = emailRegistered;
      });
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Invite fetch failed: $e',
        stack: st.toString(),
        source: 'InviteAcceptScreen',
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
    final loc = AppLocalizations.of(context);
    try {
      final inviteEmail = (_inviteData?['email'] as String?) ?? '';
      if (inviteEmail.isEmpty) {
        setState(() {
          _error = "Invitation email missing. Cannot continue.";
          _loading = false;
        });
        return;
      }
      // Must be logged in as correct user/uid
      final fb_auth.User? currentUser =
          fb_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = loc?.inviteMustSignIn ??
              "Please sign in with your invited email.";
          _loading = false;
        });
        return;
      }
      final inviteUid = _inviteData?['invitedUserId'];
      if (inviteUid != null && currentUser.uid != inviteUid) {
        setState(() {
          _error =
              "Signed-in account does not match the invite. Please sign in with the correct email.";
          _loading = false;
        });
        return;
      }

      final inviteType = (_inviteData?['inviteType'] as String?)?.trim() ?? '';
      final isPortalStaff = inviteType == 'portal_staff';

      if (isPortalStaff) {
        await _acceptPortalStaffInvite(
          token: _effectiveToken!,
          currentUser: currentUser,
          inviteEmail: inviteEmail,
        );
        if (!mounted) return;

        // Best-effort custom claims so JWT matches users/{uid}.
        // Firestore bind already succeeded; do not block exit on CF failure.
        try {
          final data = _inviteData ?? const <String, dynamic>{};
          final franchiseId = (data['franchiseId'] as String?)?.trim() ?? '';
          final role = (data['role'] as String?)?.trim();
          final rolesRaw = data['roles'];
          final roles = <String>[];
          if (rolesRaw is List) {
            for (final r in rolesRaw) {
              final s = r.toString().trim();
              if (s.isNotEmpty) roles.add(s);
            }
          }
          if (role != null && role.isNotEmpty && !roles.contains(role)) {
            roles.add(role);
          }
          if (roles.isEmpty) {
            roles.add('manager');
          }

          if (franchiseId.isNotEmpty) {
            await Provider.of<shared.FirestoreService>(context, listen: false)
                .updateUserClaims(
              uid: currentUser.uid,
              franchiseIds: [franchiseId],
              roles: roles,
              additionalClaims: {
                'defaultFranchise': franchiseId,
              },
            );
            await currentUser.getIdToken(true);
          }
        } catch (e, st) {
          shared.ErrorLogger.log(
            message: 'Portal invite claims update failed: $e',
            stack: st.toString(),
            source: 'InviteAcceptScreen',
            severity: 'warning',
            contextData: {
              'token': _effectiveToken,
              'uid': currentUser.uid,
            },
          );
        }

        if (!mounted) return;
        await _exitInviteToApp();
        return;
      }

      // Franchisee path (unchanged)
      await Provider.of<shared.FirestoreService>(context, listen: false)
          .callAcceptInvitationFunction(_effectiveToken!);

      Navigator.of(context).pushReplacementNamed(
        '/franchise-onboarding',
        arguments: {'token': _effectiveToken!},
      );
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Invite accept failed: $e',
        stack: st.toString(),
        source: 'InviteAcceptScreen',
        severity: 'error',
        contextData: {'token': _effectiveToken},
      );
      setState(() {
        _error = AppLocalizations.of(context)?.inviteAcceptFailed ??
            "Failed to accept invitation.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exitInviteToApp() async {
    await Provider.of<shared.AuthService>(context, listen: false)
        .clearInviteToken();
    // Full load into authenticated root — no invite MaterialApp, no hash token.
    html.window.location.href = '${Uri.base.origin}/';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(loc?.acceptInvitation ?? "Accept Invitation"),
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
      AppLocalizations? loc, ColorScheme colorScheme, ThemeData theme) {
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(loc?.loadingInvite ?? "Loading invitation...")],
      );
    }

    final inviteEmail = (_inviteData?['email'] as String?) ?? 'Unknown';
    final inviteFranchiseName =
        (_inviteData?['franchiseName'] as String?) ?? '';

    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    final inviteUid = _inviteData?['invitedUserId'];
    final isLoggedIn = currentUser != null;
    final isUidMatch =
        isLoggedIn && inviteUid != null && currentUser!.uid == inviteUid;
    final userEmailLower = (currentUser?.email ?? '').toLowerCase();
    final inviteEmailLower = inviteEmail.toLowerCase();
    final isEmailMatch = isLoggedIn && userEmailLower == inviteEmailLower;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_unread, color: colorScheme.primary, size: 40),
        const SizedBox(height: 16),
        Text(
          loc?.inviteWelcome(inviteEmail) ?? "Invitation for $inviteEmail",
          style: (theme.textTheme.titleLarge ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        if (inviteFranchiseName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              loc?.inviteForFranchise(inviteFranchiseName) ??
                  "For franchise: $inviteFranchiseName",
              style: (theme.textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(color: colorScheme.secondary),
            ),
          ),
        const SizedBox(height: 18),
        Builder(
          builder: (context) {
            // Already registered + not signed in → prompt sign-in only.
            // If already signed in, fall through to email/uid match + Accept.
            if (_emailRegistered && !isLoggedIn) {
              return Column(
                children: [
                  Text(
                    "Your account is already registered. Please sign in with your email to accept this invitation.",
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Sign In"),
                    onPressed: () {
                      Provider.of<shared.AuthService>(context, listen: false)
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

            if (!isLoggedIn) {
              return Column(
                children: [
                  Text(
                    "Please sign in with your invited email to continue.",
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Sign In"),
                    onPressed: () {
                      Provider.of<shared.AuthService>(context, listen: false)
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
            // Portal invites have no invitedUserId until accept — match on email.
            // Franchisee invites may set invitedUserId; honor either match.
            final isInvitee = isEmailMatch ||
                (inviteUid != null &&
                    isLoggedIn &&
                    currentUser!.uid == inviteUid);

            if (!isInvitee) {
              return Column(
                children: [
                  Text(
                    "You are signed in as ${currentUser?.email ?? 'another account'}.\n"
                    "Please sign in with $inviteEmail to accept this invite.",
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Switch Account"),
                    onPressed: () async {
                      await fb_auth.FirebaseAuth.instance.signOut();
                      Provider.of<shared.AuthService>(context, listen: false)
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
            // All good — signed in as invitee
            return Column(
              children: [
                Text(
                  "You are signed in as the invited user. Click below to accept.",
                  style: theme.textTheme.bodyMedium ?? const TextStyle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _acceptInvite,
                  icon: const Icon(Icons.check_circle),
                  label: Text(loc?.acceptInvitation ?? "Accept Invitation"),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccepted(AppLocalizations? loc, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, color: colorScheme.primary, size: 44),
        const SizedBox(height: 14),
        Text(
          loc?.inviteAcceptedTitle ?? "Invitation Accepted",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontSize: 20),
        ),
        const SizedBox(height: 7),
        Text(
          loc?.inviteAcceptedDesc ?? "Your invitation has been accepted.",
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: Text(loc?.goToDashboard ?? "Go to Dashboard"),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/dashboard', (route) => false);
          },
        ),
      ],
    );
  }
}
