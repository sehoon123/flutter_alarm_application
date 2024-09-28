import 'dart:io';
import 'dart:convert'; // For JSON encoding/decoding

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarmshare/screens/alarm_ring_screen.dart';
import 'package:alarmshare/services/permission.dart';
import 'package:alarmshare/widgets/alarm_setting_widget.dart';
import 'package:alarmshare/widgets/notification_card.dart';
import 'package:alarmshare/widgets/review_card.dart';
import 'package:alarmshare/screens/alarm_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarmshare/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int userCoins = 0;
  List<String> notifications = [];

  // Variables to store alarm settings
  TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);

  bool wakeUpAlarmEnabled = false;
  bool bedTimeAlarmEnabled = false;

  List<String> wakeUpDays = [];
  List<String> bedTimeDays = [];

  // New variables for custom settings
  String wakeUpSound = 'marimba.mp3';
  bool wakeUpVibration = true;
  int wakeUpSnoozeDuration = 5;

  String bedTimeSound = 'marimba.mp3';
  bool bedTimeVibration = true;
  int bedTimeSnoozeDuration = 5;

  @override
  void initState() {
    super.initState();
    AlarmPermissions.checkNotificationPermission();
    if (Alarm.android) {
      AlarmPermissions.checkAndroidScheduleExactAlarmPermission();
    }
    loadPreferences();
    Alarm.ringStream.stream.listen((alarmSettings) {
      onAlarmRing(alarmSettings);
    });
    _loadUserData();
  }

  void _loadUserData() async {
    // For this example, we're using a hardcoded user ID. In a real app, you'd get this from Firebase Auth.
    String userId = 'example_user_id';
    int coins = await _firestoreService.getUserCoins(userId);
    setState(() {
      userCoins = coins;
    });
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load Wake-up Alarm Settings
      String? wakeUpAlarmJson = prefs.getString('wakeUpAlarmSettings');
      if (wakeUpAlarmJson != null) {
        Map<String, dynamic> wakeUpAlarmMap = jsonDecode(wakeUpAlarmJson);
        wakeUpTime = TimeOfDay(
            hour: wakeUpAlarmMap['hour'], minute: wakeUpAlarmMap['minute']);
        wakeUpDays = List<String>.from(wakeUpAlarmMap['days']);
        wakeUpSound = wakeUpAlarmMap['sound'];
        wakeUpVibration = wakeUpAlarmMap['vibration'];
        wakeUpSnoozeDuration = wakeUpAlarmMap['snoozeDuration'];
        wakeUpAlarmEnabled = wakeUpAlarmMap['enabled'];
      }

      // Load Bedtime Alarm Settings
      String? bedTimeAlarmJson = prefs.getString('bedTimeAlarmSettings');
      if (bedTimeAlarmJson != null) {
        Map<String, dynamic> bedTimeAlarmMap = jsonDecode(bedTimeAlarmJson);
        bedTime = TimeOfDay(
            hour: bedTimeAlarmMap['hour'], minute: bedTimeAlarmMap['minute']);
        bedTimeDays = List<String>.from(bedTimeAlarmMap['days']);
        bedTimeSound = bedTimeAlarmMap['sound'];
        bedTimeVibration = bedTimeAlarmMap['vibration'];
        bedTimeSnoozeDuration = bedTimeAlarmMap['snoozeDuration'];
        bedTimeAlarmEnabled = bedTimeAlarmMap['enabled'];
      }
    });

    // After loading, set the alarms if they are enabled
    if (wakeUpAlarmEnabled) {
      setWakeUpAlarms();
    }
    if (bedTimeAlarmEnabled) {
      setBedTimeAlarms();
    }
  }

  void savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save Wake-up Alarm Settings
    Map<String, dynamic> wakeUpAlarmMap = {
      'hour': wakeUpTime.hour,
      'minute': wakeUpTime.minute,
      'days': wakeUpDays,
      'sound': wakeUpSound,
      'vibration': wakeUpVibration,
      'snoozeDuration': wakeUpSnoozeDuration,
      'enabled': wakeUpAlarmEnabled,
    };
    prefs.setString('wakeUpAlarmSettings', jsonEncode(wakeUpAlarmMap));

    // Save Bedtime Alarm Settings
    Map<String, dynamic> bedTimeAlarmMap = {
      'hour': bedTime.hour,
      'minute': bedTime.minute,
      'days': bedTimeDays,
      'sound': bedTimeSound,
      'vibration': bedTimeVibration,
      'snoozeDuration': bedTimeSnoozeDuration,
      'enabled': bedTimeAlarmEnabled,
    };
    prefs.setString('bedTimeAlarmSettings', jsonEncode(bedTimeAlarmMap));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellow),
                const SizedBox(width: 4),
                Text('보유코인 $userCoins'),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notification area
            NotificationCard(),
            // Wake-up Alarm Setting
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AlarmDetailScreen(
                            alarmType: '기상',
                            initialTime: wakeUpTime,
                            initialDays: wakeUpDays,
                            initialSound: wakeUpSound,
                            initialVibration: wakeUpVibration,
                            initialSnoozeDuration: wakeUpSnoozeDuration,
                            onSave: (time, days, sound, vibration, snooze) {
                              setState(() {
                                wakeUpTime = time;
                                wakeUpDays = days;
                                wakeUpSound = sound;
                                wakeUpVibration = vibration;
                                wakeUpSnoozeDuration = snooze;
                                savePreferences();
                                if (wakeUpAlarmEnabled) {
                                  setWakeUpAlarms();
                                }
                              });
                            },
                          )),
                );
              },
              child: AlarmSettingWidget(
                title: '기상 알람 설정',
                time: wakeUpTime,
                isEnabled: wakeUpAlarmEnabled,
                selectedDays: wakeUpDays,
                onTimeChanged: (newTime) {
                  setState(() {
                    wakeUpTime = newTime;
                  });
                },
                onToggleChanged: (newValue) {
                  setState(() {
                    wakeUpAlarmEnabled = newValue;
                    savePreferences();
                    if (newValue) {
                      // Set the wake-up alarm
                      setWakeUpAlarms();
                    } else {
                      // Stop all wake-up alarms
                      stopAlarms(isWakeUp: true);
                    }
                  });
                },
                onDaysChanged: (newDays) {
                  setState(() {
                    wakeUpDays = newDays;
                    if (wakeUpAlarmEnabled) {
                      setWakeUpAlarms();
                    }
                  });
                },
              ),
            ),
            // Bedtime Alarm Setting
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AlarmDetailScreen(
                            alarmType: '취침',
                            initialTime: bedTime,
                            initialDays: bedTimeDays,
                            initialSound: bedTimeSound,
                            initialVibration: bedTimeVibration,
                            initialSnoozeDuration: bedTimeSnoozeDuration,
                            onSave: (time, days, sound, vibration, snooze) {
                              setState(() {
                                bedTime = time;
                                bedTimeDays = days;
                                bedTimeSound = sound;
                                bedTimeVibration = vibration;
                                bedTimeSnoozeDuration = snooze;
                                savePreferences();
                                if (bedTimeAlarmEnabled) {
                                  setBedTimeAlarms();
                                }
                              });
                            },
                          )),
                );
              },
              child: AlarmSettingWidget(
                title: '취침 알람 설정',
                time: bedTime,
                isEnabled: bedTimeAlarmEnabled,
                selectedDays: bedTimeDays,
                onTimeChanged: (newTime) {
                  setState(() {
                    bedTime = newTime;
                  });
                },
                onToggleChanged: (newValue) {
                  setState(() {
                    bedTimeAlarmEnabled = newValue;
                    savePreferences();
                    if (newValue) {
                      // Set the bedtime alarms
                      setBedTimeAlarms();
                    } else {
                      // Stop all bedtime alarms
                      stopAlarms(isWakeUp: false);
                    }
                  });
                },
                onDaysChanged: (newDays) {
                  setState(() {
                    bedTimeDays = newDays;
                    if (bedTimeAlarmEnabled) {
                      setBedTimeAlarms();
                    }
                  });
                },
              ),
            ),
            // Review Invitation Section
            ReviewCard(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Assuming home is at index 1
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.purple),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }

  void setWakeUpAlarms() {
    // Stop existing alarms
    stopAlarms(isWakeUp: true);
    // For each selected day, schedule an alarm
    for (String day in wakeUpDays) {
      DateTime alarmDateTime = getNextDateTimeForDay(wakeUpTime, day);
      int alarmId = getAlarmId(day, isWakeUp: true);
      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: alarmDateTime,
        assetAudioPath: 'assets/sounds/$wakeUpSound',
        loopAudio: true,
        vibrate: wakeUpVibration,
        volume: 0.8,
        fadeDuration: 3.0,
        notificationSettings: const NotificationSettings(
          title: '기상 알람',
          body: '일어날 시간입니다!',
        ),
        // androidFullScreenIntent: true,
      );
      Alarm.set(alarmSettings: alarmSettings);
    }
  }

  void setBedTimeAlarms() {
    // Stop existing alarms
    stopAlarms(isWakeUp: false);
    // For each selected day, schedule an alarm
    for (String day in bedTimeDays) {
      DateTime alarmDateTime = getNextDateTimeForDay(bedTime, day);
      int alarmId = getAlarmId(day, isWakeUp: false);
      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: alarmDateTime,
        assetAudioPath: 'assets/sounds/$bedTimeSound',
        loopAudio: true,
        vibrate: bedTimeVibration,
        volume: 0.8,
        fadeDuration: 1.0,
        notificationSettings: const NotificationSettings(
          title: '취침 알람',
          body: '취침 시간입니다!',
        ),
        // androidFullScreenIntent: true,
      );
      Alarm.set(alarmSettings: alarmSettings);
    }
  }

  void stopAlarms({required bool isWakeUp}) {
    List<String> days = isWakeUp ? wakeUpDays : bedTimeDays;
    for (String day in days) {
      int alarmId = getAlarmId(day, isWakeUp: isWakeUp);
      Alarm.stop(alarmId);
    }
  }

  void onAlarmRing(AlarmSettings alarmSettings) {
    int alarmId = alarmSettings.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmRingScreen(
          alarmId: alarmId,
          isWakeUp: alarmId < 200,
          snoozeDuration:
              alarmId < 200 ? wakeUpSnoozeDuration : bedTimeSnoozeDuration,
        ),
      ),
    );
  }

  DateTime getNextDateTimeForDay(TimeOfDay timeOfDay, String day) {
    int weekday = getWeekdayFromKorean(day);
    DateTime now = DateTime.now();
    DateTime date = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    int daysUntilNextOccurrence = (weekday - date.weekday + 7) % 7;
    if (daysUntilNextOccurrence == 0 && date.isBefore(now)) {
      daysUntilNextOccurrence = 7;
    }
    return date.add(Duration(days: daysUntilNextOccurrence));
  }

  int getWeekdayFromKorean(String day) {
    switch (day) {
      case '월':
        return DateTime.monday;
      case '화':
        return DateTime.tuesday;
      case '수':
        return DateTime.wednesday;
      case '목':
        return DateTime.thursday;
      case '금':
        return DateTime.friday;
      case '토':
        return DateTime.saturday;
      case '일':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  int getAlarmId(String day, {required bool isWakeUp}) {
    int baseId = isWakeUp ? 100 : 200;
    int dayOffset = getWeekdayFromKorean(day) % 7;
    return baseId + dayOffset;
  }
}
