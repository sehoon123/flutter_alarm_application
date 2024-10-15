// /lib/screens/login_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  void _checkUserLoggedIn() async {
    // Check if the user is already logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, navigate to the appropriate screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/home', // Replace with the route of your next screen
        );
      });
    }
  }

  Future<void> _storeUserInfo(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('userName', user.displayName ?? '');
    await prefs.setString('userEmail', user.email ?? '');
    // Store any other user information you need
  }

  // Future<UserCredential> signInWithGoogle() async {
  //   // Trigger the authentication flow
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  //   // Obtain the auth details from the request
  //   final GoogleSignInAuthentication? googleAuth =
  //       await googleUser?.authentication;

  //   // Create a new credential
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );

  //   // Once signed in, return the UserCredential
  //   return await FirebaseAuth.instance.signInWithCredential(credential);
  // }

  // Future<UserCredential> signInWithApple() async {
  //   final credential = await SignInWithApple.getAppleIDCredential(
  //     scopes: [
  //       AppleIDAuthorizationScopes.email,
  //       AppleIDAuthorizationScopes.fullName,
  //     ],
  //   );
  //   return await _auth
  //       .signInWithCredential(OAuthProvider('apple.com').credential(
  //     idToken: credential.identityToken,
  //     accessToken: credential.authorizationCode,
  //   ));
  // }

  // Future<UserCredential> signInWithLine() async {
  //   try {
  //     final result = await LineSDK.instance.login();

  //     // Check for valid accessToken
  //     final credential = OAuthProvider('line').credential(
  //       idToken: result.accessToken.value,
  //     );
  //     return await _auth.signInWithCredential(credential);
  //   } on PlatformException catch (e) {
  //     if (e.code == 'CANCEL') {
  //       // LINE-specific cancellation code
  //       debugPrint('User canceled LINE sign-in');
  //     } else {
  //       debugPrint('Error in signInWithLine: $e');
  //       // Handle other potential errors
  //     }
  //     rethrow;
  //   }
  // }

  Future<UserCredential> signInWithKakao() async {
    try {
      // ... (Get OAuthToken code remains the same) ...
      kakao.OAuthToken token =
          await kakao.UserApi.instance.loginWithKakaoAccount();

      var credential = OAuthProvider('oidc.kakao').credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on kakao.KakaoAuthException catch (e) {
      // Handle common Kakao Auth errors
      switch (e.error) {
        case kakao.AuthErrorCause.accessDenied:
          debugPrint('User canceled Kakao sign-in');
          break;
        case kakao.AuthErrorCause.invalidGrant:
          debugPrint('Invalid Kakao login credentials');
          break;
        default:
          debugPrint('Error in signInWithKakao: $e');
      }
      rethrow; // Pass the error for higher-level handling
    } catch (error) {
      // Catch other potential errors
      debugPrint('Unexpected error in signInWithKakao: $error');
      rethrow;
    }
  }

  void _handleSuccessfulSignIn(UserCredential userCredential) async {
    final user = userCredential.user;
    await _storeUserInfo(user!);

    // Check if the user already exists in Firestore
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      // Create a new user document
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'agreement': false, // Set agreement to 'false' by default
        // Add other fields as needed
      });
    }

    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    bool agreement = userData['agreement'] ?? false;

    // Navigate to the appropriate screen
    Navigator.pushReplacementNamed(
      context,
      agreement ? '/home' : '/agreement',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // InkWell(
              //   child: Image.asset(
              //     'assets/images/google_login.png',
              //     width: 300,
              //   ),
              //   onTap: () async {
              //     try {
              //       final userCredential = await signInWithGoogle();
              //       _handleSuccessfulSignIn(userCredential);
              //       // Navigator.pushReplacementNamed(context, '/agreement');
              //     } catch (e) {
              //       debugPrint('Error in signInWithGoogle: $e');
              //     }
              //   },
              // ),
              // const SizedBox(height: 20), // Add space
              // InkWell(
              //   child: Image.asset(
              //     'assets/images/apple_login.png',
              //     width: 300,
              //   ),
              //   onTap: () async {
              //     final userCredential = await signInWithApple();
              //     _handleSuccessfulSignIn(userCredential);
              //   },
              // ),
              // const SizedBox(height: 20), // Add space
              // InkWell(
              //   child: Image.asset(
              //     'assets/images/line_login.png',
              //     width: 300,
              //   ),
              //   onTap: () async {
              //     try {
              //       final userCredential = await signInWithLine();
              //       _handleSuccessfulSignIn(userCredential);
              //     } catch (e) {
              //       debugPrint('Error in signInWithLine: $e');
              //     }
              //   },
              // ),
              // const SizedBox(height: 20), // Add space
              InkWell(
                child: Image.asset(
                  'assets/images/kakao_login.png',
                  width: 300,
                ),
                onTap: () async {
                  try {
                    debugPrint('Sign in with kakao');
                    final userCredential = await signInWithKakao();
                    _handleSuccessfulSignIn(userCredential);
                  } catch (e) {
                    debugPrint('Error in signInWithKakao: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
