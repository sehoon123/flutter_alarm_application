import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmRingScreen extends StatefulWidget {
  final int alarmId;
  final bool isWakeUp;
  final int snoozeDuration;

  const AlarmRingScreen({
    super.key,
    required this.alarmId,
    required this.isWakeUp,
    required this.snoozeDuration,
  });

  @override
  _AlarmRingScreenState createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  late Timer failSafeTimer;

  @override
  void initState() {
    super.initState();

    // Set window flags to show over lock screen
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setLockScreenFlags();
      });
    }

    // Start fail-safe timer
    failSafeTimer = Timer(const Duration(minutes: 5), () {
      // Automatically snooze the alarm
      onSnooze();
    });
  }

  void _setLockScreenFlags() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ));
    }
  }

  @override
  void dispose() {
    failSafeTimer.cancel();
    if (Platform.isAndroid) {
      // Reset system UI overlays
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void onSnooze() {
    Alarm.stop(widget.alarmId);
    DateTime snoozeTime = DateTime.now().add(
      Duration(minutes: widget.snoozeDuration),
    );
    final alarmSettings = AlarmSettings(
      id: widget.alarmId,
      dateTime: snoozeTime,
      assetAudioPath: 'assets/sounds/marimba.mp3', // Adjust as needed
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      // androidFullScreenIntent: true, // Ensure this is set
      notificationSettings: NotificationSettings(
        title: widget.isWakeUp ? '기상 알람 스누즈' : '취침 알람 스누즈',
        body: '스누즈 시간이 되었습니다!',
      ),
    );
    Alarm.set(alarmSettings: alarmSettings);
    Navigator.pop(context);
  }

  void onStop() {
    Alarm.stop(widget.alarmId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make this screen full-screen
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Detect a left-to-right swipe to stop the alarm
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            onStop();
          }
        },
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.grey],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isWakeUp ? 'Alarm' : 'Bedtime',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    TimeOfDay.now().format(context),
                    style: const TextStyle(
                      fontSize: 80,
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Snooze Button
                  ElevatedButton(
                    onPressed: onSnooze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text(
                      'Snooze',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
              // Slide to Stop at the bottom
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Swipe to Stop Alarm',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 0) {
                          onStop();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 30,
                            ),
                            Text(
                              ' Slide to Stop ',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
