// lib/utils/route_config.dart
// 앱의 라우트 설정을 중앙에서 관리합니다.

import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/story_create_screen.dart';
import '../screens/story_detail_screen.dart';
import '../screens/moment_create_screen.dart';
import '../screens/history_book_screen.dart';
import '../screens/milestone_screen.dart';
import '../screens/parenting_info_screen.dart';
import '../screens/family_registration_screen.dart';
import '../screens/family_join_screen.dart';
import '../screens/profile_screen.dart';
import '../models/story_model.dart';

class RouteConfig {
  // 라우트 이름들을 상수로 정의
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String timeline = '/timeline';
  static const String createStory = '/createStory';
  static const String createMoment = '/createMoment';
  static const String storyDetail = '/storyDetail';
  static const String historyBook = '/historyBook';
  static const String milestone = '/milestone';
  static const String parentingInfo = '/parentingInfo';
  static const String familyRegistration = '/familyRegistration';
  static const String familyJoin = '/familyJoin';
  static const String profile = '/profile';

  // 라우트 생성 함수
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      auth: (context) => const AuthScreen(),
      timeline: (context) => const TimelineScreen(),
      createStory: (context) => const StoryCreateScreen(),
      createMoment: (context) => const MomentCreateScreen(),
      storyDetail: (context) {
        final story = ModalRoute.of(context)!.settings.arguments as StoryModel;
        return StoryDetailScreen(story: story);
      },
      historyBook: (context) => const HistoryBookScreen(),
      milestone: (context) => const MilestoneScreen(),
      parentingInfo: (context) => const ParentingInfoScreen(),
      familyRegistration: (context) => const FamilyRegistrationScreen(),
      familyJoin: (context) => const FamilyJoinScreen(),
      profile: (context) => const ProfileScreen(),
    };
  }
}
