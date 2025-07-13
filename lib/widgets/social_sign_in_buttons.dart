import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

/// SocialSignInButtons (ADMIN VERSION)
/// Only allows Google and Phone sign-in (no guest or demo modes).
class SocialSignInButtons extends StatefulWidget {
  final void Function(User? user)? onSuccess;
  final void Function(String error)? onError;
  final void Function(bool)? setLoading;

  final bool showGoogle;
  final bool showPhone;
  final bool isLoading;

  final Color? googleButtonColor;
  final Color? phoneButtonColor;

  final Future<void> Function(User user)? ensureUserProfile;

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
    setState(() => _loading = value);
    widget.setLoading?.call(value);
  }

  Future<void> _defaultEnsureUserProfile(
      BuildContext context, User user) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.uid);
    if (existing == null) {
      final newUser = admin_user.User(
        id: user.uid,
        name: user.displayName ?? "",
        email: user.email ?? "",
        phoneNumber: user.phoneNumber,
        addresses: [],
        language: "en",
        roles: [admin_user.User.roleAdmin],
        status: "active",
      );
      await firestoreService.addUser(newUser);
    }
  }

  Future<void> _handleSignIn(
      BuildContext context, Future<User?> Function() signInMethod) async {
    _setLoading(true);
    try {
      final user = await signInMethod();
      if (!mounted) return;
      if (user != null) {
        if (widget.ensureUserProfile != null) {
          await widget.ensureUserProfile!(user);
        } else {
          await _defaultEnsureUserProfile(context, user);
        }
        if (!mounted) return;
        // --- ADD THIS BLOCK ---
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        Provider.of<UserProfileNotifier>(context, listen: false)
            .listenToUser(firestoreService, user.uid);
        // --- END BLOCK ---
        widget.onSuccess?.call(user);
      } else {
        if (!mounted) return;
        widget.onError?.call("Sign-in failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e.toString());
    }
    if (!mounted) return;
    _setLoading(false);
  }

  Future<void> _handlePhoneSignIn(BuildContext context) async {
    String phone = '';
    String? verificationId;
    bool smsSent = false;
    String smsCode = '';
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(smsSent ? 'Enter SMS Code' : 'Sign in with Phone'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!smsSent)
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1XXXXXXXXXX',
                    ),
                    onChanged: (v) => phone = v,
                  ),
                if (smsSent)
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SMS Code',
                    ),
                    onChanged: (v) => smsCode = v,
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              if (!smsSent)
                TextButton(
                  onPressed: () async {
                    _setLoading(true);
                    try {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      await authService.signInWithPhone(
                        phone,
                        (vid, _) {
                          setDialogState(() {
                            smsSent = true;
                            verificationId = vid;
                          });
                        },
                        onError: (err) {
                          setDialogState(() {
                            error = err.toString();
                          });
                        },
                      );
                    } catch (e) {
                      setDialogState(() {
                        error = e.toString();
                      });
                    }
                    if (!mounted) return;
                    _setLoading(false);
                  },
                  child: const Text('Send Code'),
                ),
              if (smsSent)
                TextButton(
                  onPressed: () async {
                    _setLoading(true);
                    try {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      final user = await authService.verifySmsCode(
                          verificationId!, smsCode);
                      if (!mounted) return;
                      if (user != null) {
                        if (widget.ensureUserProfile != null) {
                          await widget.ensureUserProfile!(user);
                        } else {
                          await _defaultEnsureUserProfile(context, user);
                        }
                        if (!mounted) return;
                        widget.onSuccess?.call(user);
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() {
                          error = "Incorrect code.";
                        });
                      }
                    } catch (e) {
                      setDialogState(() {
                        error = e.toString();
                      });
                    }
                    if (!mounted) return;
                    _setLoading(false);
                  },
                  child: const Text('Verify'),
                ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
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
                  : () => _handleSignIn(
                        context,
                        () => authService.signInWithGoogle(),
                      ),
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
              onPressed: isBusy ? null : () => _handlePhoneSignIn(context),
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
