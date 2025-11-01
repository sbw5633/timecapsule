// lib/models/user_model.dart
// 사용자 데이터 모델입니다. Firestore 문서의 데이터를 객체로 변환하는 데 사용됩니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String password;
  final String nickname;
  final String profileImageUrl;
  final String? familyUid; // 가족 UID 추가
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.password,
    required this.nickname,
    required this.profileImageUrl,
    this.familyUid,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      familyUid: data['familyUid'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'familyUid': familyUid,
      'createdAt': createdAt,
    };
  }
}
