// /lib/screens/alarm_ring_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fluttertoast/fluttertoast.dart'; // For toast messages

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
  int _alarmCoinsEarnedToday = 0;
  late Future<void> _coinsLoadFuture;

  @override
  void initState() {
    super.initState();
    _coinsLoadFuture = _loadAlarmCoinsEarnedToday();

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

  Future<void> _loadAlarmCoinsEarnedToday() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastDate = prefs.getString('lastAlarmCoinEarnDate') ?? '';
    if (lastDate != today) {
      // Reset count for new day
      await prefs.setInt('alarmCoinsEarnedToday', 0);
      await prefs.setString('lastAlarmCoinEarnDate', today);
      setState(() {
        _alarmCoinsEarnedToday = 0;
      });
    } else {
      // Load existing count
      int coinsEarned = prefs.getInt('alarmCoinsEarnedToday') ?? 0;
      setState(() {
        _alarmCoinsEarnedToday = coinsEarned;
      });
    }
  }

  Future<void> _incrementAlarmCoinsEarnedToday() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmCoinsEarnedToday += 1;
    });
    await prefs.setInt('alarmCoinsEarnedToday', _alarmCoinsEarnedToday);
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
      // androidFullScreenIntent: true, // Ensure this is set if needed
      notificationSettings: NotificationSettings(
        title: widget.isWakeUp ? '기상 알람 스누즈' : '취침 알람 스누즈',
        body: '스누즈 시간이 되었습니다!',
      ),
    );
    Alarm.set(alarmSettings: alarmSettings);
    Navigator.pop(context);
  }

  void onStop() async {
    Alarm.stop(widget.alarmId);

    // Wait for _loadAlarmCoinsEarnedToday() to complete
    await _coinsLoadFuture;

    // Check if the user can watch an ad
    if (_alarmCoinsEarnedToday < 2) {
      // Show the rewarded ad
      _loadAndShowRewardedAd();
    } else {
      // Show alert if the user has reached the daily limit
      _showMaxRewardAlert();
      // Do not call Navigator.pop(context) here
    }
  }

  void _loadAndShowRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test Ad Unit ID (Android)
          : 'ca-app-pub-3940256099942544/1712485313', // Test Ad Unit ID (iOS)
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              Navigator.pop(context);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              Navigator.pop(context);
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
              await _incrementAlarmCoinsEarnedToday();
              await _rewardUserViaAlarm();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _rewardUserViaAlarm() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        DocumentReference userDoc = FirebaseFirestore.instance
            .collection('user_collection')
            .doc(userId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          int currentCoins = snapshot['coins'] ?? 0;
          int currentAdCoupons = snapshot['adCoupons'] ?? 0;
          transaction.update(userDoc, {
            'coins': currentCoins + 1,
            'adCoupons': currentAdCoupons + 3,
          });
          debugPrint('User rewarded with 1 coin and 3 ad coupons.');
        });

        // Show toast notification
        Fluttertoast.showToast(
          msg: "코인이 1개와 광고 쿠폰 3개가 지급되었습니다!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        debugPrint('No user is currently signed in.');
      }
    } catch (e) {
      debugPrint('Failed to reward user: $e');
    }
  }

  // Show alert when user reaches daily reward limit
  void _showMaxRewardAlert() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('보상 한도 도달'),
        content: const Text('오늘은 더 이상 보상을 받을 수 없습니다. 내일 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close the dialog
              Navigator.pop(context); // Close the AlarmRingScreen
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make this screen full-screen
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              // Detect a left-to-right swipe to stop the alarm
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 0) {
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
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
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
        ],
      ),
    );
  }
}
