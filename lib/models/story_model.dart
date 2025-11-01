// lib/models/story_model.dart
// 스토리 데이터 모델입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String familyUid;
  final String authorId;
  final String authorName;
  final String authorProfileImageUrl;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final GeoPoint location;
  final String weather;
  final List<String> tags;
  final Timestamp storyDate;
  final Timestamp createdAt;

  StoryModel({
    required this.id,
    required this.familyUid,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImageUrl,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.videoUrls,
    required this.location,
    required this.weather,
    required this.tags,
    required this.storyDate,
    required this.createdAt,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      familyUid: data['familyUid'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileImageUrl: data['authorProfileImageUrl'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
      weather: data['weather'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      storyDate: data['storyDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyUid': familyUid,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImageUrl': authorProfileImageUrl,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'location': location,
      'weather': weather,
      'tags': tags,
      'storyDate': storyDate,
      'createdAt': createdAt,
    };
  }
}
