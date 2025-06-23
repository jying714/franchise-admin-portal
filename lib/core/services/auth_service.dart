import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:franchise_admin_portal/core/utils/log_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ensures user profile exists with a default role (for admin UI usage)
  Future<void> ensureUserProfile(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email,
        'phoneNumber': firebaseUser.phoneNumber ?? '',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'onboarded': false,
      });
      LogUtils.i('User profile created for admin: ${firebaseUser.email}');
    }
  }

  /// EMAIL SIGN-IN (used by admin)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) await ensureUserProfile(user);
      LogUtils.i('Admin signed in with email: $email');
      return user;
    } catch (e, stack) {
      LogUtils.e('Admin email sign-in error', e, stack);
      return null;
    }
  }

  /// EMAIL REGISTRATION (optional)
  Future<User?> registerWithEmail(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      final user = result.user;
      if (user != null) await ensureUserProfile(user);
      LogUtils.i('Admin registered with email: $email');
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

  /// GOOGLE SIGN-IN (optional for web)
  Future<User?> signInWithGoogle() async {
    try {
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
      if (user != null) await ensureUserProfile(user);
      LogUtils.i('Google sign-in successful: ${user?.email ?? 'No email'}');
      return user;
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
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
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
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    return result.user;
  }
}
