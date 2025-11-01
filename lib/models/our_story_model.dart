// lib/models/our_story_model.dart
// 우리 이야기 데이터 모델입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class OurStoryModel {
  final String id;
  final String familyUid;
  final String title;
  final String content;
  final DateTime storyDate;
  final String authorId;
  final String authorName;
  final String? authorProfileImageUrl;
  final List<String> imageUrls; // 이미지 URL 목록
  final List<String> tags; // 태그 목록
  final bool isFromStory; // 스토리에서 추가된 것인지
  final String? originalStoryId; // 원본 스토리 ID
  final Timestamp createdAt;

  OurStoryModel({
    required this.id,
    required this.familyUid,
    required this.title,
    required this.content,
    required this.storyDate,
    required this.authorId,
    required this.authorName,
    this.authorProfileImageUrl,
    this.imageUrls = const [],
    this.tags = const [],
    required this.isFromStory,
    this.originalStoryId,
    required this.createdAt,
  });

  factory OurStoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // storyDate 안전하게 처리
    DateTime storyDate;
    if (data['storyDate'] != null) {
      if (data['storyDate'] is Timestamp) {
        storyDate = (data['storyDate'] as Timestamp).toDate();
      } else if (data['storyDate'] is DateTime) {
        storyDate = data['storyDate'] as DateTime;
      } else {
        storyDate = DateTime.now();
      }
    } else {
      storyDate = DateTime.now();
    }
    
    // createdAt 안전하게 처리
    Timestamp createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = data['createdAt'] as Timestamp;
      } else {
        createdAt = Timestamp.now();
      }
    } else {
      createdAt = Timestamp.now();
    }
    
    return OurStoryModel(
      id: doc.id,
      familyUid: data['familyUid'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      storyDate: storyDate,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileImageUrl: data['authorProfileImageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isFromStory: data['isFromStory'] ?? false,
      originalStoryId: data['originalStoryId'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyUid': familyUid,
      'title': title,
      'content': content,
      'storyDate': Timestamp.fromDate(storyDate),
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImageUrl': authorProfileImageUrl,
      'imageUrls': imageUrls,
      'tags': tags,
      'isFromStory': isFromStory,
      'originalStoryId': originalStoryId,
      'createdAt': createdAt,
    };
  }

  OurStoryModel copyWith({
    String? id,
    String? familyUid,
    String? title,
    String? content,
    DateTime? storyDate,
    String? authorId,
    String? authorName,
    String? authorProfileImageUrl,
    List<String>? imageUrls,
    List<String>? tags,
    bool? isFromStory,
    String? originalStoryId,
    Timestamp? createdAt,
  }) {
    return OurStoryModel(
      id: id ?? this.id,
      familyUid: familyUid ?? this.familyUid,
      title: title ?? this.title,
      content: content ?? this.content,
      storyDate: storyDate ?? this.storyDate,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileImageUrl: authorProfileImageUrl ?? this.authorProfileImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      isFromStory: isFromStory ?? this.isFromStory,
      originalStoryId: originalStoryId ?? this.originalStoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
