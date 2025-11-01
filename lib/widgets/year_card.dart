// lib/widgets/year_card.dart
// 연도 카드 위젯

import 'package:flutter/material.dart';
import '../models/year_month_metadata.dart';
import '../utils/constants.dart';
import 'cached_image_widget.dart';

class YearCard extends StatelessWidget {
  final int year;
  final YearMonthMetadata metadata;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const YearCard({
    super.key,
    required this.year,
    required this.metadata,
    required this.onTap,
    required this.onSettings,
  });

  static const double _cardHeight = 100.0;
  static const double _imageWidth = 100.0;
  static const double _borderRadius = 12.0;
  static const double _padding = 16.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: _padding),
        height: _cardHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 메인 이미지
            _buildImageSection(),
            // 주제와 글 수
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _padding, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 연도
                    Text(
                      '$year년',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 주제
                    Text(
                      metadata.title ?? '$year년',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 이야기 수
                    Text(
                      '${metadata.storyCount}개의 이야기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 설정 아이콘
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: onSettings,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(_borderRadius)),
      child: Container(
        width: _imageWidth,
        height: _cardHeight,
        color: Colors.grey.shade200,
        child: metadata.mainImageUrl != null
            ? CachedImageWidget(
                imageUrl: metadata.mainImageUrl!,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.book_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
      ),
    );
  }
}

