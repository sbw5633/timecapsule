// lib/screens/our_story_create_screen.dart
// 우리 이야기 작성 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/user_provider.dart';
import '../models/our_story_model.dart';
import '../services/file_upload_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_overlay.dart';

class OurStoryCreateScreen extends StatefulWidget {
  const OurStoryCreateScreen({super.key});

  @override
  State<OurStoryCreateScreen> createState() => _OurStoryCreateScreenState();
}

class _OurStoryCreateScreenState extends State<OurStoryCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FileUploadService _uploadService = FileUploadService();
  
  List<XFile> _selectedImages = [];
  DateTime? _selectedDate;
  bool _isLoading = false;
  String _loadingMessage = '저장 중...';

  static const int _maxTitleLength = 100;
  static const int _maxContentLength = 3000;
  static const int _maxImageCount = 5;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

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
        setState(() {
          _loadingMessage = '이미지 업로드 중...';
        });
        for (int i = 0; i < _selectedImages.length; i++) {
          setState(() {
            _loadingMessage = '이미지 업로드 중... (${i + 1}/${_selectedImages.length})';
          });
          final result = await _uploadService.uploadFile(_selectedImages[i]);
          if (result != null && result['view_url'] != null) {
            final viewUrl = _uploadService.getViewUrl(result['view_url']);
            imageUrls.add(viewUrl);
          }
        }
      }
      
      setState(() {
        _loadingMessage = '저장 중...';
      });

      // 우리 이야기 저장
      final ourStory = OurStoryModel(
        id: '',
        familyUid: userProvider.familyUid!,
        title: _titleController.text,
        content: _contentController.text,
        storyDate: _selectedDate!,
        authorId: userProvider.user!.uid,
        authorName: userProvider.user!.nickname,
        authorProfileImageUrl: userProvider.user!.profileImageUrl,
        imageUrls: imageUrls,
        tags: [],
        isFromStory: false,
        originalStoryId: null,
        createdAt: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('ourStories')
          .add(ourStory.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('우리 이야기가 작성되었습니다!')),
        );
        Navigator.pop(context, true); // true를 반환하여 화면이 새로고침되도록 함
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
    return PopScope(
      canPop: !_isLoading,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('우리 이야기 작성'),
              centerTitle: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 제목
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '제목 (${_maxTitleLength}자 이내)',
                        border: const OutlineInputBorder(),
                      ),
                      maxLength: _maxTitleLength,
                    ),
                    const SizedBox(height: 16),
                    // 내용
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: '내용 (${_maxContentLength}자 이내)',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 10,
                      maxLength: _maxContentLength,
                    ),
                    const SizedBox(height: 16),
                    // 날짜
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
                    // 이미지 선택 버튼
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text('사진 추가 (${_selectedImages.length}/$_maxImageCount)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 선택된 이미지 미리보기
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
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
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _saveStory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
          ),
          // 로딩 오버레이
          LoadingOverlay(
            message: _loadingMessage,
            isVisible: _isLoading,
          ),
        ],
      ),
    );
  }
}
