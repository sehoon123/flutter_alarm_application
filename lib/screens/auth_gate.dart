// /lib/screens/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'agreement_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 연결 상태 확인
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 인증된 사용자
        if (snapshot.hasData && snapshot.data != null) {
          // Fetch user's agreement status
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('user_collection')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                Map<String, dynamic> userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                bool agreement = userData['agreement'] ?? false;
                debugPrint('AuthGate agreement status: $agreement');

                if (agreement) {
                  return const HomeScreen();
                } else {
                  return const AgreementScreen();
                }
              } else {
                // User data not found, navigate to AgreementScreen
                return const AgreementScreen();
              }
            },
          );
        }

        // 인증되지 않은 사용자
        return const LoginPage();
      },
    );
  }
}
