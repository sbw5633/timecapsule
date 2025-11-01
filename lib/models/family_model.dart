// lib/models/family_model.dart
// 가족 데이터 모델입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String familyUid; // 6자리 가족 고유 ID
  final String familyName;
  final String? representativeImageUrl; // 대표사진 (선택사항)
  final String familyLeaderId; // 가족 대표 ID
  final List<FamilyMember> members;
  final List<FamilyInvitation> invitations;
  final Timestamp createdAt;
  final String createdBy;

  FamilyModel({
    required this.id,
    required this.familyUid,
    required this.familyName,
    this.representativeImageUrl,
    required this.familyLeaderId,
    required this.members,
    required this.invitations,
    required this.createdAt,
    required this.createdBy,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      id: doc.id,
      familyUid: data['familyUid'] ?? '',
      familyName: data['familyName'] ?? '',
      representativeImageUrl: data['representativeImageUrl'],
      familyLeaderId: data['familyLeaderId'] ?? data['createdBy'] ?? '', // 기본값은 생성자
      members: (data['members'] as List? ?? []).map((memberData) => FamilyMember.fromMap(memberData)).toList(),
      invitations: (data['invitations'] as List? ?? []).map((inviteData) => FamilyInvitation.fromMap(inviteData)).toList(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyUid': familyUid,
      'familyName': familyName,
      'representativeImageUrl': representativeImageUrl,
      'familyLeaderId': familyLeaderId,
      'members': members.map((m) => m.toMap()).toList(),
      'invitations': invitations.map((i) => i.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  // 가족 대표 멤버 찾기
  FamilyMember? get familyLeader {
    try {
      return members.firstWhere((member) => member.userId == familyLeaderId);
    } catch (e) {
      return null;
    }
  }
}

class FamilyMember {
  final String userId;
  final String name;
  final String profileImageUrl;
  final String role; // 'parent', 'child', 'grandparent' 등
  final Timestamp joinedAt;

  FamilyMember({
    required this.userId,
    required this.name,
    required this.profileImageUrl,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      role: data['role'] ?? 'parent',
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'joinedAt': joinedAt,
    };
  }
}

class FamilyInvitation {
  final String invitedUserId;
  final String invitedUserName;
  final String invitedUserEmail;
  final String status; // 'pending', 'accepted', 'declined'
  final Timestamp invitedAt;
  final Timestamp? respondedAt;

  FamilyInvitation({
    required this.invitedUserId,
    required this.invitedUserName,
    required this.invitedUserEmail,
    required this.status,
    required this.invitedAt,
    this.respondedAt,
  });

  factory FamilyInvitation.fromMap(Map<String, dynamic> data) {
    return FamilyInvitation(
      invitedUserId: data['invitedUserId'] ?? '',
      invitedUserName: data['invitedUserName'] ?? '',
      invitedUserEmail: data['invitedUserEmail'] ?? '',
      status: data['status'] ?? 'pending',
      invitedAt: data['invitedAt'] ?? Timestamp.now(),
      respondedAt: data['respondedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invitedUserId': invitedUserId,
      'invitedUserName': invitedUserName,
      'invitedUserEmail': invitedUserEmail,
      'status': status,
      'invitedAt': invitedAt,
      'respondedAt': respondedAt,
    };
  }
}
