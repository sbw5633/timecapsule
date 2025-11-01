// lib/widgets/common_screen_layout.dart
// 모든 화면에서 공통으로 사용할 레이아웃 위젯입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../providers/story_provider.dart';
import '../providers/milestone_provider.dart';
import 'common_bottom_navigation_bar.dart';

class CommonScreenLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool showBottomNavigationBar;
  final bool showAppBar;
  final bool checkUserProvider;
  final bool checkFamilyProvider;
  final bool checkStoryProvider;
  final bool checkMilestoneProvider;
  final Color? backgroundColor;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final bool extendBodyBehindAppBar;
  final Widget? drawer;
  final Widget? endDrawer;

  const CommonScreenLayout({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.floatingActionButton,
    this.bottom,
    this.showBottomNavigationBar = true,
    this.showAppBar = true,
    this.checkUserProvider = false,
    this.checkFamilyProvider = false,
    this.checkStoryProvider = false,
    this.checkMilestoneProvider = false,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.extendBodyBehindAppBar = false,
    this.drawer,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: drawer,
      endDrawer: endDrawer,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              centerTitle: true,
              backgroundColor: appBarBackgroundColor ?? AppColors.primary,
              foregroundColor: appBarForegroundColor ?? Colors.white,
              elevation: 0,
              actions: [
                // 프로필 아이콘 (기본)
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.user != null) {
                      return IconButton(
                        icon: const Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // 커스텀 actions 추가
                if (appBarActions != null) ...appBarActions!,
              ],
              bottom: bottom,
            )
          : null,
      body: _buildBodyWithLoadingCheck(context),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigationBar
          ? CommonBottomNavigationBar(
              currentIndex: _getCurrentIndex(context),
              onTap: (index) => _handleNavigation(context, index),
            )
          : null,
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
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
              child: const Text('로그인하기', style: TextStyle(color: AppColors.white)),
            ),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/familyRegistration'),
                child: const Text('가족 만들기'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/familyJoin'),
                child: const Text('가족 참여하기'),
              ),
            ],
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

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/timeline':
        return 0;
      case '/historyBook':
        return 1;
      case '/milestone':
        return 2;
      case '/parentingInfo':
        return 3;
      default:
        return 0;
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/timeline') {
          Navigator.pushReplacementNamed(context, '/timeline');
        }
        break;
      case 1:
        if (ModalRoute.of(context)?.settings.name != '/historyBook') {
          Navigator.pushReplacementNamed(context, '/historyBook');
        }
        break;
      case 2:
        if (ModalRoute.of(context)?.settings.name != '/milestone') {
          Navigator.pushReplacementNamed(context, '/milestone');
        }
        break;
      case 3:
        if (ModalRoute.of(context)?.settings.name != '/parentingInfo') {
          Navigator.pushReplacementNamed(context, '/parentingInfo');
        }
        break;
    }
  }
}
