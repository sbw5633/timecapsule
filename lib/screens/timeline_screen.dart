// lib/screens/timeline_screen.dart
// 메인 타임라인 화면입니다. 가족의 모든 스토리를 시간 순으로 보여줍니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/timeline_card.dart';
import '../widgets/common_screen_layout.dart';
import '../widgets/search_filter_widget.dart';
import '../utils/route_config.dart';
import '../models/story_model.dart';
import '../utils/provider_initializer.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  bool _isAscending = false;
  
  List<StoryModel> _filteredStories = [];
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  @override
  void initState() {
    super.initState();
    // Provider 초기화
    ProviderInitializer.initializeProvidersOnInit(
      context,
      initializeFamily: true,
      initializeStory: true,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 스토리 필터링 및 정렬
  void _filterAndSortStories(List<StoryModel> stories) {
    List<StoryModel> filtered = stories;

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((story) {
        final query = _searchQuery.toLowerCase();
        return story.title.toLowerCase().contains(query) ||
               story.content.toLowerCase().contains(query) ||
               story.authorName.toLowerCase().contains(query);
      }).toList();
    }

    // 년/월 필터
    final selectedYear = _filters['year'];
    final selectedMonth = _filters['month'];
    
    if (selectedYear != null) {
      filtered = filtered.where((story) {
        final storyDate = story.storyDate.toDate();
        return storyDate.year == selectedYear;
      }).toList();
    }

    if (selectedMonth != null) {
      filtered = filtered.where((story) {
        final storyDate = story.storyDate.toDate();
        return storyDate.month == selectedMonth;
      }).toList();
    }

    // 정렬
    filtered.sort((a, b) {
      if (_isAscending) {
        return a.storyDate.compareTo(b.storyDate); // 오래된순
      } else {
        return b.storyDate.compareTo(a.storyDate); // 최신순
      }
    });

    setState(() {
      _filteredStories = filtered;
    });
  }

  // 사용 가능한 년도/월 추출
  void _updateAvailableDates(List<StoryModel> stories) {
    final years = <int>{};
    final months = <int>{};

    for (final story in stories) {
      final date = story.storyDate.toDate();
      years.add(date.year);
      months.add(date.month);
    }

    setState(() {
      _availableYears = years.toList()..sort((a, b) => b.compareTo(a)); // 최신순
      _availableMonths = months.toList()..sort();
    });
  }

  // 검색 실행
  void _performSearch(String query, Map<String, dynamic> filters) {
    setState(() {
      _searchQuery = query;
      _filters = filters;
    });
    
    // 스토리 필터링 및 정렬 적용
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    _filterAndSortStories(storyProvider.stories);
  }

  // 필터 초기화
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filters = {};
      _isAscending = false;
    });
    
    // 스토리 필터링 및 정렬 적용
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    _filterAndSortStories(storyProvider.stories);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScreenLayout(
      title: '타임라인',
      checkUserProvider: true,
      checkFamilyProvider: true,
      checkStoryProvider: true,
      body: Consumer3<UserProvider, FamilyProvider, StoryProvider>(
        builder: (context, userProvider, familyProvider, storyProvider, child) {
          // 스토리가 업데이트될 때마다 필터링 및 날짜 업데이트
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (storyProvider.stories.isNotEmpty) {
              _updateAvailableDates(storyProvider.stories);
              _filterAndSortStories(storyProvider.stories);
            }
          });

          // CommonScreenLayout에서 이미 로딩 체크를 하므로 여기서는 스토리 목록만 처리
          if (storyProvider.stories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '아직 스토리가 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '첫 번째 스토리를 만들어보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 검색 및 필터 위젯
              SearchFilterWidget(
                hintText: '제목, 내용, 작성자로 검색...',
                searchFields: ['title', 'content', 'authorName'],
                filterOptions: [
                  FilterOption(
                    key: 'year',
                    label: '년',
                    options: _availableYears.map((year) => FilterItem(
                      value: year,
                      label: year.toString(),
                    )).toList(),
                    resetOnChange: 'month',
                  ),
                  FilterOption(
                    key: 'month',
                    label: '월',
                    options: _availableMonths.map((month) => FilterItem(
                      value: month,
                      label: month.toString(),
                    )).toList(),
                  ),
                ],
                onSearch: _performSearch,
                onReset: _resetFilters,
                isAscending: _isAscending,
                onToggleSort: (isAscending) {
                  setState(() {
                    _isAscending = isAscending;
                  });
                  // 스토리 필터링 및 정렬 적용
                  final storyProvider = Provider.of<StoryProvider>(context, listen: false);
                  _filterAndSortStories(storyProvider.stories);
                },
              ),
              // 스토리 목록
              Expanded(
                child: _filteredStories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '다른 검색어나 필터를 시도해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = _filteredStories[index];
                          return TimelineCard(
                            story: story,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RouteConfig.storyDetail,
                                arguments: story,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, RouteConfig.createStory);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
