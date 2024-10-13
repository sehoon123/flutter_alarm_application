// /lib/main.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarmshare/screens/home_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  // Clear saved alarms
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.clear();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Alarm.init();

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
        home: const HomeScreen());
  }
}
