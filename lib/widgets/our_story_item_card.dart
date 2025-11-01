// lib/widgets/our_story_item_card.dart
// 우리 이야기 아이템 카드 위젯

import 'package:flutter/material.dart';
import '../models/our_story_model.dart';
import '../utils/constants.dart';
import 'cached_image_widget.dart';

class OurStoryItemCard extends StatelessWidget {
  final OurStoryModel story;
  final VoidCallback? onTap;

  const OurStoryItemCard({
    super.key,
    required this.story,
    this.onTap,
  });

  static const double _borderRadius = 12.0;
  static const double _cardPadding = 16.0;
  static const double _cardMargin = 12.0;
  static const double _imageSize = 80.0;
  static const double _avatarRadius = 12.0;
  static const int _contentMaxLines = 2;
  static const double _imageBorderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    final hasImage = story.imageUrls.isNotEmpty;
    final imageUrl = hasImage ? story.imageUrls.first : null;
    final imageCount = story.imageUrls.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: _cardMargin),
        padding: const EdgeInsets.all(_cardPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 영역 (좌측)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성일
                  Text(
                    _formatDate(story.storyDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 제목
                  Text(
                    story.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 내용 (최대 2줄)
                  Text(
                    story.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: _contentMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 작성자
                  _buildAuthorSection(),
                ],
              ),
            ),
            // 이미지 영역 (우측)
            if (hasImage && imageUrl != null) ...[
              const SizedBox(width: 12),
              _buildImageSection(imageUrl, imageCount),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: _avatarRadius,
          backgroundColor: AppColors.primaryLight,
          child: story.authorProfileImageUrl != null
              ? ClipOval(
                  child: CachedImageWidget(
                    imageUrl: story.authorProfileImageUrl!,
                    width: _avatarRadius * 2,
                    height: _avatarRadius * 2,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 14,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(width: 6),
        Text(
          story.authorName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(String imageUrl, int imageCount) {
    return SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_imageBorderRadius),
            child: CachedImageWidget(
              imageUrl: imageUrl,
              width: _imageSize,
              height: _imageSize,
              fit: BoxFit.cover,
            ),
          ),
          if (imageCount > 1)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${imageCount - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

