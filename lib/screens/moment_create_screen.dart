// lib/screens/moment_create_screen.dart
// 소중한 순간 작성 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/user_provider.dart';
import '../models/precious_moment_model.dart';
import '../models/our_story_model.dart';
import '../services/file_upload_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/add_to_our_story_widget.dart';
import '../utils/constants.dart';

class MomentCreateScreen extends StatefulWidget {
  const MomentCreateScreen({super.key});

  @override
  State<MomentCreateScreen> createState() => _MomentCreateScreenState();
}

class _MomentCreateScreenState extends State<MomentCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FileUploadService _uploadService = FileUploadService();
  final List<XFile> _selectedFiles = [];
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _addToOurStory = false; // 우리 이야기에 추가 여부
  
  // 파일 크기 제한 (5MB)
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const int _maxImageCount = 30;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 파일 크기 체크
  Future<bool> _checkFileSize(XFile file) async {
    final fileSize = await file.length();
    return fileSize <= _maxFileSizeBytes;
  }

  // 중복 파일 체크 (파일명과 크기로 비교)
  Future<bool> _isDuplicateFile(XFile newFile) async {
    for (XFile existingFile in _selectedFiles) {
      // 파일 경로가 같으면 중복
      if (existingFile.path == newFile.path) {
        return true;
      }
      
      // 파일명과 크기가 같으면 중복으로 간주
      if (existingFile.name == newFile.name) {
        final existingSize = await existingFile.length();
        final newSize = await newFile.length();
        if (existingSize == newSize) {
          return true;
        }
      }
    }
    return false;
  }

  // 총 파일 크기 체크
  Future<bool> _checkTotalFileSize(List<XFile> files) async {
    int totalSize = 0;
    for (XFile file in files) {
      totalSize += await file.length();
    }
    return totalSize <= _maxFileSizeBytes;
  }

  Future<void> _pickImages() async {
    // 최대 개수 체크
    if (_selectedFiles.length >= _maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxImageCount장까지만 선택할 수 있습니다.')),
      );
      return;
    }

    // 선택 가능한 개수 계산
    final remainingSlots = _maxImageCount - _selectedFiles.length;
    
    List<XFile> images;
    
    // remainingSlots가 1이면 단일 이미지 선택, 2 이상이면 다중 이미지 선택
    if (remainingSlots == 1) {
      final XFile? singleImage = await _picker.pickImage(source: ImageSource.gallery);
      images = singleImage != null ? [singleImage] : [];
    } else {
      images = await _picker.pickMultiImage(
        limit: remainingSlots, // 선택 가능한 개수로 제한
      );
    }
    if (images.isEmpty) return;

    // 각 파일 검증 및 개수 제한
    final validImages = <XFile>[];
    for (XFile image in images) {
      // 최대 개수 체크 (이중 체크)
      if (_selectedFiles.length + validImages.length >= _maxImageCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최대 $_maxImageCount장까지만 선택할 수 있습니다.')),
        );
        break;
      }

      // 중복 체크 (파일명과 크기로 비교)
      if (await _isDuplicateFile(image)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('중복된 사진이 있습니다. 다른 사진을 선택해주세요.')),
        );
        continue;
      }

      // 파일 크기 체크
      if (await _checkFileSize(image)) {
        validImages.add(image);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 크기가 5MB를 초과합니다. 다른 사진을 선택해주세요.')),
        );
      }
    }

    // 총 파일 크기 체크 및 최종 개수 체크
    if (validImages.isNotEmpty) {
      final newFileList = [..._selectedFiles, ...validImages];
      
      // 최대 개수 체크
      if (newFileList.length > _maxImageCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최대 $_maxImageCount장까지만 선택할 수 있습니다.')),
        );
        return;
      }

      // 총 파일 크기 체크
      if (await _checkTotalFileSize(newFileList)) {
        setState(() {
          _selectedFiles.addAll(validImages);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 사진들의 총 크기가 5MB를 초과합니다.')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _createMoment() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
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
      
      if (userProvider.user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      if (userProvider.familyUid == null) {
        throw Exception('가족 정보를 찾을 수 없습니다.');
      }

      // 이미지 업로드
      List<String> imageUrls = [];
      if (_selectedFiles.isNotEmpty) {
        setState(() {
          _loadingMessage = '이미지를 업로드하는 중...';
        });
        
        final uploadResults = await _uploadService.uploadMultipleFiles(_selectedFiles);
        
        for (var result in uploadResults) {
          if (result['view_url'] != null) {
            final viewUrl = _uploadService.getViewUrl(result['view_url']);
            imageUrls.add(viewUrl);
          }
        }
        
        if (imageUrls.isEmpty) {
          throw Exception('이미지 업로드에 실패했습니다.');
        }
        
        setState(() {
          _loadingMessage = '소중한 순간을 저장하는 중...';
        });
      }

      // 소중한 순간 생성
      final moment = PreciousMomentModel(
        id: '', // Firestore에서 자동 생성
        familyUid: userProvider.familyUid!,
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        authorId: userProvider.user!.uid,
        authorName: userProvider.user!.nickname,
        authorProfileImageUrl: userProvider.user!.profileImageUrl,
      );

      // Firestore에 저장
      await FirebaseFirestore.instance.collection('preciousMoments').add(moment.toFirestore());

      // 우리 이야기에 추가하는 경우
      if (_addToOurStory) {
        setState(() {
          _loadingMessage = '우리 이야기에 추가하는 중...';
        });

        final ourStory = OurStoryModel(
          id: '', // Firestore에서 자동 생성
          familyUid: userProvider.familyUid!,
          title: _titleController.text,
          content: _contentController.text,
          storyDate: DateTime.now(),
          authorId: userProvider.user!.uid,
          authorName: userProvider.user!.nickname,
          authorProfileImageUrl: userProvider.user!.profileImageUrl,
          imageUrls: imageUrls, // 이미지 URL 추가
          isFromStory: false, // 소중한 순간에서 추가된 것
          originalStoryId: null,
          createdAt: Timestamp.now(),
        );

        await FirebaseFirestore.instance
            .collection('ourStories')
            .add(ourStory.toFirestore());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('소중한 순간이 생성되었습니다!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('소중한 순간 생성 중 오류가 발생했습니다: $e')),
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
      canPop: !_isLoading, // 로딩 중일 때 뒤로가기 막기
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('소중한 순간 작성'),
              centerTitle: true,
              // 로딩 중일 때 뒤로가기 버튼 비활성화
              automaticallyImplyLeading: !_isLoading,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _titleController,
                            labelText: '제목',
                            maxLength: 30,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _contentController,
                            labelText: '내용',
                            maxLines: 3,
                            maxLength: 300,
                          ),
                          const SizedBox(height: 16),
                          // 이미지 선택 버튼
                          OutlinedButton.icon(
                            onPressed: _selectedFiles.length >= _maxImageCount ? null : _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: Text('사진 추가 (${_selectedFiles.length}/$_maxImageCount)'),
                          ),
                          const SizedBox(height: 16),
                          // 우리 이야기에 추가 위젯
                          AddToOurStoryWidget(
                            initialValue: _addToOurStory,
                            onChanged: (value) {
                              setState(() {
                                _addToOurStory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // 선택된 이미지들 표시
                          if (_selectedFiles.isNotEmpty) ...[
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedFiles.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(_selectedFiles[index].path),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        // 삭제 버튼
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
                                        // 파일 크기 표시
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          child: FutureBuilder<int>(
                                            future: _selectedFiles[index].length(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                final sizeInMB = (snapshot.data! / (1024 * 1024)).toStringAsFixed(1);
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${sizeInMB}MB',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  PrimaryButton(
                    text: _isLoading ? '생성 중...' : '소중한 순간 생성하기',
                    onPressed: _isLoading ? null : _createMoment,
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
