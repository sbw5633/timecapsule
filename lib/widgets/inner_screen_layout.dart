// lib/widgets/inner_screen_layout.dart
// 내부 탭 화면(예: 우리 이야기, 소중한 순간들)용 공용 레이아웃입니다.
// AppBar와 BottomNavigationBar 없이 body만 표시합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../providers/story_provider.dart';
import '../providers/milestone_provider.dart';

class InnerScreenLayout extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool checkUserProvider;
  final bool checkFamilyProvider;
  final bool checkStoryProvider;
  final bool checkMilestoneProvider;
  final Color? backgroundColor;

  const InnerScreenLayout({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.checkUserProvider = false,
    this.checkFamilyProvider = false,
    this.checkStoryProvider = false,
    this.checkMilestoneProvider = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: _buildBodyWithLoadingCheck(context),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBodyWithLoadingCheck(BuildContext context) {
    if (checkUserProvider) {
      return Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return _buildLoadingWidget('사용자 정보를 불러오는 중...');
          }
          
          if (userProvider.user == null) {
            return _buildLoginRequiredWidget(context);
          }
          
          if (userProvider.familyUid == null) {
            return _buildFamilyRequiredWidget(context);
          }
          
          return _buildOtherProvidersCheck(context, userProvider);
        },
      );
    }
    
    return body;
  }

  Widget _buildOtherProvidersCheck(BuildContext context, UserProvider userProvider) {
    if (checkFamilyProvider) {
      return Consumer<FamilyProvider>(
        builder: (context, familyProvider, child) {
          if (familyProvider.isLoading) {
            return _buildLoadingWidget('가족 정보를 불러오는 중...');
          }
          
          if (familyProvider.family == null) {
            return _buildEmptyStateWidget('가족 정보를 찾을 수 없습니다.');
          }
          
          return _buildStoryAndMilestoneCheck(context, userProvider);
        },
      );
    }
    
    return body;
  }

  Widget _buildStoryAndMilestoneCheck(BuildContext context, UserProvider userProvider) {
    if (checkStoryProvider) {
      return Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.isLoading) {
            return _buildLoadingWidget('스토리를 불러오는 중...');
          }
          
          return _buildMilestoneCheck(context, userProvider);
        },
      );
    }
    
    return body;
  }

  Widget _buildMilestoneCheck(BuildContext context, UserProvider userProvider) {
    if (checkMilestoneProvider) {
      return Consumer<MilestoneProvider>(
        builder: (context, milestoneProvider, child) {
          if (milestoneProvider.isLoading) {
            return _buildLoadingWidget('성장 기록을 불러오는 중...');
          }
          
          return body;
        },
      );
    }
    
    return body;
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '로그인이 필요합니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '가족과 함께 특별한 순간을 기록하려면\n로그인해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyRequiredWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.family_restroom,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '가족 등록이 필요합니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '가족과 함께 특별한 순간을 기록하려면\n가족을 등록하거나 참여해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

