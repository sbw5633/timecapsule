// lib/models/precious_moment_model.dart
// 소중한 순간들 데이터 모델입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class PreciousMomentModel {
  final String id;
  final String familyUid;
  final String title; // 30자 제한
  final String content; // 300자 제한
  final List<String> imageUrls; // 최대 30장
  final List<String> tags; // 태그 목록
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  final String? authorProfileImageUrl;

  PreciousMomentModel({
    required this.id,
    required this.familyUid,
    required this.title,
    required this.content,
    required this.imageUrls,
    this.tags = const [],
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorProfileImageUrl,
  });

  factory PreciousMomentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PreciousMomentModel(
      id: doc.id,
      familyUid: data['familyUid'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileImageUrl: data['authorProfileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyUid': familyUid,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImageUrl': authorProfileImageUrl,
    };
  }

  PreciousMomentModel copyWith({
    String? id,
    String? familyUid,
    String? title,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    DateTime? createdAt,
    String? authorId,
    String? authorName,
    String? authorProfileImageUrl,
  }) {
    return PreciousMomentModel(
      id: id ?? this.id,
      familyUid: familyUid ?? this.familyUid,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileImageUrl: authorProfileImageUrl ?? this.authorProfileImageUrl,
    );
  }

  // 대표 이미지 URL (첫 번째 이미지)
  String? get representativeImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  // 제목이 10자를 초과하면 줄임표 추가
  String get displayTitle {
    if (title.length > 10) {
      return '${title.substring(0, 10)}...';
    }
    return title;
  }
}
