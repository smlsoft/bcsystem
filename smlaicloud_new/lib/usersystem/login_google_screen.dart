import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smlaicloud/bloc/login_bloc/login_bloc.dart';
import 'package:smlaicloud/environment.dart';
import 'package:smlaicloud/flavors.dart';
import 'package:smlaicloud/model/user_login_model.dart';
import 'package:smlaicloud/select_language_screen.dart';
import 'package:smlaicloud/usersystem/utils.dart';
import 'package:smlaicloud/utils/background.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:url_launcher/url_launcher.dart';

/// Login Screen with Google Sign-In (สำหรับ SMLAI flavors)
class LoginGoogleScreen extends StatefulWidget {
  const LoginGoogleScreen({super.key});

  @override
  State<LoginGoogleScreen> createState() => LoginGoogleScreenState();
}

class LoginGoogleScreenState extends State<LoginGoogleScreen> {
  late FirebaseAuth _auth;

  Future<UserCredential?> googleSignInForWeb() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'], // scopes พื้นฐานพอ
      );
      // Obtain the auth details from the request
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
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

  @override
  void initState() {
    if (kIsWeb) {
      _auth = FirebaseAuth.instance;
    } else if (Platform.isWindows || Platform.isMacOS) {
      _auth = FirebaseAuth.instance;
    }
    try {
      // load user profile from local storage
      var userValue = global.prefs.getString("user");
      if (userValue != null) {
        global.userLoginData = UserLoginModel.fromJson(jsonDecode(userValue));
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is TokenLoginSuccess) {
          if (state.userLogin.token != '') {
            Navigator.pushNamedAndRemoveUntil(context, '/login_screen_shop', (route) => false);
          }
        } else if (state is TokenLoginFailed) {
          global.showSnackBar(
            context,
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            state.message,
            Colors.red,
          );
          removeUser();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CloudBackground(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: loginByGoogle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void removeUser() {
    global.prefs.remove("user");
    global.userLoginData = UserLoginModel(name: "", code: "", token: "", email: "", refreshtoken: "", photourl: "");
    setState(() {});
  }

  String _getEnvironmentName() {
    switch (F.appFlavor) {
      case Flavor.smlaidev:
        return 'SML DEV';
      case Flavor.smlaiprod:
        return 'SML PROD';
      case Flavor.smlaiuat:
        return 'SML UAT';
      default:
        return kDebugMode ? 'DEV' : 'PROD';
    }
  }

  Widget loginByGoogle() {
    Widget userLoginWidget = (global.userLoginData.token.isNotEmpty)
        ? Column(children: [
            Container(
                margin: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10.0,
                      spreadRadius: 0.0,
                      offset: Offset(2.0, 2.0),
                    )
                  ],
                ),
                child: global.userLoginData.photourl.isNotEmpty
                    ? Image.network(
                        global.userLoginData.photourl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )),
            const SizedBox(height: 10),
            Text(global.userLoginData.email,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 10),
            FittedBox(
                child: Text(
              "${global.language("welcome")} ${global.userLoginData.name}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (mounted) {
                        context.read<LoginBloc>().add(TokenLogin(token: global.userLoginData.token));
                      }
                    },
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login),
                            SizedBox(width: 12),
                            Text(global.language("login"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        )))),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      removeUser();
                    },
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text(global.language("logout"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        )))),
          ])
        : Container();

    return SingleChildScrollView(
        child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: const Offset(-2.0, -2.0),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: const Offset(2.0, 2.0),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: const Offset(2.0, -2.0),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: const Offset(-2.0, 2.0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // เปลี่ยนภาษา
              Positioned(
                top: 0,
                right: 0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(top: 15, bottom: 15, left: 0, right: 0),
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectLanguageScreen()),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          global.userLanguage = value;
                          global.appConfig.setString('language', global.userLanguage);
                          global.languageSelect(global.userLanguage);
                        });
                      }
                    });
                  },
                  child: Image(image: AssetImage("assets/flags/${global.userLanguage}.png"), width: 30, height: 30),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  imageLogo(),
                  const SizedBox(height: 20),
                  if (global.userLoginData.token.isEmpty) _buildGoogleSignInButton(),
                  userLoginWidget,
                  const SizedBox(height: 20),
                  _buildTermsAndPrivacyPolicy(),

                  /// detail version
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VERSION : ${F.title}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ENVIRONMENT: ${_getEnvironmentName()}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'SERVICE API: ${Environment().config.serviceApi}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'REPORT API: ${Environment().config.reportApi}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'WEBSOCKET: ${Environment().config.webSocketCartService}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )),
    ));
  }

  Widget imageLogo() {
    return Image.asset(
      "assets/img/sml-merchant-icon.png",
      height: 100,
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image(width: 45, height: 45, image: AssetImage("assets/img/google_logo.png")),
                SizedBox(width: 10),
                Text('Sign in with google', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ])),
          onPressed: () {
            if (kIsWeb) {
              googleSignInForWeb().then((value) async {
                if (value != null) {
                  String? userIdToken = await getCurrentUserIdToken();
                  if (userIdToken != null) {
                    global.userLoginData = UserLoginModel(
                        name: value.user!.displayName ?? "",
                        code: "",
                        token: userIdToken,
                        email: value.user!.email ?? "",
                        refreshtoken: userIdToken,
                        photourl: value.user!.photoURL ?? "");

                    String stringUserLoginData = jsonEncode(global.userLoginData);

                    global.prefs.setString("user", stringUserLoginData);
                  }
                }
                setState(() {});
              });
            } else if (Platform.isWindows || Platform.isMacOS) {
              GoogleAuthHelper googleAuthHelper = GoogleAuthHelper();
              googleAuthHelper.signIn().then((value) async {
                if (value != null) {
                  String? userIdToken = await getCurrentUserIdToken();
                  if (userIdToken != null) {
                    global.userLoginData = UserLoginModel(
                        name: value.user!.displayName ?? "",
                        code: "",
                        token: userIdToken,
                        email: value.user!.email ?? "",
                        refreshtoken: userIdToken,
                        photourl: value.user!.photoURL ?? "");

                    String stringUserLoginData = jsonEncode(global.userLoginData);

                    global.prefs.setString("user", stringUserLoginData);
                  }
                }
                setState(() {});
              });
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTermsAndPrivacyPolicy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 10.0,
            spreadRadius: 0.0,
            offset: Offset(2.0, 2.0),
          )
        ],
      ),
      child: Column(children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(decoration: TextDecoration.none),
            children: <TextSpan>[
              TextSpan(
                text: global.language('you_have_accepted'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: ' ${global.language('terms_of_use')} ',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // ignore: deprecated_member_use
                    launch('https://www.smlsoft.com/terms');
                  },
              ),
            ],
          ),
        ),
        RichText(
          text: TextSpan(
            style: const TextStyle(decoration: TextDecoration.none),
            children: <TextSpan>[
              TextSpan(
                text: ' ${global.language('read')} ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: ' ${global.language('privacy_policy')} ',
                style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // ignore: deprecated_member_use
                    launch('https://www.smlsoft.com/privacy');
                  },
              ),
            ],
          ),
        )
      ]),
    );
  }
}
