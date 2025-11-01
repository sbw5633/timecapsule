// lib/widgets/common_bottom_navigation_bar.dart
// 모든 화면에서 공통으로 사용할 BottomNavigationBar 위젯입니다.

import 'package:flutter/material.dart';
import '../utils/navigation_config.dart';
import '../utils/constants.dart';

class CommonBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CommonBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: _buildCustomItems(),
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.6),
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      onTap: onTap,
    );
  }

  List<BottomNavigationBarItem> _buildCustomItems() {
    final items = NavigationConfig.items;
    
    return items.map((item) {
      
      return BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            size:  20,
            color: AppColors.primaryLight.withValues(alpha: 0.9),
          ),
        ),
        activeIcon: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            item.icon,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        label: item.label,
      );
    }).toList();
  }
}
