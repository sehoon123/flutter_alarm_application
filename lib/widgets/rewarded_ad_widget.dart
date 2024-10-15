// /lib/widgets/rewarded_ad_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardedAdWidget extends StatefulWidget {
  final bool isWakeUp;
  final Function()? onAdDismissed;
  final Function()? onUserEarnedReward;

  const RewardedAdWidget({
    Key? key,
    required this.isWakeUp,
    this.onAdDismissed,
    this.onUserEarnedReward,
  }) : super(key: key);

  @override
  _RewardedAdWidgetState createState() => _RewardedAdWidgetState();
}

class _RewardedAdWidgetState extends State<RewardedAdWidget> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _rewardGiven = false;

  // 보상 횟수 및 날짜 추적 변수
  int _dailyRewardCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyRewardCount();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
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
              if (widget.onAdDismissed != null) {
                widget.onAdDismissed!();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              setState(() {
                _rewardedAd = null;
                _isAdLoaded = false;
              });
              if (widget.onAdDismissed != null) {
                widget.onAdDismissed!();
              }
            },
          );
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
          // Show the ad immediately after it's loaded
          _showRewardedAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isAdLoaded = false;
          });
          if (widget.onAdDismissed != null) {
            widget.onAdDismissed!();
          }
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
          if (widget.onUserEarnedReward != null) {
            widget.onUserEarnedReward!();
          }
        },
      );
    } else {
      // 광고가 로드되지 않았을 경우 바로 종료
      if (widget.onAdDismissed != null) {
        widget.onAdDismissed!();
      }
    }
  }

  Future<void> _rewardUser() async {
    if (_rewardGiven) return; // 이미 보상을 지급했으면 반환

    // 보상 횟수 증가 및 저장
    _incrementDailyRewardCount();

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

  @override
  Widget build(BuildContext context) {
    // Since the ad shows immediately, we can return an empty container or a loading indicator
    return const SizedBox.shrink();
  }
}
