// lib/screens/splash_screen.dart
// 앱 시작 시 로딩 화면입니다. 인증 상태를 확인하고 다음 화면으로 이동합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 2)); // 2초간 스플래시 화면 표시
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // Firebase Auth에 사용자가 로그인되어 있음
      // UserProvider가 자동으로 사용자 데이터를 로드하므로
      // 로딩이 완료될 때까지 기다립니다.
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // UserProvider가 로딩을 완료할 때까지 기다림
      while (userProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      if (userProvider.user != null) {
        // 사용자 정보가 로드되었고 familyUid가 있으면 타임라인으로
        if (userProvider.familyUid != null) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/timeline');
          }
        } else {
          // familyUid가 없으면 가족 등록/조인 선택 화면으로
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/familyRegistration');
          }
        }
      } else {
        // 사용자 정보 로드 실패
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } else {
      // 로그인되지 않은 상태
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 또는 앱 아이콘
            const Icon(
              Icons.family_restroom,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Time Capsule',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '가족과 함께 특별한 순간을 기록하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

