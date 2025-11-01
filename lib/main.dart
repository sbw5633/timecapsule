// lib/main.dart
// 앱의 진입점입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/family_provider.dart';
import 'providers/story_provider.dart';
import 'providers/milestone_provider.dart';
import 'utils/route_config.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (중복 초기화 방지)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 이미 초기화된 경우 무시
    print('Firebase already initialized: $e');
  }
  
  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY', // 실제 키로 교체 필요
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
      ],
      child: MaterialApp(
        title: 'Time Capsule',
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: RouteConfig.getRoutes(),
      ),
    );
  }
}
