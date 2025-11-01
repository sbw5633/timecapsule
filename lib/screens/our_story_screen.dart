// lib/screens/our_story_screen.dart
// 우리 이야기 화면입니다. 책 형식으로 연도별 → 월별 → 글 목록으로 이동

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/our_story_model.dart';
import '../models/year_month_metadata.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/inner_screen_layout.dart';
import 'our_story_create_screen.dart';
import '../widgets/year_card.dart';
import '../widgets/month_card.dart';
import '../widgets/our_story_item_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/metadata_settings_dialog.dart';
import 'our_story_detail_screen.dart';

enum OurStoryViewMode { years, months, stories }

class OurStoryScreen extends StatefulWidget {
  const OurStoryScreen({super.key});

  @override
  State<OurStoryScreen> createState() => _OurStoryScreenState();
}

class _OurStoryScreenState extends State<OurStoryScreen> {
  OurStoryViewMode _viewMode = OurStoryViewMode.years;
  int? _selectedYear;
  int? _selectedMonth;
  
  Map<int, List<OurStoryModel>> _storiesByYear = {};
  Map<String, List<OurStoryModel>> _storiesByYearMonth = {}; // "2025_1" 형식
  Set<int> _availableYears = {};
  
  Map<String, YearMonthMetadata> _yearMetadata = {}; // "2025" 형식
  Map<String, YearMonthMetadata> _monthMetadata = {}; // "2025_1" 형식
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.familyUid == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 스토리 로드
      final snapshot = await FirebaseFirestore.instance
          .collection('ourStories')
          .where('familyUid', isEqualTo: userProvider.familyUid)
          .get()
          .timeout(const Duration(seconds: 5));

      List<OurStoryModel> stories = [];
      for (var doc in snapshot.docs) {
        try {
          final story = OurStoryModel.fromFirestore(doc);
          stories.add(story);
        } catch (e) {
          print('스토리 파싱 실패: ${doc.id} - $e');
          continue;
        }
      }

      // 메타데이터 로드
      final metadataSnapshot = await FirebaseFirestore.instance
          .collection('ourStoryMetadata')
          .where('familyUid', isEqualTo: userProvider.familyUid)
          .get();

      Map<String, YearMonthMetadata> yearMeta = {};
      Map<String, YearMonthMetadata> monthMeta = {};

      for (var doc in metadataSnapshot.docs) {
        try {
          final meta = YearMonthMetadata.fromMap(doc.id, doc.data());
          if (meta.month == null) {
            yearMeta['${meta.year}'] = meta;
          } else {
            monthMeta['${meta.year}_${meta.month}'] = meta;
          }
        } catch (e) {
          print('메타데이터 파싱 실패: ${doc.id} - $e');
          continue;
        }
      }

      // 연도별, 월별로 분류
      Map<int, List<OurStoryModel>> byYear = {};
      Map<String, List<OurStoryModel>> byYearMonth = {};
      Set<int> years = {};

      for (var story in stories) {
        final year = story.storyDate.year;
        final month = story.storyDate.month;
        final key = '${year}_$month';

        years.add(year);

        byYear.putIfAbsent(year, () => []).add(story);
        byYearMonth.putIfAbsent(key, () => []).add(story);
      }

