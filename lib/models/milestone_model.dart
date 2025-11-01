// lib/models/milestone_model.dart
// 성장 기록 데이터 모델입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneModel {
  final String id;
  final String authorId;
  final String type;
  final String value;
  final String notes;
  final String? photoUrl;
  final Timestamp recordDate;
  final Timestamp createdAt;

  MilestoneModel({
    required this.id,
    required this.authorId,
    required this.type,
    required this.value,
    required this.notes,
    this.photoUrl,
    required this.recordDate,
    required this.createdAt,
  });

  factory MilestoneModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MilestoneModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      type: data['type'] ?? '',
      value: data['value'] ?? '',
      notes: data['notes'] ?? '',
      photoUrl: data['photoUrl'],
      recordDate: data['recordDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'type': type,
      'value': value,
      'notes': notes,
      'photoUrl': photoUrl,
      'recordDate': recordDate,
      'createdAt': createdAt,
    };
  }
}
