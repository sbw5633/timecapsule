// lib/widgets/unified_story_dialog.dart
// 통합된 스토리 작성 다이얼로그입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/user_provider.dart';
import '../models/story_model.dart';
import '../models/our_story_model.dart';
import '../models/precious_moment_model.dart';
import '../services/file_upload_service.dart';
import '../widgets/add_to_our_story_widget.dart';

enum StoryType { timeline, preciousMoment }

class UnifiedStoryDialog extends StatefulWidget {
  final StoryType storyType;
  final VoidCallback onStoryAdded;

  const UnifiedStoryDialog({
    super.key,
    required this.storyType,
    required this.onStoryAdded,
  });

  @override
  State<UnifiedStoryDialog> createState() => _UnifiedStoryDialogState();
}

class _UnifiedStoryDialogState extends State<UnifiedStoryDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FileUploadService _uploadService = FileUploadService();
  
  List<XFile> _selectedImages = [];
  DateTime? _selectedDate;
  bool _addToOurStory = false;
  bool _isLoading = false;

  // 제한 설정
  int get _maxTitleLength => widget.storyType == StoryType.timeline ? 30 : 30;
  int get _maxContentLength => widget.storyType == StoryType.timeline ? 3000 : 300;
  int get _maxImageCount => widget.storyType == StoryType.timeline ? 5 : 30;
  int get _maxFileSizeBytes => 5 * 1024 * 1024; // 5MB

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = _formatDate(date);
      });
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxImageCount장까지만 선택할 수 있습니다.')),
      );
      return;
    }

    final remainingSlots = _maxImageCount - _selectedImages.length;
    List<XFile> images;
    
    if (remainingSlots == 1) {
      final XFile? singleImage = await _picker.pickImage(source: ImageSource.gallery);
      images = singleImage != null ? [singleImage] : [];
    } else {
      images = await _picker.pickMultiImage(limit: remainingSlots);
    }
    
    if (images.isEmpty) return;

    // 파일 검증
    final validImages = <XFile>[];
    for (XFile image in images) {
      if (_selectedImages.length + validImages.length >= _maxImageCount) break;
      
      // 파일 크기 체크
      final fileSize = await image.length();
      if (fileSize <= _maxFileSizeBytes) {
        validImages.add(image);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 크기가 5MB를 초과합니다.')),
        );
      }
    }

    if (validImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(validImages);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveStory() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    if (widget.storyType == StoryType.preciousMoment && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1장의 사진을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null || userProvider.familyUid == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // 이미지 업로드
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final uploadResults = await _uploadService.uploadMultipleFiles(_selectedImages);
        
        for (var result in uploadResults) {
          if (result['view_url'] != null) {
            final viewUrl = _uploadService.getViewUrl(result['view_url']);
            imageUrls.add(viewUrl);
          }
        }
      }

      // 타임라인 스토리 저장
      if (widget.storyType == StoryType.timeline) {
        final story = StoryModel(
          id: '',
          familyUid: userProvider.familyUid!,
          authorId: userProvider.user!.uid,
          authorName: userProvider.user!.nickname,
          authorProfileImageUrl: userProvider.user!.profileImageUrl,
          title: _titleController.text,
          content: _contentController.text,
          imageUrls: imageUrls,
          videoUrls: [],
          location: const GeoPoint(0, 0),
          weather: '',
          tags: [],
          storyDate: Timestamp.now(),
          createdAt: Timestamp.now(),
        );

        final storyDocRef = await FirebaseFirestore.instance
            .collection('stories')
            .add(story.toFirestore());

        // 우리 이야기에 추가하는 경우
        if (_addToOurStory) {
          final ourStory = OurStoryModel(
            id: '',
            familyUid: userProvider.familyUid!,
            title: _titleController.text,
            content: _contentController.text,
            storyDate: _selectedDate!,
            authorId: userProvider.user!.uid,
            authorName: userProvider.user!.nickname,
            authorProfileImageUrl: userProvider.user!.profileImageUrl,
            isFromStory: true,
            originalStoryId: storyDocRef.id,
            createdAt: Timestamp.now(),
          );

          await FirebaseFirestore.instance
              .collection('ourStories')
              .add(ourStory.toFirestore());
        }
      }
      // 소중한 순간 저장
      else if (widget.storyType == StoryType.preciousMoment) {
        final moment = PreciousMomentModel(
          id: '',
          familyUid: userProvider.familyUid!,
          title: _titleController.text,
          content: _contentController.text,
          imageUrls: imageUrls,
          createdAt: DateTime.now(),
          authorId: userProvider.user!.uid,
          authorName: userProvider.user!.nickname,
          authorProfileImageUrl: userProvider.user!.profileImageUrl,
        );

        await FirebaseFirestore.instance
            .collection('preciousMoments')
            .add(moment.toFirestore());

        // 우리 이야기에 추가하는 경우
        if (_addToOurStory) {
          final ourStory = OurStoryModel(
            id: '',
            familyUid: userProvider.familyUid!,
            title: _titleController.text,
            content: _contentController.text,
            storyDate: _selectedDate!,
            authorId: userProvider.user!.uid,
            authorName: userProvider.user!.nickname,
            authorProfileImageUrl: userProvider.user!.profileImageUrl,
            isFromStory: false, // 소중한 순간에서 추가된 것
            originalStoryId: null,
            createdAt: Timestamp.now(),
          );

          await FirebaseFirestore.instance
              .collection('ourStories')
              .add(ourStory.toFirestore());
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onStoryAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.storyType == StoryType.timeline ? '스토리' : '소중한 순간'}가 생성되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.storyType == StoryType.timeline ? '스토리 작성' : '소중한 순간 추가'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // 제목
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목 ($_maxTitleLength자 이내)',
                border: const OutlineInputBorder(),
              ),
              maxLength: _maxTitleLength,
            ),
            const SizedBox(height: 16),
            // 내용
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용 ($_maxContentLength자 이내)',
                border: const OutlineInputBorder(),
              ),
              maxLines: widget.storyType == StoryType.timeline ? 10 : 3,
              maxLength: _maxContentLength,
            ),
            const SizedBox(height: 16),
            // 날짜 (타임라인만)
            if (widget.storyType == StoryType.timeline) ...[
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: '날짜',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
            ],
            // 우리 이야기에 추가
            AddToOurStoryWidget(
              initialValue: _addToOurStory,
              onChanged: (value) {
                setState(() {
                  _addToOurStory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // 사진 선택 버튼
            OutlinedButton.icon(
              onPressed: _selectedImages.length >= _maxImageCount ? null : _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text('사진 추가 (${_selectedImages.length}/$_maxImageCount)'),
            ),
            const SizedBox(height: 16),
            // 선택된 이미지들
            if (_selectedImages.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveStory,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.storyType == StoryType.timeline ? '저장' : '저장'),
        ),
      ],
    );
  }
}
