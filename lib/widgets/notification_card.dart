// /lib/widgets/notification_card.dart

import 'package:flutter/material.dart';
import 'package:alarmshare/services/firestore_service.dart';

class NotificationCard extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  NotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.0, // Increased height for better visibility
      child: StreamBuilder<List<String>>(
        stream: _firestoreService.getNotifications(),
        builder: (context, snapshot) {
          // Print the status of the connection and the data state
          debugPrint('Connection state: ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Waiting for data...');
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            debugPrint('Error: ${snapshot.error}');
            return const Center(
              child: Text('Error loading notifications'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('No data or notifications available');
            return const Center(
              child: Text('No notifications available'),
            );
          } else {
            List<String> notifications = snapshot.data!;
            // Print the fetched notifications for debugging
            debugPrint('Fetched notifications: $notifications');
            return PageView.builder(
              itemCount: notifications.length,
              controller: PageController(viewportFraction: 0.9),
              scrollDirection: Axis.horizontal, // Ensures horizontal scrolling
              itemBuilder: (context, index) {
                debugPrint(
                    'Displaying notification at index $index: ${notifications[index]}');
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 10.0),
                  color: Colors.purple[700],
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        notifications[index],
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
