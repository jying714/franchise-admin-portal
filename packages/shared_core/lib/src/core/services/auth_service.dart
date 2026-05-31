// packages/shared_core/lib/src/core/services/auth_service.dart

import '../models/user.dart';

/// Pure interface — no Firebase, no Flutter
abstract class AuthService {
  /// Current authenticated user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign in with email/password
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email/password
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile (name, photo)
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  });

  /// Reauthenticate user
  Future<void> reauthenticateWithCredential({
    required String email,
    required String password,
  });

  /// Delete user account
  Future<void> deleteUser();

  /// Get ID token
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Set guest session (anonymous Firebase auth)
  Future<void> setGuestSession();

  /// Set demo session (anonymous Firebase auth for testing/demo mode)
  Future<void> setDemoSession();

  Future<User> signInWithGoogle();

  // === P2.5 Web-App Cleanup: Invite/Onboarding token helpers (admin flows) ===
  // Stored in memory or local storage per platform impl; used by sign-in + onboarding wizard.
  Future<String?> getInviteToken();
  Future<void> saveInviteToken(String token);
  Future<void> clearInviteToken();

  // === P2.5: Phone auth stubs (web admin may use Firebase phone or stub for now) ===
  Future<void> signInWithPhone(String phoneNumber);
  Future<User?> verifySmsCode(String smsCode);
}
