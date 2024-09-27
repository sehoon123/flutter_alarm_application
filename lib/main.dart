import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_application/screens/home_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear saved alarms
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.clear();
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
