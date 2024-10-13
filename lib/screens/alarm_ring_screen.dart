// /lib/screens/alarm_ring_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // 날짜 형식 처리를 위한 패키지
import 'package:fluttertoast/fluttertoast.dart'; // 토스트 메시지용 패키지

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
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _rewardGiven = false;

  // 보상 횟수 및 날짜 추적 변수
  int _dailyRewardCount = 0;
  String _lastRewardDate = '';

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

    // Load rewarded ad
    _loadRewardedAd();

    // Load daily reward count
    _loadDailyRewardCount();
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
    _rewardedAd?.dispose();
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

  void onStop() async {
    Alarm.stop(widget.alarmId);

    // 광고 시청 가능 여부 확인
    if (_canWatchAd()) {
      if (_isAdLoaded) {
        // 보상형 광고 표시
        _showRewardedAd();
      } else {
        // 광고가 로드되지 않았을 경우 바로 화면 종료
        Navigator.pop(context);
      }
    } else {
      // 하루에 2번만 보상을 받을 수 있으므로 알림 표시
      _showMaxRewardAlert();
      // 화면 종료
      Navigator.pop(context);
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // 테스트용 Ad Unit ID
          : 'ca-app-pub-3940256099942544/1712485313',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              setState(() {
                _rewardedAd = null;
                _isAdLoaded = false;
              });
              // 광고를 이미 시청했으므로 화면 종료
              Navigator.pop(context);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              setState(() {
                _rewardedAd = null;
                _isAdLoaded = false;
              });
              Navigator.pop(context);
            },
          );
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // 사용자가 광고를 끝까지 시청함
          _rewardUser();
        },
      );
    } else {
      // 광고가 로드되지 않았을 경우 바로 화면 종료
      Navigator.pop(context);
    }
  }

  Future<void> _rewardUser() async {
    if (_rewardGiven) return; // 이미 보상을 지급했으면 반환

    // 보상 횟수 증가 및 저장
    _incrementDailyRewardCount();

    // Firebase에서 코인 증가 로직 구현
    try {
      // Firebase Auth에서 현재 사용자 가져오기
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('user_collection').doc(userId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          int currentCoins = snapshot['coins'] ?? 0;
          debugPrint('current coins = $currentCoins');
          transaction.update(userDoc, {'coins': currentCoins + 1});
          debugPrint('User rewarded with 1 coin.');
        });

        // 보상 지급 완료 알림 (토스트 메시지)
        Fluttertoast.showToast(
          msg: "코인이 1개 지급되었습니다!",
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

    // 보상 지급 완료 플래그 설정
    setState(() {
      _rewardGiven = true;
    });
  }

  // 보상 횟수 로드
  void _loadDailyRewardCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastDate = prefs.getString(_getLastRewardDateKey()) ?? '';

    if (lastDate != today) {
      // 새로운 날이므로 보상 횟수 초기화
      await prefs.setInt(_getDailyRewardCountKey(), 0);
      await prefs.setString(_getLastRewardDateKey(), today);
      setState(() {
        _dailyRewardCount = 0;
      });
    } else {
      // 이전에 저장된 보상 횟수 로드
      setState(() {
        _dailyRewardCount = prefs.getInt(_getDailyRewardCountKey()) ?? 0;
      });
    }
  }

  // 보상 횟수 증가 및 저장
  void _incrementDailyRewardCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyRewardCount += 1;
    });
    await prefs.setInt(_getDailyRewardCountKey(), _dailyRewardCount);
  }

  // 보상 횟수 키 생성
  String _getDailyRewardCountKey() {
    return widget.isWakeUp ? 'dailyRewardCountWakeUp' : 'dailyRewardCountBedTime';
  }

  // 마지막 보상 날짜 키 생성
  String _getLastRewardDateKey() {
    return widget.isWakeUp ? 'lastRewardDateWakeUp' : 'lastRewardDateBedTime';
  }

  // 하루에 2번만 보상을 받을 수 있는지 확인
  bool _canWatchAd() {
    return _dailyRewardCount < 2;
  }

  // 보상 횟수 초과 시 알림 표시
  void _showMaxRewardAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보상 한도 도달'),
        content: const Text('오늘은 더 이상 보상을 받을 수 없습니다. 내일 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
