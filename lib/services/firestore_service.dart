// lib/services/firestore_service.dart
// Firestore와 관련된 모든 CRUD(생성, 조회, 수정, 삭제) 로직을 처리하는 서비스입니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../models/story_model.dart';
import '../models/milestone_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 사용자 정보 가져오기
  Stream<UserModel?> getUser(String uid) {
    return _db.collection('Users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  // 사용자 정보 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('Users').doc(uid).update(data);
  }

  // 가족 정보 가져오기 (기존)
  Stream<FamilyModel?> getFamily(String familyId) {
    return _db.collection('Families').doc(familyId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return FamilyModel.fromFirestore(snapshot);
    });
  }

  // 가족 UID로 가족 정보 가져오기
  Stream<FamilyModel?> getFamilyByUid(String familyUid) {
    return _db
        .collection('Families')
        .where('familyUid', isEqualTo: familyUid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('가족 정보를 찾을 수 없습니다. familyUid: $familyUid');
        return null;
      }
      print('가족 정보를 찾았습니다. familyUid: $familyUid');
      return FamilyModel.fromFirestore(snapshot.docs.first);
    });
  }

  // 스토리 목록 가져오기
  Stream<List<StoryModel>> getStories(String familyUid) {
    print('FirestoreService.getStories 호출: $familyUid');
    return _db
        .collection('stories')
        .where('familyUid', isEqualTo: familyUid)
        .snapshots()
        .map((snapshot) {
      print('FirestoreService.getStories 스냅샷 수신: ${snapshot.docs.length}개 문서');
      final stories = snapshot.docs.map((doc) => StoryModel.fromFirestore(doc)).toList();
      // 클라이언트에서 정렬 (최신순)
      stories.sort((a, b) => b.storyDate.compareTo(a.storyDate));
      print('FirestoreService.getStories 정렬 완료: ${stories.length}개 스토리');
      return stories;
    });
  }

  // 스토리 추가
  Future<void> addStory(StoryModel story) async {
    await _db.collection('stories').add(story.toFirestore());
  }
  
  // 성장 기록 목록 가져오기
  Stream<List<MilestoneModel>> getMilestones(String familyUid, String childId) {
    // Firestore 구조상 'children' 컬렉션의 하위 컬렉션에서 가져와야 합니다.
    return _db
        .collection('Families')
        .doc(familyUid)
        .collection('children')
        .doc(childId)
        .collection('milestones')
        .orderBy('recordDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MilestoneModel.fromFirestore(doc)).toList());
  }
}
