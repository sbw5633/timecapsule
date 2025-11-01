// lib/utils/constants.dart
// 앱에서 전역적으로 사용될 상수들을 정의합니다.
// 색상, 폰트 스타일 등을 한 곳에서 관리할 수 있습니다.

import 'package:flutter/material.dart';

class AppColors {
  // 메인 브랜드 색상 - 채도 높은 파스텔톤
  static const Color primary = Color(0xFFF06292); // 채도 높은 파스텔 핑크
  static const Color primaryDark = Color(0xFFEC407A); // 진한 파스텔 핑크
  static const Color primaryLight = Color(0xFFF8BBD9); // 연한 파스텔 핑크
  
  // 보조 색상 - 채도 높은 파스텔 계열
  static const Color secondary = Color(0xFFCE93D8); // 채도 높은 파스텔 라벤더
  static const Color secondaryLight = Color(0xFFE1BEE7); // 연한 파스텔 라벤더
  
  // 배경 색상
  static const Color background = Color(0xFFFAFAFA); // 매우 연한 회색
  static const Color backgroundLight = Color(0xFFF5F5F5); // 연한 회색
  static const Color surface = Color(0xFFFFFFFF); // 흰색
  static const Color cardBackground = Color(0xFFFFF0F5); // 채도 높은 파스텔 핑크 배경
  
  // 테두리 색상
  static const Color border = Color(0xFFE0E0E0); // 연한 회색 테두리
  
  // 텍스트 색상
  static const Color textPrimary = Color(0xFF4E342E); // 진한 갈색
  static const Color textSecondary = Color(0xFF6D4C41); // 중간 갈색
  static const Color textLight = Color(0xFFA1887F); // 연한 갈색
  
  // 성공/에러/경고 색상
  static const Color success = Color(0xFF66BB6A); // 채도 높은 파스텔 녹색
  static const Color successLight = Color(0xFFC8E6C9); // 연한 녹색
  static const Color error = Color(0xFFEF5350); // 채도 높은 파스텔 빨간색
  static const Color errorLight = Color(0xFFFFCDD2); // 연한 빨간색
  static const Color warning = Color(0xFFFF9800); // 채도 높은 파스텔 주황색
  static const Color warningLight = Color(0xFFFFE0B2); // 연한 주황색
  
  // 액센트 색상
  static const Color accent = Color(0xFF9C27B0); // 채도 높은 파스텔 보라색
  static const Color accentLight = Color(0xFFCE93D8); // 연한 보라색
  
  // 기존 호환성을 위한 색상
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

// 앱 테마 정의
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.pink,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
