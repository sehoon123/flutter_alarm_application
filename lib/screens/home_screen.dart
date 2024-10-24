// /lib/screens/home_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert'; // For JSON encoding/decoding

import 'package:alarmshare/widgets/my_banner_ad_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarmshare/screens/alarm_ring_screen.dart';
import 'package:alarmshare/services/permission.dart';
import 'package:alarmshare/widgets/alarm_setting_widget.dart';
import 'package:alarmshare/widgets/notification_card.dart';
import 'package:alarmshare/widgets/review_card.dart';
import 'package:alarmshare/screens/alarm_detail_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  int userAdCoupons = 0;
  List<String> notifications = [];

  // Variables to store alarm settings
  TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);

  bool wakeUpAlarmEnabled = false;
  bool bedTimeAlarmEnabled = false;
  bool _isLoadingAd = false;

  List<String> wakeUpDays = [];
  List<String> bedTimeDays = [];

  // New variables for custom settings
  String wakeUpSound = 'marimba.mp3';
  bool wakeUpVibration = true;
  int wakeUpSnoozeDuration = 5;

  String bedTimeSound = 'marimba.mp3';
  bool bedTimeVibration = true;
  int bedTimeSnoozeDuration = 5;

  // Add this StreamSubscription
  StreamSubscription<DocumentSnapshot>? _userSubscription;

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

    // Start listening to Firestore changes
    _startListeningToUserDocument();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToUserDocument() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      _userSubscription = FirebaseFirestore.instance
          .collection('user_collection')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          int coins = snapshot.data()?['coins'] ?? 0;
          int adCoupons = snapshot.data()?['adCoupons'] ?? 0;
          setState(() {
            userCoins = coins;
            userAdCoupons = adCoupons;
          });
        }
      });
    }
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user is currently signed in.');
      return;
    }

    String userId = user.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('user_collection')
        .doc(userId)
        .get();
    int coins = userDoc['coins'] ?? 0;
    int adCoupons = userDoc['adCoupons'] ?? 0;
    setState(() {
      userCoins = coins;
      userAdCoupons = adCoupons;
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
        // androidFullScreenIntent: true, // Ensure this is set if needed
        notificationSettings: const NotificationSettings(
          title: '기상 알람',
          body: '일어날 시간입니다!',
        ),
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
          isWakeUp: alarmId < 200, // Adjust based on your ID logic
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

  void _triggerRewardedAd() async {
    if (userAdCoupons > 0 && !_isLoadingAd) {
      setState(() {
        _isLoadingAd = true;
      });
      await _decrementAdCoupons();
      _loadAndShowRewardedAd();
    } else {
      if (_isLoadingAd) {
        // Optionally, show a message that an ad is already loading
        Fluttertoast.showToast(
          msg: "광고가 이미 로딩 중입니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "광고 쿠폰이 없습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _decrementAdCoupons() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        DocumentReference userDoc = FirebaseFirestore.instance
            .collection('user_collection')
            .doc(userId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          int currentAdCoupons = snapshot['adCoupons'] ?? 0;
          if (currentAdCoupons > 0) {
            transaction.update(userDoc, {
              'adCoupons': currentAdCoupons - 1,
            });
          }
        });
      } else {
        debugPrint('No user is currently signed in.');
      }
    } catch (e) {
      debugPrint('Failed to decrement ad coupons: $e');
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
              setState(() {
                _isLoadingAd = false;
              });
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              setState(() {
                _isLoadingAd = false;
              });
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
              await _rewardUserViaAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          setState(() {
            _isLoadingAd = false;
          });
          Fluttertoast.showToast(
            msg: "광고를 불러오는 데 실패했습니다.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        },
      ),
    );
  }

  Future<void> _rewardUserViaAd() async {
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
          transaction.update(userDoc, {
            'coins': currentCoins + 1,
          });
        });

        // Show toast notification
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
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    // Ensure the user is authenticated
    if (user == null) {
      // You might want to navigate to the login screen or show a message
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    String userId = user.uid;

    // Firestore에서 사용자의 문서를 실시간으로 스트림 리스닝
    Stream<DocumentSnapshot> userStream = FirebaseFirestore.instance
        .collection('user_collection')
        .doc(userId)
        .snapshots();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('홈'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.yellow),
                    const SizedBox(width: 4),
                    Text('보유코인 $userCoins / 쿠폰 $userAdCoupons'),
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
                // Row for Review Invitation Section and '광고 보기' Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: ReviewCard(), // Adjust flex as needed
                      ),
                      const SizedBox(
                          width: 16), // Space between the two widgets
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: (userAdCoupons > 0 && !_isLoadingAd)
                              ? _triggerRewardedAd
                              : null,
                          child: AbsorbPointer(
                            absorbing:
                                _isLoadingAd, // Prevents interaction when loading
                            child: Card(
                              margin: const EdgeInsets.all(16.0),
                              color: userAdCoupons > 0
                                  ? Colors.grey[800]
                                  : Colors.grey[400],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: _isLoadingAd
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : Text(
                                          '광고 보기 ($userAdCoupons개 남음)',
                                          style: const TextStyle(
                                              fontSize: 20.0,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                MyBannerAdWidget(),
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
        ),
      ],
    );
  }

  // ... existing methods ...
}
