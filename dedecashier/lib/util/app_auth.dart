import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/clipper.dart';

class ApplicationAuthentication extends StatefulWidget {
  const ApplicationAuthentication({super.key});

  @override
  State<ApplicationAuthentication> createState() =>
      _ApplicationAuthenticationState();
}

class _ApplicationAuthenticationState extends State<ApplicationAuthentication> {
  final heightOfAppBar = 56.0;
  // bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var heightOfScreen = MediaQuery.of(context).size.height - heightOfAppBar;

    return Scaffold(
        body: Stack(
      children: [
        Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromRGBO(0, 123, 255, 0.55),
                Color.fromRGBO(0, 123, 255, 1),
              ],
            )))),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: ClipPath(
            clipper: VFPosLoginShapeClipper(),
            child: Container(
              height: heightOfScreen,
              decoration: const BoxDecoration(color: Color(0xFF007BFF)),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 500,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10.0), // set border radius here
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/app_logo.png', // path to your image asset
                        height: 100.0,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 113, 15, 15),
                              width: 2.0,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      ElevatedButton(
                        onPressed: () {
                          // handle login button press here
                          // validate user credentials
                          // navigate to home screen on successful login
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Colors.blue), // set button background color
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  6.0), // set border radius here
                            ),
                          ),
                          padding:
                              WidgetStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(
                                vertical: 16.0), // set button padding here
                          ),
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text('or'),
                      const SizedBox(height: 16.0),
                      ElevatedButton.icon(
                          icon:
                              Image.asset('assets/icons/icon-gmail-white.png'),
                          onPressed: () {},
                          style: ButtonStyle(
                            padding:
                                WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.symmetric(
                                  vertical: 16.0), // set button padding here
                            ),
                          ),
                          label: const Text('Google'))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class AuthService {
  // Login
  Future<bool> login() async {
    // Simulate a future for response after 2 second.
    return await Future<bool>.delayed(
        const Duration(seconds: 2), () => Random().nextBool());
  }

  // Logout
  Future<void> logout() async {
    // Simulate a future for response after 1 second.
    return await Future<void>.delayed(const Duration(seconds: 1));
  }
}
