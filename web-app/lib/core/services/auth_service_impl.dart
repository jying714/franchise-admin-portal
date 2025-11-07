// web-app/lib/core/services/auth_service_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:shared_core/src/core/models/user.dart';

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
}
