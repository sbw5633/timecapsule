// lib/screens/history_book_screen.dart
// 히스토리 북 화면입니다. 가족의 특별한 순간들을 책 형태로 보여줍니다.

import 'package:flutter/material.dart';
import '../widgets/common_screen_layout.dart';
import '../utils/provider_initializer.dart';
import 'our_story_screen.dart';
import 'precious_moment_screen.dart';

class HistoryBookScreen extends StatefulWidget {
  const HistoryBookScreen({super.key});

  @override
  State<HistoryBookScreen> createState() => _HistoryBookScreenState();
}

class _HistoryBookScreenState extends State<HistoryBookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': '우리 이야기',
      'icon': Icons.home,
      'description': '가족의 주요 연혁과 이벤트',
    },
    {
      'title': '소중한 순간들',
      'icon': Icons.favorite,
      'description': '특별한 추억과 감동적인 순간',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Provider 초기화
    ProviderInitializer.initializeProvidersOnInit(
      context,
      initializeFamily: true,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScreenLayout(
      title: '히스토리 북',
      bottom: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: _categories.map((category) => Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category['icon'], size: 20),
              const SizedBox(height: 4),
              Text(
                category['title'],
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        )).toList(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 우리 이야기 탭
          const OurStoryScreen(),
          // 소중한 순간들 탭
          const PreciousMomentScreen(),
        ],
      ),
    );
  }

}