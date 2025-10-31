import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:franchise_admin_portal/core/utils/log_utils.dart';
import '../models/user.dart' as app;
import 'dart:html' as html show window;

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  app.User? _profileUser; // Note: avoid name clash with Firebase User
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  app.User? get profileUser => _profileUser;
  String? _inviteToken;

  AuthService() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  /// EMAIL SIGN-IN (for admin)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      LogUtils.i('Admin signed in with email: $email');
      notifyListeners();
      return user;
    } catch (e, stack) {
      LogUtils.e('Admin email sign-in error', e, stack);
      return null;
    }
  }

  /// EMAIL REGISTRATION (optional, if ever used)
  Future<User?> registerWithEmail(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      final user = result.user;
      LogUtils.i('Admin registered with email: $email');
      notifyListeners();
      return user;
    } catch (e, stack) {
      LogUtils.e('Admin registration error', e, stack);
      return null;
    }
  }

  /// PASSWORD RESET (admin portal)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      LogUtils.i('Password reset email sent: $email');
    } catch (e, stack) {
      LogUtils.e('Password reset error', e, stack);
      rethrow;
    }
  }

  /// GOOGLE SIGN-IN (optional for web/mobile)
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        LogUtils.i(
            'Google sign-in successful (web): ${user?.email ?? 'No email'}');
        notifyListeners();
        return user;
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          LogUtils.w('Google sign-in canceled.');
          return null;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential authResult =
            await _auth.signInWithCredential(credential);
        final user = authResult.user;
        LogUtils.i('Google sign-in successful: ${user?.email ?? 'No email'}');
        notifyListeners();
        return user;
      }
    } catch (e, stack) {
      LogUtils.e('Google sign-in error', e, stack);
      return null;
    }
  }

  /// SIGN OUT (admin)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      LogUtils.i('Admin signed out.');
    } catch (e, stack) {
      LogUtils.e('Sign-out error', e, stack);
    }
  }

  /// EMAIL VERIFICATION (optional)
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      LogUtils.i('Verification sent to: ${user.email}');
    }
  }

  Future<void> signInWithPhone(
    String phoneNumber,
    Function(String verificationId, int? resendToken) codeSentCallback, {
    Function? onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (onError != null) onError(e);
        },
        codeSent: codeSentCallback,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (onError != null) onError(e);
    }
  }

  Future<User?> verifySmsCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  void saveInviteToken(String? token) {
    print('[auth_service.dart] saveInviteToken called with token=$token');
    _inviteToken = token;
    // Persist for reload/redirect flow, especially on web:
    if (token != null) {
      if (kIsWeb) {
        print(
            '[auth_service.dart] saveInviteToken: saving token to localStorage');
        html.window.localStorage['inviteToken'] = token;
      }
    }
  }

  String? getInviteToken() {
    print('[auth_service.dart] getInviteToken called');
    if (_inviteToken != null) {
      print(
          '[auth_service.dart] getInviteToken: returning from _inviteToken ($_inviteToken)');
      return _inviteToken;
    }
    if (kIsWeb) {
      final token = html.window.localStorage['inviteToken'];
      print(
          '[auth_service.dart] getInviteToken: returning from localStorage ($token)');
      return token;
    }
    print('[auth_service.dart] getInviteToken: no token found, returning null');
    return null;
  }

  void clearInviteToken() {
    print('[auth_service.dart] clearInviteToken called');
    _inviteToken = null;
    if (kIsWeb) {
      print(
          '[auth_service.dart] clearInviteToken: removing token from localStorage');
      html.window.localStorage.remove('inviteToken');
    }
  }

  // All franchise-specific profile logic should be handled by a profile/provider class, not here.
}
