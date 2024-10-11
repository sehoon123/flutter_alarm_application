// /lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarmshare/screens/home_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear saved alarms
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.clear();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Alarm.init();

  await printAllUsersData();

  runApp(const MyApp());
}

// Add this function
Future<void> printAllUsersData() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('user_collection').get();
    
    debugPrint('Total users: ${querySnapshot.size}');
    
    for (var doc in querySnapshot.docs) {
      debugPrint('User ID: ${doc.id}');
      debugPrint('User Data: ${doc.data()}');
      debugPrint('-------------------');
    }
  } catch (e) {
    debugPrint('Error fetching users data: $e');
  }
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