      // 메타데이터에 없는 연도/월 생성
      for (var year in years) {
        if (!yearMeta.containsKey('$year')) {
          yearMeta['$year'] = YearMonthMetadata(
            id: '${userProvider.familyUid}_$year',
            familyUid: userProvider.familyUid!,
            year: year,
            storyCount: byYear[year]?.length ?? 0,
          );
        } else {
          yearMeta['$year']!.storyCount = byYear[year]?.length ?? 0;
        }

        // 월별 메타데이터
        for (int month = 1; month <= 12; month++) {
          final key = '${year}_$month';
          if (!monthMeta.containsKey(key)) {
            monthMeta[key] = YearMonthMetadata(
              id: '${userProvider.familyUid}_${year}_$month',
              familyUid: userProvider.familyUid!,
              year: year,
              month: month,
              storyCount: byYearMonth[key]?.length ?? 0,
            );
          } else {
            monthMeta[key]!.storyCount = byYearMonth[key]?.length ?? 0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _storiesByYear = byYear;
          _storiesByYearMonth = byYearMonth;
          _availableYears = years;
          _yearMetadata = yearMeta;
          _monthMetadata = monthMeta;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('데이터 로드 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    }
  }

  List<int> _getSortedYears() {
    return _availableYears.toList()..sort((a, b) => b.compareTo(a));
  }

  List<OurStoryModel> _getStoriesForMonth(int year, int month) {
    final key = '${year}_$month';
    return _storiesByYearMonth[key] ?? [];
  }

  YearMonthMetadata _getYearMetadata(int year) {
    return _yearMetadata['$year'] ?? YearMonthMetadata(
      id: '',
      familyUid: '',
      year: year,
      storyCount: _storiesByYear[year]?.length ?? 0,
    );
  }

  YearMonthMetadata _getMonthMetadata(int year, int month) {
    final key = '${year}_$month';
    return _monthMetadata[key] ?? YearMonthMetadata(
      id: '',
      familyUid: '',
      year: year,
      month: month,
      storyCount: _getStoriesForMonth(year, month).length,
    );
  }

  void _navigateToYear(int year) {
    setState(() {
      _selectedYear = year;
      _viewMode = OurStoryViewMode.months;
    });
  }

  void _navigateToMonth(int year, int month) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      _viewMode = OurStoryViewMode.stories;
    });
  }

  void _goBack() {
    setState(() {
      if (_viewMode == OurStoryViewMode.stories) {
        _selectedMonth = null;
        _viewMode = OurStoryViewMode.months;
      } else if (_viewMode == OurStoryViewMode.months) {
        _selectedYear = null;
        _viewMode = OurStoryViewMode.years;
      }
    });
  }

