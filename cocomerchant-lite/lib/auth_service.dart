import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );

  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign-In process');
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (kDebugMode) {
          print('User cancelled the login process');
        }
        return null;
      }

      if (kDebugMode) {
        print('Google Sign-In successful, obtaining auth details');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (kDebugMode) {
        print('Auth details obtained, creating credential');
      }
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('Signing in to Firebase');
      }
      final UserCredential authResult = await _auth.signInWithCredential(credential);
      if (kDebugMode) {
        print('Firebase sign-in successful');
      }
      return authResult.user;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformException during Google sign in: ${e.code} - ${e.message}');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during Google sign in: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during Google sign in: $e');
      }
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential authResult = await _auth.signInWithCredential(oauthCredential);
      return authResult.user;
    } catch (e) {
      if (kDebugMode) {
        print('Error during Apple sign in: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> getCurrentUserIdToken() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String? idToken = await currentUser.getIdToken();
      return idToken;
    } else {
      return null;
    }
  }
}
