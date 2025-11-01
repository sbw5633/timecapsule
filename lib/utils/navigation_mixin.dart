// lib/utils/navigation_mixin.dart
// 화면 간 네비게이션을 쉽게 처리할 수 있는 Mixin입니다.

import 'package:flutter/material.dart';
import 'navigation_config.dart';

mixin NavigationMixin<T extends StatefulWidget> on State<T> {
  // 현재 화면의 인덱스 가져오기
  int get currentIndex => NavigationConfig.getCurrentIndex(ModalRoute.of(context)?.settings.name ?? '');

  // 네비게이션 처리
  void handleNavigation(int index) {
    final item = NavigationConfig.getItemByIndex(index);
    if (item != null && item.index != currentIndex) {
      Navigator.pushReplacementNamed(context, item.route);
    }
  }

  // 특정 라우트로 이동
  void navigateToRoute(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  // 현재 라우트 확인
  bool isCurrentRoute(String route) {
    return ModalRoute.of(context)?.settings.name == route;
  }
}
