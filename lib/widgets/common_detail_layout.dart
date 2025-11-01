// lib/widgets/common_detail_layout.dart
// 상세 화면용 공통 레이아웃 위젯입니다.

import 'package:flutter/material.dart';
import 'cached_image_widget.dart';

class CommonDetailLayout extends StatelessWidget {
  final String title;
  final String authorName;
  final String? authorProfileImageUrl;
  final DateTime date;
  final String? contentTitle;
  final String content;
  final List<String> imageUrls;
  final List<String>? videoUrls;

  const CommonDetailLayout({
    super.key,
    required this.title,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.date,
    this.contentTitle,
    required this.content,
    this.imageUrls = const [],
    this.videoUrls,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보
          _buildAuthorSection(),
          const SizedBox(height: 24),
          
          // 제목
          if (contentTitle != null && contentTitle!.isNotEmpty) ...[
            Text(
              contentTitle!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 내용
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          const SizedBox(height: 24),
          
          // 이미지들
          if (imageUrls.isNotEmpty) _buildImageSection(),
          
          // 비디오들
          if (videoUrls != null && videoUrls!.isNotEmpty) _buildVideoSection(),
        ],
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          child: authorProfileImageUrl != null && authorProfileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedImageWidget(
                    imageUrl: authorProfileImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.person, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                _formatDate(date),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사진',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedImageWidget(
                    imageUrl: imageUrls[index],
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '동영상',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text('비디오 플레이어는 준비 중입니다.'),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }
}
