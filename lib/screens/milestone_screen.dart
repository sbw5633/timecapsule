// lib/screens/milestone_screen.dart
// 성장 기록 화면입니다. 아이의 성장 과정을 기록하고 관리합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../widgets/common_screen_layout.dart';
import '../utils/provider_initializer.dart';

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen({super.key});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> {
  @override
  void initState() {
    super.initState();
    // Provider 초기화
    ProviderInitializer.initializeProvidersOnInit(
      context,
      initializeFamily: true,
      // TODO: childId를 어떻게 가져올지 결정 필요
      // initializeMilestone: true,
      // milestoneChildId: childId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScreenLayout(
      title: '성장 기록',
      checkUserProvider: true,
      checkFamilyProvider: true,
      body: Consumer2<UserProvider, FamilyProvider>(
        builder: (context, userProvider, familyProvider, child) {
          if (userProvider.isLoading || familyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.user == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          if (familyProvider.family == null) {
            return const Center(child: Text('가족 정보를 찾을 수 없습니다.'));
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.child_care,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '성장 기록 기능 준비 중',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '곧 아이의 성장 과정을 기록할 수 있습니다!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
