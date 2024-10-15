// /lib/main.dart

import 'dart:async';

import 'package:alarmshare/screens/agreement_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarmshare/screens/home_screen.dart';
import 'package:alarmshare/screens/login_screen.dart'; // LoginScreen 경로 확인
import 'package:alarmshare/screens/auth_gate.dart'; // AuthGate 위젯 추가
import 'package:alarm/alarm.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();
  unawaited(MobileAds.instance.initialize());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Alarm.init();

  // Clear saved alarms
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: FlutterConfig.get('kakaoNativeAppKey'),
    javaScriptAppKey: FlutterConfig.get('kakaoJSAppKey'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
      ),
      home: const AuthGate(), // AuthGate를 초기 화면으로 설정
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginPage(),
        '/agreement': (context) =>
            const AgreementScreen(), // AgreementScreen이 있다면 추가
      },
    );
  }
}
