import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:doughboys_pizzeria_final/core/utils/log_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Ensures a Firestore user profile with a default role exists for every user
  Future<void> ensureUserProfile(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email,
        'phoneNumber': firebaseUser.phoneNumber,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'completeProfile':
            false, // <--- Ensures onboarding dialog will trigger!
      });
      LogUtils.i(
          'User profile created in Firestore for: ${firebaseUser.email}');
    } else if (!(doc.data()?.containsKey('role') ?? false)) {
      await docRef.update({'role': 'customer'});
      LogUtils.i(
          'User profile role patched in Firestore for: ${firebaseUser.email}');
    }
  }

  // EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
      LogUtils.i('Email sign-in successful for: $email');
      return user;
    } catch (e, stack) {
      LogUtils.e('Email sign-in error', e, stack);
      return null;
    }
  }

  // REGISTRATION (with custom fields)
  Future<User?> registerWithEmail(
      String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      final user = result.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
      LogUtils.i('User registered with email: $email');
      return user;
    } catch (e, stack) {
      LogUtils.e('Email registration error', e, stack);
      return null;
    }
  }

  // PASSWORD RESET
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      LogUtils.i('Password reset email sent to: $email');
    } catch (e, stack) {
      LogUtils.e('Password reset error', e, stack);
      rethrow;
    }
  }

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        LogUtils.w('Google sign-in aborted by user.');
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      LogUtils.i(
          'Google Auth: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        LogUtils.e('Google sign-in error: Null tokens received.');
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final user = authResult.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
      LogUtils.i('Google sign-in successful for: ${user?.email}');
      return user;
    } catch (e, stack) {
      LogUtils.e('Google sign-in error (caught):', e, stack);
      return null;
    }
  }

  // PHONE SIGN-IN (use codeSent callback for UI flow)
  Future<void> signInWithPhone(
    String phoneNumber,
    Function(String verificationId, int? resendToken) codeSentCallback, {
    Function? onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final result = await _auth.signInWithCredential(credential);
          final user = result.user;
          if (user != null) {
            await ensureUserProfile(user);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          LogUtils.e('Phone sign-in failed', e);
          if (onError != null) onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSentCallback(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e, stack) {
      LogUtils.e('Phone sign-in error', e, stack);
      if (onError != null) onError(e);
    }
  }

  // PHONE CODE VERIFICATION
  Future<User?> verifySmsCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
      LogUtils.i('Phone SMS verification successful.');
      return user;
    } catch (e, stack) {
      LogUtils.e('Phone SMS verification error', e, stack);
      return null;
    }
  }

  // GUEST SESSION (no real login, just flag in memory)
  Future<void> setGuestSession() async {
    try {
      await _auth.signOut();
      LogUtils.i('Guest session started.');
    } catch (e, stack) {
      LogUtils.e('Set guest session error', e, stack);
    }
  }

  // DEMO SESSION (no real login, demo state only)
  Future<void> setDemoSession() async {
    try {
      await _auth.signOut();
      LogUtils.i('Demo session started.');
    } catch (e, stack) {
      LogUtils.e('Set demo session error', e, stack);
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      LogUtils.i('User signed out.');
    } catch (e, stack) {
      LogUtils.e('Sign-out error', e, stack);
    }
  }

  // EMAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      LogUtils.i('Email verification sent to: ${user.email}');
    }
  }
}
