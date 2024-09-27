import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final List<String> notifications = [
    '2023년 10월 2주차 응모 마감까지 00시간 00분 00초',
    '새로운 프로모션이 시작되었습니다!',
    '업데이트를 확인하세요!',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      child: PageView.builder(
        itemCount: notifications.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                notifications[index],
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          );
        },
      ),
    );
  }
}
