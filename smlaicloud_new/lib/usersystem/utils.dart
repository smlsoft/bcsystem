// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as google_sign_in_all_platforms;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:smlaicloud/global.dart' as global;

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Converts user data coming from native code into the proper platform interface type.
GoogleSignInUserData? getUserDataFromMap(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  return GoogleSignInUserData(
      email: data['email']! as String,
      id: data['id']! as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      idToken: data['idToken'] as String?,
      serverAuthCode: data['serverAuthCode'] as String?);
}

/// Converts token data coming from native code into the proper platform interface type.
GoogleSignInTokenData getTokenDataFromMap(Map<String, dynamic> data) {
  return GoogleSignInTokenData(
    idToken: data['idToken'] as String?,
    accessToken: data['accessToken'] as String?,
    serverAuthCode: data['serverAuthCode'] as String?,
  );
}

class GoogleAuthHelper {
  // สร้างตัวแปร singleton เพื่อป้องกันการสร้าง instance ซ้ำซ้อน
  static GoogleAuthHelper? _instance;
  static google_sign_in_all_platforms.GoogleSignIn? _googleSignInInstance;

  // Factory constructor สำหรับ singleton pattern
  factory GoogleAuthHelper() {
    _instance ??= GoogleAuthHelper._internal();
    return _instance!;
  }

  // Constructor แบบ private
  GoogleAuthHelper._internal();

  // getter สำหรับเข้าถึง instance ของ GoogleSignIn
  google_sign_in_all_platforms.GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= google_sign_in_all_platforms.GoogleSignIn(
        params: google_sign_in_all_platforms.GoogleSignInParams(
            clientId: global.googleSignInClientId,
            clientSecret: global.googleSignInClientSecret,
            redirectPort: 3000,
            scopes: ['email', 'profile']));
    return _googleSignInInstance!;
  }

  /// ล็อกอินด้วย Google Account และบังคับให้เลือก account ใหม่ทุกครั้ง
  Future<UserCredential?> signIn() async {
    try {
      // ทำการ sign out ก่อนเพื่อบังคับให้แสดงหน้าเลือก account ใหม่ทุกครั้ง
      if (kDebugMode) {
        print("Signing out from previous sessions...");
      }
      await _googleSignIn.signOut();

      // รอสักครู่เพื่อให้การ signOut ทำงานได้สมบูรณ์
      await Future.delayed(const Duration(milliseconds: 300));

      if (kDebugMode) {
        print("Starting new sign-in process...");
      }
      final credentials = await _googleSignIn.signInOnline();

      if (credentials == null) {
        if (kDebugMode) {
          print("Google Sign In Failed: No credentials returned");
        }
        return null;
      }

      if (kDebugMode) {
        print("Google Sign In Success: ${credentials.accessToken}");
      }

      // สร้าง credential สำหรับ Firebase Auth
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      // ล็อกอินเข้าสู่ Firebase
      final UserCredential authResult =
          await _auth.signInWithCredential(authCredential);
      if (kDebugMode) {
        print("Firebase Auth Success: ${authResult.user?.displayName}");
      }

      return authResult;
    } catch (e) {
      if (kDebugMode) {
        print("Error during Google Sign In: $e");
      }
      return null;
    }
  }

  /// ดึงข้อมูลผู้ใช้จาก JWT token
  Map<String, dynamic> decodeIdToken(String? idToken) {
    if (idToken == null) return {};

    try {
      // แยกส่วนข้อมูลจาก JWT token
      final parts = idToken.split('.');
      if (parts.length > 1) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        return json.decode(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error decoding ID token: $e");
      }
    }

    return {};
  }
}

// Class เก็บข้อมูลผลลัพธ์การ sign in
class GoogleSignInResult {
  final google_sign_in_all_platforms.GoogleSignInCredentials credentials;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  GoogleSignInResult({
    required this.credentials,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accessToken': credentials.accessToken,
      'idToken': credentials.idToken,
    };
  }

  @override
  String toString() {
    return 'GoogleSignInResult(email: $email, displayName: $displayName)';
  }
}
