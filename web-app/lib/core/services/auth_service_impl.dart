// web-app/lib/core/services/auth_service_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:shared_core/shared_core.dart' show AuthService, User;

class AuthServiceImpl implements AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;

  @override
  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
  }

  @override
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) =>
        firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null);
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user!);
  }

  @override
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user!);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
    await user.reload();
  }

  @override
  Future<void> reauthenticateWithCredential({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user to reauthenticate');

    final credential = firebase.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user to delete');
    await user.delete();
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Maps Firebase User → shared_core User
  /// Core fields only — roles, isDeveloper, etc. must be loaded from Firestore
  User _mapFirebaseUser(firebase.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phoneNumber: '',
      roles: const [],
      addresses: const [],
      language: 'en',
      status: 'active',
      defaultFranchise: null,
      avatarUrl: firebaseUser.photoURL,
      isActive: true,
      franchiseIds: const [],
      completeProfile: null,
      onboardingComplete: false,
      updatedAt: null,
    );
  }

  // === Missing overrides from shared AuthService (P2.5 web cleanup) ===
  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> setGuestSession() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> setDemoSession() async {
    // Demo: anonymous + flag; in real would set custom claims or local flag
    await _auth.signInAnonymously();
  }

  @override
  Future<User> signInWithGoogle() async {
    final credential = await _auth.signInWithPopup(firebase.GoogleAuthProvider());
    final fbUser = credential.user!;
    return _mapFirebaseUser(fbUser);
  }

  // === P2.5 Invite token helpers (web uses in-memory; persist via onboarding if needed) ===
  String? _inviteToken;
  @override
  Future<String?> getInviteToken() async => _inviteToken;
  @override
  Future<void> saveInviteToken(String token) async {
    _inviteToken = token;
  }
  @override
  Future<void> clearInviteToken() async {
    _inviteToken = null;
  }

  // P2.5 phone stubs for admin web (can enhance with firebase phone provider + captcha)
  @override
  Future<void> signInWithPhone(String phoneNumber) async {
    throw UnimplementedError('Phone sign-in stubbed for P2.5 web cleanup; implement with Firebase auth phone flow + UI state.');
  }

  @override
  Future<User?> verifySmsCode(String smsCode) async {
    throw UnimplementedError('Phone verify stubbed for P2.5; requires verificationId from prior signInWithPhone.');
  }
}
