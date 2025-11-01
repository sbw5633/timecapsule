// lib/screens/precious_moment_screen.dart
// 소중한 순간들 사진첩 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/precious_moment_model.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/inner_screen_layout.dart';
import '../widgets/cached_image_widget.dart';
import '../utils/route_config.dart';

class PreciousMomentScreen extends StatefulWidget {
  const PreciousMomentScreen({super.key});

  @override
  State<PreciousMomentScreen> createState() => _PreciousMomentScreenState();
}

class _PreciousMomentScreenState extends State<PreciousMomentScreen> {
  List<PreciousMomentModel> _allMoments = [];
  List<PreciousMomentModel> _filteredMoments = [];
  Set<String> _allTags = {};
  String? _selectedTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
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

      final snapshot = await FirebaseFirestore.instance
          .collection('preciousMoments')
          .where('familyUid', isEqualTo: userProvider.familyUid)
          .get();

      List<PreciousMomentModel> moments = [];
      Set<String> tags = {};

      for (var doc in snapshot.docs) {
        try {
          final moment = PreciousMomentModel.fromFirestore(doc);
          moments.add(moment);
          tags.addAll(moment.tags);
        } catch (e) {
          print('순간 파싱 실패: ${doc.id} - $e');
          continue;
        }
      }

      // 최신순 정렬
      moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allMoments = moments;
          _filteredMoments = moments;
          _allTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('순간 로드 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('순간 로드 실패: $e')),
        );
      }
    }
  }

  void _filterByTag(String? tag) {
    setState(() {
      _selectedTag = tag;
      if (tag == null) {
        _filteredMoments = _allMoments;
      } else {
        _filteredMoments = _allMoments
            .where((moment) => moment.tags.contains(tag))
            .toList();
      }
    });
  }

  void _showMomentDetail(PreciousMomentModel moment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MomentDetailScreen(moment: moment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InnerScreenLayout(
      body: Column(
        children: [
          // 태그 필터
          if (_allTags.isNotEmpty) _buildTagFilter(),
          // 순간 그리드
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMoments.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoAlbumGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, RouteConfig.createMoment);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTagFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 전체 태그
          _buildTagChip(
            label: '전체',
            isSelected: _selectedTag == null,
            onTap: () => _filterByTag(null),
          ),
          const SizedBox(width: 8),
          // 각 태그
          ..._allTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildTagChip(
                  label: tag,
                  isSelected: _selectedTag == tag,
                  onTap: () => _filterByTag(tag),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTag == null
                ? '아직 소중한 순간들이 없습니다.'
                : '선택한 태그의 순간이 없습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 순간을 추가하여\n소중한 추억을 기록해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAlbumGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredMoments.length,
      itemBuilder: (context, index) {
        final moment = _filteredMoments[index];
        return GestureDetector(
          onTap: () => _showMomentDetail(moment),
          child: _buildBookCover(moment),
        );
      },
    );
  }

  Widget _buildBookCover(PreciousMomentModel moment) {
    final String coverImageUrl = moment.imageUrls.isNotEmpty
        ? moment.imageUrls.first
        : 'https://via.placeholder.com/150'; // 기본 이미지

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedImageWidget(
                imageUrl: coverImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moment.title.length > 10
                      ? '${moment.title.substring(0, 10)}...'
                      : moment.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // 태그 표시
                if (moment.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: moment.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 순간 상세 화면 (책 넘김 효과)
class _MomentDetailScreen extends StatefulWidget {
  final PreciousMomentModel moment;

  const _MomentDetailScreen({required this.moment});

  @override
  State<_MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends State<_MomentDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  int _imagesPerPage = 4; // 기본 4장

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalPages = (widget.moment.imageUrls.length / _imagesPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moment.title),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, pageIndex) {
                final int startIndex = pageIndex * _imagesPerPage;
                final int endIndex = (startIndex + _imagesPerPage).clamp(0, widget.moment.imageUrls.length);
                final List<String> pageImages = widget.moment.imageUrls.sublist(startIndex, endIndex);

                return GestureDetector(
                  onScaleUpdate: (details) {
                    // 핀치 줌으로 이미지 개수 조절
                    if (details.scale > 1.0 && _imagesPerPage > 1) {
                      setState(() {
                        _imagesPerPage = (_imagesPerPage / 2).ceil().clamp(1, 16);
                      });
                    } else if (details.scale < 1.0 && _imagesPerPage < 16) {
                      setState(() {
                        _imagesPerPage = (_imagesPerPage * 2).floor().clamp(1, 16);
                      });
                    }
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (_imagesPerPage == 1) ? 1 : ((_imagesPerPage <= 4) ? 2 : 4),
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: pageImages.length,
                    itemBuilder: (context, imageIndex) {
                      final imageUrl = pageImages[imageIndex];
                      return GestureDetector(
                        onTap: () {
                          // 개별 이미지 확대 보기
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _ImageViewerScreen(
                                imageUrl: imageUrl,
                                imageUrls: widget.moment.imageUrls,
                                initialIndex: startIndex + imageIndex,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // 페이지 인디케이터 및 이미지 개수 조절 슬라이더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('페이지 ${_currentPage + 1} / $totalPages'),
                Slider(
                  value: _imagesPerPage.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 4, // 1, 4, 9, 16
                  label: '$_imagesPerPage장',
                  onChanged: (double newValue) {
                    setState(() {
                      _imagesPerPage = newValue.toInt();
                    });
                  },
                ),
                Text('한 페이지당 사진 수: $_imagesPerPage장'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 이미지 뷰어 화면
class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedImageWidget(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}