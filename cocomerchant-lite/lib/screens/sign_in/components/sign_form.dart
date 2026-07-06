// ignore_for_file: use_build_context_synchronously

import 'package:cocomerchant_lite/auth_service.dart';
import 'package:cocomerchant_lite/bloc/login_bloc/login_bloc.dart';
import 'package:cocomerchant_lite/screens/login_success/login_success_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../components/default_button.dart';
import 'package:cocomerchant_lite/global.dart';

class SignForm extends StatefulWidget {
  const SignForm({super.key});

  @override
  SignFormState createState() => SignFormState();
}

class SignFormState extends State<SignForm> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        if (kDebugMode) {
          print('Logged in: ${user.displayName}');
        }

        String? userIdToken = await _auth.getCurrentUserIdToken();
        if (userIdToken != null) {
          context.read<LoginBloc>().add(TokenLogin(user: user.email!, token: userIdToken));
        }
      } else {
        if (kDebugMode) {
          print('Failed to log in');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log in'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google sign in: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during Google sign in $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _auth.signInWithApple();
      if (user != null) {
        if (kDebugMode) {
          print('Logged in with Apple: ${user.email}');
          print('refreshToken: ${user.refreshToken}');
        }

        // String? userIdToken = await _auth.getCurrentUserIdToken();
        // if (userIdToken != null) {
        //   context.read<LoginBloc>().add(TokenLogin(user: user.email!, token: userIdToken));
        // }
      } else {
        if (kDebugMode) {
          print('Failed to log in with Apple');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log in with Apple'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Apple sign in: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during Apple sign in'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state is TokenLoginSuccess) {
          await appConfig.write("user", state.userLogin.userName);

          // Navigate to home page or show success message
          if (state.userLogin.token != '') {
            Navigator.pushNamed(context, LoginSuccessScreen.routeName);
          }
        } else if (state is TokenLoginFailed) {
          // Show error message
          setState(() {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: ${state.message}'),
              ),
            );
          });
        }
      },
      child: Column(
        children: [
          Semantics(
            label: 'Login with Google',
            child: DefaultButton(
              image: const AssetImage("assets/images/google_logo.png"),
              text: "Login with Google",
              press: _isLoading ? null : _handleGoogleSignIn,
            ),
          ),
          // if (Platform.isIOS)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 16.0),
          //     child: DefaultButton(
          //       image: const AssetImage("assets/images/apple_logo.png"),
          //       text: "Login with Apple",
          //       press: _isLoading ? null : _handleAppleSignIn,
          //     ),
          //   ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
