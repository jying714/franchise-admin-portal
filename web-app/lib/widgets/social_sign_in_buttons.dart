// P1 Batch 3: Duplicated widget (exact filename match with mobile_app).
// Mobile canonical in mobile_app/lib/widgets/.
// Safe for deletion in next batch if admin previews can reuse via shared_ui package or path dependency.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart'
    show UserProfileNotifier;

typedef OnSuccessCallback = void Function(shared.User? user);
typedef OnErrorCallback = void Function(String error);

/// SocialSignInButtons (ADMIN VERSION)
/// Only allows Google and Phone sign-in (no guest or demo modes).
class SocialSignInButtons extends StatefulWidget {
  final OnSuccessCallback? onSuccess;
  final OnErrorCallback? onError;
  final void Function(bool)? setLoading;

  final bool showGoogle;
  final bool showPhone;
  final bool isLoading;

  final Color? googleButtonColor;
  final Color? phoneButtonColor;

  final Future<void> Function(shared.User user)? ensureUserProfile;

  const SocialSignInButtons({
    super.key,
    this.onSuccess,
    this.onError,
    this.setLoading,
    this.showGoogle = true,
    this.showPhone = true,
    this.isLoading = false,
    this.googleButtonColor,
    this.phoneButtonColor,
    this.ensureUserProfile,
  });

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  bool _loading = false;

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _loading = value);
    widget.setLoading?.call(value);
  }

  Future<void> _defaultEnsureUserProfile(shared.User user) async {
    final firestoreService = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );
    final existing = await firestoreService.getUser(user.id);
    if (existing == null) {
      final newUser = shared.User(
        id: user.id,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        addresses: [],
        language: "en",
        roles: [shared.User.roleAdmin],
        status: "active",
      );
      await firestoreService.addUser(newUser);
    }
  }

  Future<void> _handleSignIn(
      Future<shared.User?> Function() signInMethod) async {
    _setLoading(true);
    try {
      final user = await signInMethod();
      if (!mounted) return;

      if (user != null) {
        if (widget.ensureUserProfile != null) {
          await widget.ensureUserProfile!(user);
        } else {
          await _defaultEnsureUserProfile(user);
        }
        if (!mounted) return;

        final firestoreService = Provider.of<shared.FirestoreService>(
          context,
          listen: false,
        );
        Provider.of<UserProfileNotifier>(context, listen: false)
            .listenToUser(user.id);

        widget.onSuccess?.call(user);
      } else {
        widget.onError?.call("Sign-in failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handlePhoneSignIn() async {
    // Phone flow logic (stubbed for now - full implementation can be expanded)
    widget.onError?.call("Phone sign-in is currently in development.");
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final isBusy = widget.isLoading || _loading;

    return Column(
      children: [
        if (widget.showGoogle)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
              label: const Text('Sign in with Google'),
              onPressed: isBusy
                  ? null
                  : () => _handleSignIn(() => authService.signInWithGoogle()),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.googleButtonColor ?? Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        if (widget.showGoogle) const SizedBox(height: 8),
        if (widget.showPhone)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, color: Colors.green, size: 22),
              label: const Text('Sign in with Phone'),
              onPressed: isBusy ? null : _handlePhoneSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.phoneButtonColor ?? Colors.green[50],
                foregroundColor: Colors.green[900],
              ),
            ),
          ),
        if (widget.showPhone) const SizedBox(height: 8),
        if (isBusy) ...[
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}