  Future<void> _updateYearMetadata(int year, {String? mainImageUrl, String? title}) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.familyUid == null) return;

      final meta = _getYearMetadata(year);
      final docId = '${userProvider.familyUid}_$year';

      final Map<String, dynamic> updateData = {
        'familyUid': userProvider.familyUid!,
        'year': year,
        'storyCount': meta.storyCount,
      };

      // mainImageUrl이 명시적으로 null이면 삭제, 아니면 업데이트
      if (mainImageUrl != null) {
        updateData['mainImageUrl'] = mainImageUrl;
      } else if (mainImageUrl == null && meta.mainImageUrl != null) {
        // null로 설정하려는 경우 FieldValue.delete() 사용
        updateData['mainImageUrl'] = FieldValue.delete();
      }

      // title 처리
      if (title != null) {
        updateData['title'] = title;
      } else if (title == null && meta.title != null) {
        updateData['title'] = meta.title;
      }

      await FirebaseFirestore.instance
          .collection('ourStoryMetadata')
          .doc(docId)
          .set(updateData, SetOptions(merge: true));

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _updateMonthMetadata(int year, int month, {String? mainImageUrl, String? title}) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.familyUid == null) return;

      final meta = _getMonthMetadata(year, month);
      final docId = '${userProvider.familyUid}_${year}_$month';

      final Map<String, dynamic> updateData = {
        'familyUid': userProvider.familyUid!,
        'year': year,
        'month': month,
        'storyCount': meta.storyCount,
      };

      // mainImageUrl이 명시적으로 null이면 삭제, 아니면 업데이트
      if (mainImageUrl != null) {
        updateData['mainImageUrl'] = mainImageUrl;
      } else if (mainImageUrl == null && meta.mainImageUrl != null) {
        // null로 설정하려는 경우 FieldValue.delete() 사용
        updateData['mainImageUrl'] = FieldValue.delete();
      }

      // title 처리
      if (title != null) {
        updateData['title'] = title;
      } else if (title == null && meta.title != null) {
        updateData['title'] = meta.title;
      }

      await FirebaseFirestore.instance
          .collection('ourStoryMetadata')
          .doc(docId)
          .set(updateData, SetOptions(merge: true));

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  void _showYearSettingsDialog(int year) {
    print('연도 설정 다이얼로그 열기: $year년');
    final meta = _getYearMetadata(year);
    
    showDialog(
      context: context,
      builder: (context) => 
      
      MetadataSettingsDialog(
        title: '${year}년 설정',
        currentMainImage: meta.mainImageUrl,
        currentTitle: meta.title ?? '$year년',
        onSave: (mainImageUrl, title) => _updateYearMetadata(year, mainImageUrl: mainImageUrl, title: title),
      ),
    );

    // showDialog(
    //   context: context,
    //   useRootNavigator: true,
    //   barrierDismissible: true,
    //   builder: (dialogContext) => MetadataSettingsDialog(
    //     title: '${year}년 설정',
    //     currentMainImage: meta.mainImageUrl,
    //     currentTitle: meta.title ?? '$year년',
    //     onSave: (mainImageUrl, title) {
    //       _updateYearMetadata(year, mainImageUrl: mainImageUrl, title: title);
    //     },
    //   ),
    // ).catchError((e, stackTrace) {
    //   print('연도 설정 다이얼로그 에러: $e');
    //   print('스택: $stackTrace');
    // });
  }

  void _showMonthSettingsDialog(int year, int month) {
    print('월 설정 다이얼로그 열기: $year년 $month월');
    final meta = _getMonthMetadata(year, month);
    
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) => MetadataSettingsDialog(
        title: '${year}년 ${month}월 설정',
        currentMainImage: meta.mainImageUrl,
        currentTitle: meta.title ?? '$month월',
        onSave: (mainImageUrl, title) {
          _updateMonthMetadata(year, month, mainImageUrl: mainImageUrl, title: title);
        },
      ),
    ).catchError((e, stackTrace) {
      print('월 설정 다이얼로그 에러: $e');
      print('스택: $stackTrace');
    });
  }

  void _showAddStoryDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OurStoryCreateScreen(),
      ),
    );
    
    // 스토리가 작성되면 데이터 새로고침
    if (result == true && mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InnerScreenLayout(
      body: Column(
        children: [
          // 뒤로가기 버튼 (연도 목록이 아닐 때만)
          if (_viewMode != OurStoryViewMode.years)
            _buildBackButton(),
          // 메인 컨텐츠
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBackButton() {
    final title = _viewMode == OurStoryViewMode.months
        ? '$_selectedYear년'
        : '$_selectedYear년 $_selectedMonth월';
    
    return BackButtonWidget(
      title: title,
      onBack: _goBack,
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case OurStoryViewMode.years:
        return _buildYearsView();
      case OurStoryViewMode.months:
        return _buildMonthsView();
      case OurStoryViewMode.stories:
        return _buildStoriesView();
    }
  }

  // 연도별 목록 (1행에 1개씩)
  Widget _buildYearsView() {
    final years = _getSortedYears();
    
    if (years.isEmpty) {
      return const EmptyStateWidget(
        message: '아직 우리 이야기가 없습니다.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final meta = _getYearMetadata(year);
        
        return YearCard(
          year: year,
          metadata: meta,
          onTap: () => _navigateToYear(year),
          onSettings: () => _showYearSettingsDialog(year),
        );
      },
    );
  }

  // 월별 그리드 (한 행에 3개씩, 총 4행)
  Widget _buildMonthsView() {
    if (_selectedYear == null) return const SizedBox();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final meta = _getMonthMetadata(_selectedYear!, month);
        
        return MonthCard(
          month: month,
          metadata: meta,
          onTap: () => _navigateToMonth(_selectedYear!, month),
          onSettings: () => _showMonthSettingsDialog(_selectedYear!, month),
        );
      },
    );
  }

  // 글 목록 (세부)
  Widget _buildStoriesView() {
    if (_selectedYear == null || _selectedMonth == null) return const SizedBox();

    final stories = _getStoriesForMonth(_selectedYear!, _selectedMonth!);
    stories.sort((a, b) => b.storyDate.compareTo(a.storyDate)); // 최신순

    if (stories.isEmpty) {
      return const EmptyStateWidget(
        message: '이 달에 작성된 이야기가 없습니다.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
                itemBuilder: (context, index) {
        return OurStoryItemCard(
          story: stories[index],
                    onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OurStoryDetailScreen(
                  story: stories[index],
                          ),
                        ),
                      );
                    },
        );
      },
    );
  }
}


