// /lib/screens/agreement_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _isAgreed = false;
  bool _isLoading = false;

  Future<void> _updateAgreement() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('user_collection').doc(user.uid).update({
        'agreement': _isAgreed,
      });

      if (_isAgreed) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 사용자가 동의하지 않은 경우 필요한 처리를 추가
        // 예: 앱 종료, 재시도 요청 등
        // 여기서는 단순히 로그아웃 처리
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Agreement update failed: $e');
      // 에러 처리 (예: 토스트 메시지)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동의 처리에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용 약관 동의'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '이용 약관에 동의해주세요.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text('이용 약관에 동의합니다.'),
              value: _isAgreed,
              onChanged: (value) {
                setState(() {
                  _isAgreed = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isAgreed ? _updateAgreement : null,
                    child: const Text('동의하기'),
                  ),
          ],
        ),
      ),
    );
  }
}
