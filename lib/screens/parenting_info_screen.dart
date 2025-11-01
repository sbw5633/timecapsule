// lib/screens/parenting_info_screen.dart
// 육아 정보 화면입니다.

import 'package:flutter/material.dart';
import '../widgets/common_screen_layout.dart';
import '../utils/constants.dart';

class ParentingInfoScreen extends StatefulWidget {
  const ParentingInfoScreen({super.key});

  @override
  State<ParentingInfoScreen> createState() => _ParentingInfoScreenState();
}

class _ParentingInfoScreenState extends State<ParentingInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return CommonScreenLayout(
      title: '육아 정보',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '육아 정보',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '각종 육아 정보와 육아에 필요한 쇼핑 등을\n안내해드립니다.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

