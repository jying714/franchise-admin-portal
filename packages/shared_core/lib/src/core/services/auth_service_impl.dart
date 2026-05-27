import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'auth_service.dart';
import '../models/user.dart' as app_user;

class AuthServiceImpl implements AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  @override
  app_user.User? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    return app_user.User(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      roles: const ['customer'],
      language: 'en',
      status: 'active',
    );
  }

  @override
  Stream<app_user.User?> get authStateChanges {
    return _auth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return app_user.User(
        id: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
        roles: const ['customer'],
        language: 'en',
        status: 'active',
      );
    });
  }

  @override
  Future<app_user.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return currentUser ??
        app_user.User(
          id: cred.user!.uid,
          name: cred.user!.displayName ?? '',
          email: cred.user!.email ?? '',
          roles: const ['customer'],
          language: 'en',
          status: 'active',
        );
  }

  @override
  Future<app_user.User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return app_user.User(
      id: cred.user!.uid,
      name: '',
      email: email,
      roles: const ['customer'],
      language: 'en',
      status: 'active',
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    if (photoURL != null) await _auth.currentUser?.updatePhotoURL(photoURL);
  }

  @override
  Future<void> reauthenticateWithCredential(
      {required String email, required String password}) async {}
  @override
  Future<void> deleteUser() async => await _auth.currentUser?.delete();
  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async =>
      await _auth.currentUser?.getIdToken(forceRefresh);

  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> setGuestSession() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> setDemoSession() async {
    // Demo mode currently uses anonymous auth (can be extended later with demo-specific credentials or Firestore flags)
    await _auth.signInAnonymously();
  }
}
