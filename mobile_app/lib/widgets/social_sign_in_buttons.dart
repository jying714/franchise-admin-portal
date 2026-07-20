// ignore_for_file: unused_import

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

class SocialSignInButtons extends StatefulWidget {
  final void Function(shared.User? user)? onSuccess;
  final void Function(String error)? onError;
  final void Function(bool)? setLoading;

  final bool showGoogle;
  final bool showPhone;
  final bool allowGuest;
  final bool allowDemo;
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
    this.allowGuest = false,
    this.allowDemo = false,
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
      BuildContext context, shared.User user) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.id);
    if (existing == null) {
      final newUser = shared.User(
        id: user.id,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        roles: const ['customer'],
        language: user.language ?? "en",
        status: 'active',
        addresses: [],
      );
      await firestoreService.addUser(newUser);
    }
  }

  Future<void> _handleSignIn(
      BuildContext context, Future<shared.User> Function() signInMethod) async {
    _setLoading(true);
    try {
      final user = await signInMethod();
      if (!mounted) return;
      if (widget.ensureUserProfile != null) {
        await widget.ensureUserProfile!(user);
      } else {
        await _defaultEnsureUserProfile(context, user);
      }
      if (!mounted) return;
      widget.onSuccess?.call(user);
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _handlePhoneSignIn(BuildContext context) async {
    // Phone flow aligned to future AuthService extensions
    String phone = '';
    bool smsSent = false;
    String smsCode = '';
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              smsSent ? 'Enter SMS Code' : 'Sign in with Phone',
              style: shared.UiConfig.titleStyle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!smsSent)
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1XXXXXXXXXX',
                      labelStyle: shared.UiConfig.bodyStyle,
                    ),
                    onChanged: (v) => phone = v,
                  ),
                if (smsSent)
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'SMS Code',
                      labelStyle: shared.UiConfig.bodyStyle,
                    ),
                    onChanged: (v) => smsCode = v,
                  ),
                if (error != null)
                  Padding(
                    padding: shared.UiConfig.defaultPadding,
                    child: Text(error!,
                        style: shared.UiConfig.errorTextColor != null
                            ? shared.UiConfig.bodyStyle
                                .copyWith(color: shared.UiConfig.errorTextColor)
                            : shared.UiConfig.bodyStyle),
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
                      final authService = Provider.of<shared.AuthService>(
                          context,
                          listen: false);
                      // Future extension: await authService.signInWithPhone(phone);
                      setDialogState(() => smsSent = true);
                    } catch (e) {
                      setDialogState(() => error = e.toString());
                    }
                    if (mounted) _setLoading(false);
                  },
                  child: const Text('Send Code'),
                ),
              if (smsSent)
                TextButton(
                  onPressed: () async {
                    _setLoading(true);
                    try {
                      final authService = Provider.of<shared.AuthService>(
                          context,
                          listen: false);
                      // Future extension: final user = await authService.verifySmsCode(...);
                      if (!mounted) return;
                      widget.onSuccess?.call(null);
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      setDialogState(() => error = e.toString());
                    }
                    if (mounted) _setLoading(false);
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
    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final isBusy = widget.isLoading || _loading;

    return Column(
      children: [
        if (widget.showGoogle)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
              label: Text('Sign in with Google',
                  style: shared.UiConfig.bodyBoldStyle),
              onPressed: isBusy
                  ? null
                  : () => _handleSignIn(
                        context,
                        () async => await authService.signInWithGoogle(),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.googleButtonColor ?? shared.UiConfig.surfaceColor,
                foregroundColor: shared.UiConfig.textColor,
                padding: shared.UiConfig.defaultPadding,
              ),
            ),
          ),
        if (widget.showGoogle)
          SizedBox(height: shared.UiConfig.defaultPadding.top),
        if (widget.showPhone)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, color: Colors.green, size: 22),
              label: Text('Sign in with Phone',
                  style: shared.UiConfig.bodyBoldStyle),
              onPressed: isBusy ? null : () => _handlePhoneSignIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.phoneButtonColor ??
                    shared.UiConfig.primaryColor.withOpacity(0.1),
                foregroundColor: shared.UiConfig.primaryColor,
                padding: shared.UiConfig.defaultPadding,
              ),
            ),
          ),
        if (widget.showPhone)
          SizedBox(height: shared.UiConfig.defaultPadding.top),
        if (widget.allowGuest)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.person_outline,
                  color: shared.UiConfig.hintTextColor, size: 22),
              label: Text('Continue as Guest',
                  style: shared.UiConfig.bodyBoldStyle),
              onPressed: isBusy
                  ? null
                  : () async {
                      _setLoading(true);
                      try {
                        final authService = Provider.of<shared.AuthService>(
                            context,
                            listen: false);
                        await authService.setGuestSession();
                        if (!mounted) return;
                        widget.onSuccess?.call(null);
                      } catch (e) {
                        if (!mounted) return;
                        widget.onError?.call(e.toString());
                      } finally {
                        if (mounted) _setLoading(false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: shared.UiConfig.surfaceColor,
                foregroundColor: shared.UiConfig.textColor,
                padding: shared.UiConfig.defaultPadding,
              ),
            ),
          ),
        if (widget.allowGuest)
          SizedBox(height: shared.UiConfig.defaultPadding.top),
        if (widget.allowDemo)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility,
                  color: Colors.deepPurple, size: 22),
              label: Text('Test Drive (Demo Mode)',
                  style: shared.UiConfig.bodyBoldStyle),
              onPressed: isBusy
                  ? null
                  : () async {
                      _setLoading(true);
                      try {
                        final authService = Provider.of<shared.AuthService>(
                            context,
                            listen: false);
                        await authService.setDemoSession();
                        if (!mounted) return;
                        widget.onSuccess?.call(null);
                      } catch (e) {
                        if (!mounted) return;
                        widget.onError?.call(e.toString());
                      } finally {
                        if (mounted) _setLoading(false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                foregroundColor: Colors.deepPurple,
                padding: shared.UiConfig.defaultPadding,
              ),
            ),
          ),
        if (widget.allowDemo)
          SizedBox(height: shared.UiConfig.defaultPadding.top),
        if (isBusy) ...[
          SizedBox(height: shared.UiConfig.defaultPadding.top),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}
