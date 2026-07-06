// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  // static bool _initialized = false;

  // Future<void> _ensureInitialized() async {
  //   if (!_initialized) {
  //     await _googleSignIn.initialize();
  //     _initialized = true;
  //   }
  // }

  // Future<User?> signInWithGoogle() async {
  //   try {
  //     if (kDebugMode) {
  //       print('Starting Google Sign-In process');
  //     }

  //     await _ensureInitialized();

  //     final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

  //     if (kDebugMode) {
  //       print('Google Sign-In successful, obtaining auth details');
  //     }
  //     final GoogleSignInAuthentication googleAuth = googleUser.authentication;
  //     if (kDebugMode) {
  //       print('Auth details obtained, creating credential');
  //     }
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       idToken: googleAuth.idToken,
  //     );

  //     if (kDebugMode) {
  //       print('Signing in to Firebase');
  //     }
  //     final UserCredential authResult = await _auth.signInWithCredential(credential);
  //     if (kDebugMode) {
  //       print('Firebase sign-in successful');
  //     }
  //     return authResult.user;
  //   } on GoogleSignInException catch (e) {
  //     if (e.code == GoogleSignInExceptionCode.canceled) {
  //       if (kDebugMode) {
  //         print('User cancelled the login process');
  //       }
  //       return null;
  //     }
  //     if (kDebugMode) {
  //       print('GoogleSignInException during Google sign in: ${e.code} - ${e.description}');
  //     }
  //     return null;
  //   } on PlatformException catch (e) {
  //     if (kDebugMode) {
  //       print('PlatformException during Google sign in: ${e.code} - ${e.message}');
  //     }
  //     return null;
  //   } on FirebaseAuthException catch (e) {
  //     if (kDebugMode) {
  //       print('FirebaseAuthException during Google sign in: ${e.code} - ${e.message}');
  //     }
  //     return null;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Unexpected error during Google sign in: $e');
  //     }
  //     return null;
  //   }
  // }

  // Future<void> signOut() async {
  //   await _ensureInitialized();
  //   await _googleSignIn.signOut();
  //   await _auth.signOut();
  // }

  // Future<String?> getCurrentUserIdToken() async {
  //   User? currentUser = _auth.currentUser;
  //   if (currentUser != null) {
  //     String? idToken = await currentUser.getIdToken();
  //     return idToken;
  //   } else {
  //     return null;
  //   }
  // }
}
