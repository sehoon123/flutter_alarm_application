import 'package:flutter/material.dart';
import 'package:flutter_alarm_application/screens/home_screen.dart';
import 'package:alarm/alarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Alarm App',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.purple,
        ),
        home: HomeScreen());
  }
}
