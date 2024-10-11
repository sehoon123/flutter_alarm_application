// /lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getUserCoins(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('user_collection').doc(userId).get();
      return userDoc['coins'] ?? 0;
    } catch (e) {
      debugPrint('Error getting user coins: $e');
      return 0;
    }
  }

  Stream<List<String>> getNotifications() {
    return _firestore
        .collection('notification_collection')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc['message'] as String).toList();
    });
  }
}
