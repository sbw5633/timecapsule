// lib/utils/navigation_config.dart
// 앱의 네비게이션 메뉴 구조를 중앙에서 관리합니다.

import 'package:flutter/material.dart';
import 'route_config.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final int index;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.index,
  });
}

class NavigationConfig {
  // 메뉴 아이템들을 리스트로 관리
  static const List<NavigationItem> items = [
    NavigationItem(
      label: '타임라인',
      icon: Icons.home,
      route: RouteConfig.timeline,
      index: 0,
    ),
    NavigationItem(
      label: '히스토리 북',
      icon: Icons.book,
      route: RouteConfig.historyBook,
      index: 1,
    ),
    NavigationItem(
      label: '성장 기록',
      icon: Icons.child_care,
      route: RouteConfig.milestone,
      index: 2,
    ),
    NavigationItem(
      label: '육아 정보',
      icon: Icons.info,
      route: RouteConfig.parentingInfo,
      index: 3,
    ),
  ];

  // 인덱스로 메뉴 아이템 찾기
  static NavigationItem? getItemByIndex(int index) {
    try {
      return items.firstWhere((item) => item.index == index);
    } catch (e) {
      return null;
    }
  }

  // 라우트로 메뉴 아이템 찾기
  static NavigationItem? getItemByRoute(String route) {
    try {
      return items.firstWhere((item) => item.route == route);
    } catch (e) {
      return null;
    }
  }

  // 라벨로 메뉴 아이템 찾기
  static NavigationItem? getItemByLabel(String label) {
    try {
      return items.firstWhere((item) => item.label == label);
    } catch (e) {
      return null;
    }
  }

  // BottomNavigationBar 아이템들 생성
  static List<BottomNavigationBarItem> getBottomNavigationBarItems() {
    return items.map((item) => BottomNavigationBarItem(
      icon: Icon(item.icon),
      label: item.label,
    )).toList();
  }

  // 현재 화면의 인덱스 가져오기
  static int getCurrentIndex(String currentRoute) {
    final item = getItemByRoute(currentRoute);
    return item?.index ?? 0;
  }

  // 메뉴 아이템 개수
  static int get itemCount => items.length;
}
