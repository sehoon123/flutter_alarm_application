// /lib/screens/login_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'home_screen.dart';
import 'agreement_screen.dart'; // AgreementScreen이 있다면 추가

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggingIn = false; // 로딩 상태 관리

  @override
  void initState() {
    super.initState();
    // 초기 로그인 상태는 AuthGate에서 관리하므로 별도의 체크는 필요 없음
  }

  Future<void> _storeUserInfo(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('userName', user.displayName ?? '');
    await prefs.setString('userEmail', user.email ?? '');
    // 필요에 따라 추가 정보 저장
  }

  Future<UserCredential> signInWithKakao() async {
    try {
      // ... (Get OAuthToken code remains the same) ...
      kakao.OAuthToken token =
          await kakao.UserApi.instance.loginWithKakaoAccount();
      debugPrint('카카오계정으로 로그인 성공: ${token.accessToken}');

      var credential = OAuthProvider('oidc.kakao').credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );
      debugPrint('Firebase Auth로 로그인 성공');

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

  Future<void> _handleSuccessfulSignIn(UserCredential userCredential) async {
    if (!mounted) return; // Check if the widget is still mounted
    final user = userCredential.user;
    if (user == null) return;

    await _storeUserInfo(user);

    // Firestore에서 사용자 존재 여부 확인
    final userDoc =
        FirebaseFirestore.instance.collection('user_collection').doc(user.uid);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      // 사용자 문서 생성
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'agreement': false, // 기본값 설정
        'coins': 0,
        'events_applied': [],
        'events_won': [],
        // 추가 필드 필요시 추가
      });
    }
  }

  Future<void> _loginWithKakao() async {
    setState(() {
      _isLoggingIn = true;
    });

    try {
      debugPrint('카카오 로그인 시작');
      final userCredential = await signInWithKakao();
      // After signInWithKakao, check if the widget is still mounted before proceeding
      if (!mounted) return;
      await _handleSuccessfulSignIn(userCredential);
      // AuthGate가 실시간으로 인증 상태를 감지하여 HomeScreen으로 이동
    } catch (e) {
      if (!mounted)
        return; // Ensure the widget is still mounted before showing toast
      debugPrint('카카오 로그인 실패: $e');
      Fluttertoast.showToast(
        msg: "로그인에 실패했습니다. 다시 시도해주세요.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (!mounted) return; // Check before calling setState
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  @override
  void dispose() {
    // If you have any controllers or listeners, dispose them here.
    super.dispose();
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
          child: _isLoggingIn
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    InkWell(
                      onTap: _loginWithKakao,
                      child: Image.asset(
                        'assets/images/kakao_login.png',
                        width: 300,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
