// lib/widgets/metadata_settings_dialog.dart
// 메타데이터 설정 다이얼로그

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/file_upload_service.dart';
import 'cached_image_widget.dart';

class MetadataSettingsDialog extends StatefulWidget {
  final String title;
  final String? currentMainImage;
  final String currentTitle;
  final Function(String?, String) onSave;

  const MetadataSettingsDialog({
    super.key,
    required this.title,
    required this.currentMainImage,
    required this.currentTitle,
    required this.onSave,
  });

  @override
  State<MetadataSettingsDialog> createState() => _MetadataSettingsDialogState();
}

class _MetadataSettingsDialogState extends State<MetadataSettingsDialog> {
  String? _mainImageUrl;
  late TextEditingController _titleController;
  bool _isUploading = false;

  static const double _dialogBorderRadius = 16.0;
  static const double _dialogPadding = 20.0;
  static const double _imageHeight = 200.0;
  static const double _imageBorderRadius = 12.0;
  static const double _placeholderIconSize = 48.0;

  @override
  void initState() {
    super.initState();
    _mainImageUrl = widget.currentMainImage;
    _titleController = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      setState(() {
        _isUploading = true;
      });

      try {
        final fileUploadService = FileUploadService();
        final result = await fileUploadService.uploadFile(image);
        
        if (mounted) {
          if (result != null && result['view_url'] != null) {
            final url = fileUploadService.getViewUrl(result['view_url']);
            setState(() {
              _mainImageUrl = url;
              _isUploading = false;
            });
          } else {
            setState(() {
              _isUploading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이미지 업로드 실패')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드 실패: $e')),
          );
        }
      }
    }
  }

  void _save() {
    widget.onSave(_mainImageUrl, _titleController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return 
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _dialogPadding),
            // 메인 이미지
            Stack(
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: _imageHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(_imageBorderRadius),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _buildImageContent(),
                  ),
                ),
                // 이미지가 있을 때만 X 버튼 표시
                if (_mainImageUrl != null && !_isUploading)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _mainImageUrl = null;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 주제 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '주제',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: _dialogPadding),
            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
                TextButton(onPressed: () => _save(), style: TextButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: Text('저장')),

              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isUploading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mainImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_imageBorderRadius),
        child: CachedImageWidget(
          imageUrl: _mainImageUrl!,
          fit: BoxFit.cover,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: _placeholderIconSize,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          '이미지 선택',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

