// lib/widgets/month_card.dart
// 월 카드 위젯

import 'package:flutter/material.dart';
import '../models/year_month_metadata.dart';
import '../utils/constants.dart';
import 'cached_image_widget.dart';

class MonthCard extends StatelessWidget {
  final int month;
  final YearMonthMetadata metadata;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const MonthCard({
    super.key,
    required this.month,
    required this.metadata,
    required this.onTap,
    required this.onSettings,
  });

  static const double _borderRadius = 12.0;
  static const double _settingsIconSize = 16.0;
  static const double _settingsButtonPadding = 6.0;
  static const double _contentPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            // 배경 이미지 (전체 차지)
            _buildImageSection(),
            // 좌측 상단 월 표시
            Positioned(
              top: 8,
              left: 8,
              child: _buildYearLabel(),
            ),
            // 하단 텍스트 (반투명 배경)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildContentSection(),
            ),
            // 설정 아이콘 (우측 상단 모서리)
            Positioned(
              top: 4,
              right: 4,
              child: _buildSettingsButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: metadata.mainImageUrl != null
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getMonthGradientColors(month),
                ),
              ),
        child: metadata.mainImageUrl != null
            ? CachedImageWidget(
                imageUrl: metadata.mainImageUrl!,
                fit: BoxFit.cover,
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$month월',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Color> _getMonthGradientColors(int month) {
    // 월별로 다른 그라데이션 색상
    final gradients = [
      [AppColors.primary, AppColors.primaryDark], // 1월
      [AppColors.secondary, AppColors.accent], // 2월
      [Color(0xFFFFB3BA), Color(0xFFFFCCCB)], // 3월 - 연한 핑크
      [Color(0xFFBAE1FF), Color(0xFFB0E0E6)], // 4월 - 연한 블루
      [Color(0xFFFFE5B4), Color(0xFFFFD700)], // 5월 - 연한 옐로우
      [Color(0xFFBFF5BF), Color(0xFF90EE90)], // 6월 - 연한 그린
      [Color(0xFFFFD4E5), Color(0xFFFFB6C1)], // 7월 - 핑크
      [Color(0xFFFFE4B5), Color(0xFFFFD700)], // 8월 - 골드
      [Color(0xFFE6E6FA), Color(0xFFDDA0DD)], // 9월 - 라벤더
      [Color(0xFFFFE5CC), Color(0xFFFF8C69)], // 10월 - 오렌지
      [Color(0xFFCCCCFF), Color(0xFF9370DB)], // 11월 - 퍼플
      [Color(0xFFE0E0FF), Color(0xFFB0B0FF)], // 12월 - 연한 블루
    ];

    return gradients[(month - 1) % gradients.length];
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(_contentPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.title ?? '$month월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${metadata.storyCount}개의 이야기',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: onSettings,
      child: Material(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(_settingsButtonPadding),
          child: const Icon(
            Icons.settings,
            size: _settingsIconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildYearLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$month월',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

