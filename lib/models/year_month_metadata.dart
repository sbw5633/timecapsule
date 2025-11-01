// lib/models/year_month_metadata.dart
// 연도/월별 메타데이터 모델입니다.

class YearMonthMetadata {
  final String id; // "familyUid_year" 또는 "familyUid_year_month"
  final String familyUid;
  final int? year;
  final int? month; // null이면 연도, 값이 있으면 월
  final String? mainImageUrl;
  final String? title; // 주제/제목
  int storyCount; // 해당 연도/월의 글 수

  YearMonthMetadata({
    required this.id,
    required this.familyUid,
    this.year,
    this.month,
    this.mainImageUrl,
    this.title,
    this.storyCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyUid': familyUid,
      'year': year,
      'month': month,
      'mainImageUrl': mainImageUrl,
      'title': title,
      'storyCount': storyCount,
    };
  }

  factory YearMonthMetadata.fromMap(String id, Map<String, dynamic> map) {
    return YearMonthMetadata(
      id: id,
      familyUid: map['familyUid'] ?? '',
      year: map['year'],
      month: map['month'],
      mainImageUrl: map['mainImageUrl'],
      title: map['title'],
      storyCount: map['storyCount'] ?? 0,
    );
  }
}

