import 'dart:io';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_alarm_application/widgets/alarm_setting_widget.dart';
import 'package:flutter_alarm_application/widgets/notification_card.dart';
import 'package:flutter_alarm_application/widgets/review_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables to store alarm settings
  TimeOfDay wakeUpTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bedTime = TimeOfDay(hour: 22, minute: 0);

  bool wakeUpAlarmEnabled = false;
  bool bedTimeAlarmEnabled = false;

  List<String> wakeUpDays = [];
  List<String> bedTimeDays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.yellow),
                SizedBox(width: 4),
                Text('보유코인 7'),
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
            AlarmSettingWidget(
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
            // Bedtime Alarm Setting
            AlarmSettingWidget(
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
            // Review Invitation Section
            ReviewCard(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Assuming home is at index 1
        items: [
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
        assetAudioPath: 'assets/sounds/marimba.mp3',
        loopAudio: true,
        vibrate: true,
        volume: 0.8,
        fadeDuration: 3.0,
        notificationTitle: 'Wake-up Alarm',
        notificationBody: 'Time to wake up!',
        enableNotificationOnKill: Platform.isIOS,
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
        assetAudioPath: 'assets/sounds/marimba.mp3',
        loopAudio: false,
        vibrate: true,
        volume: 0.5,
        fadeDuration: 1.0,
        notificationTitle: 'Bedtime Reminder',
        notificationBody: 'Time to go to bed!',
        enableNotificationOnKill: Platform.isIOS,
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
