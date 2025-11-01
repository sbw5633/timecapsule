// lib/utils/provider_initializer.dart
// Provider 초기화를 위한 유틸리티 클래스입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../providers/story_provider.dart';
import '../providers/milestone_provider.dart';

class ProviderInitializer {
  /// 화면에 필요한 Provider들을 초기화합니다.
  /// 
  /// [context] BuildContext
  /// [initializeFamily] FamilyProvider 초기화 여부 (기본: true)
  /// [initializeStory] StoryProvider 초기화 여부 (기본: false)
  /// [initializeMilestone] MilestoneProvider 초기화 여부 (기본: false)
  /// [milestoneChildId] MilestoneProvider 초기화 시 필요한 childId (기본: null)
  static void initializeProviders(
    BuildContext context, {
    bool initializeFamily = true,
    bool initializeStory = false,
    bool initializeMilestone = false,
    String? milestoneChildId,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.familyUid == null) {
      print('ProviderInitializer: familyUid가 null이어서 초기화하지 않음');
      return;
    }

    final familyUid = userProvider.familyUid!;
    print('ProviderInitializer: 초기화 시작 - familyUid: $familyUid');

    // FamilyProvider 초기화
    if (initializeFamily) {
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      familyProvider.initialize(familyUid);
      print('ProviderInitializer: FamilyProvider 초기화 완료');
    }

    // StoryProvider 초기화
    if (initializeStory) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      storyProvider.initialize(familyUid);
      print('ProviderInitializer: StoryProvider 초기화 완료');
    }

    // MilestoneProvider 초기화
    if (initializeMilestone && milestoneChildId != null) {
      final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
      milestoneProvider.initialize(familyUid, milestoneChildId);
      print('ProviderInitializer: MilestoneProvider 초기화 완료 - childId: $milestoneChildId');
    }
  }

  /// initState에서 호출하는 헬퍼 메서드
  /// PostFrameCallback으로 지연 호출하여 컨텍스트가 준비된 후 실행
  static void initializeProvidersOnInit(
    BuildContext context, {
    bool initializeFamily = true,
    bool initializeStory = false,
    bool initializeMilestone = false,
    String? milestoneChildId,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        initializeProviders(
          context,
          initializeFamily: initializeFamily,
          initializeStory: initializeStory,
          initializeMilestone: initializeMilestone,
          milestoneChildId: milestoneChildId,
        );
      }
    });
  }
}

