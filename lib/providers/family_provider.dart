// lib/providers/family_provider.dart
// 가족 그룹의 상태를 관리하는 Provider입니다.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class FamilyProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService.instance;
  FamilyModel? _family;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _currentFamilyUid;

  FamilyModel? get family => _family;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // 6자리 랜덤 가족 UID 생성 (중복 방지)
  Future<String> _generateFamilyUid() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    while (true) {
      final uid = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      
      // 중복 체크
      final existingFamily = await FirebaseFirestore.instance
          .collection('Families')
          .where('familyUid', isEqualTo: uid)
          .get();
      
      if (existingFamily.docs.isEmpty) {
        return uid; // 중복되지 않는 UID 반환
      }
      
      // 중복되면 다시 생성
      print('가족 UID 중복 감지: $uid, 재생성 중...');
    }
  }

  void initialize(String familyUid) {
    if (_isInitialized && _currentFamilyUid == familyUid) return;
    
    print('FamilyProvider 초기화 시작: $familyUid');
    _isLoading = true;
    _isInitialized = true;
    _currentFamilyUid = familyUid;
    notifyListeners();
    
    _initializeAsync(familyUid);
  }
  
  Future<void> _initializeAsync(String familyUid) async {
    try {
      // 먼저 로컬 캐시에서 데이터 로드
      await _loadFromCache(familyUid);
      
      // 네트워크에서 최신 데이터 확인 및 동기화
      await _syncWithNetwork(familyUid);
      
    } catch (error) {
      print('FamilyProvider 초기화 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로컬 캐시에서 데이터 로드
  Future<void> _loadFromCache(String familyUid) async {
    try {
      final cachedFamily = await _localStorage.loadFamily(familyUid);
      if (cachedFamily != null) {
        print('로컬 캐시에서 Family 로드');
        _family = cachedFamily;
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      print('캐시 로드 에러: $error');
    }
  }

  // 네트워크와 동기화 (업데이트만 감지)
  Future<void> _syncWithNetwork(String familyUid) async {
    try {
      _firestoreService.getFamilyByUid(familyUid).listen(
        (networkFamily) async {
          if (networkFamily == null) {
            _family = null;
            _isLoading = false;
            notifyListeners();
            return;
          }
          
          // 업데이트가 있는지 확인
          final hasUpdate = _hasUpdate(networkFamily);
          
          if (hasUpdate) {
            print('네트워크에서 Family 수신 (업데이트 감지)');
            
            // 로컬 캐시에 저장
            await _localStorage.saveFamily(networkFamily);
            
            // UI 업데이트
            _family = networkFamily;
            _isLoading = false;
            notifyListeners();
          } else {
            print('Family 업데이트 없음 - 캐시 유지');
          }
        },
        onError: (error) {
          print('네트워크 동기화 에러: $error');
          // 네트워크 에러 시에도 로컬 캐시 데이터는 유지
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (error) {
      print('네트워크 동기화 초기화 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // 업데이트가 있는지 확인
  bool _hasUpdate(FamilyModel networkFamily) {
    if (_family == null) return true;
    
    // ID나 주요 필드 변경 확인
    if (_family!.id != networkFamily.id) return true;
    if (_family!.familyName != networkFamily.familyName) return true;
    if (_family!.members.length != networkFamily.members.length) return true;
    if (_family!.invitations.length != networkFamily.invitations.length) return true;
    
    // 멤버 변경 확인
    final cachedMemberIds = _family!.members.map((m) => m.userId).toSet();
    final networkMemberIds = networkFamily.members.map((m) => m.userId).toSet();
    if (cachedMemberIds != networkMemberIds) return true;
    
    return false;
  }

  // 가족 생성
  Future<String> createFamily({
    required String familyName,
    required String userId,
    required String userName,
    required String userEmail,
    required String profileImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 6자리 가족 UID 생성 (중복 방지)
      String familyUid = await _generateFamilyUid();
      
      // Firestore에 가족 정보 저장
      final familyData = {
        'familyUid': familyUid,
        'familyName': familyName,
        'familyLeaderId': userId, // 가족 대표는 가족을 생성한 사람
        'members': [
          {
            'userId': userId,
            'name': userName,
            'profileImageUrl': profileImageUrl,
            'role': 'parent',
            'joinedAt': Timestamp.now(),
          }
        ],
        'invitations': [],
        'createdAt': Timestamp.now(),
        'createdBy': userId,
      };

      final docRef = await FirebaseFirestore.instance.collection('Families').add(familyData);
      
      // 사용자 정보에 familyUid 업데이트
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'familyUid': familyUid,
      });

      // 생성된 가족 정보 로드
      _family = FamilyModel(
        id: docRef.id,
        familyUid: familyUid,
        familyName: familyName,
        familyLeaderId: userId, // 가족 대표는 가족을 생성한 사람
        members: [
          FamilyMember(
            userId: userId,
            name: userName,
            profileImageUrl: profileImageUrl,
            role: 'parent',
            joinedAt: Timestamp.now(),
          )
        ],
        invitations: [],
        createdAt: Timestamp.now(),
        createdBy: userId,
      );

      _isLoading = false;
      notifyListeners();
      return familyUid;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 가족 UID로 가족 조인
  Future<bool> joinFamily({
    required String familyUid,
    required String userId,
    required String userName,
    required String userEmail,
    required String profileImageUrl,
  }) async {
    try {
      // 가족 UID로 가족 찾기
      final familyQuery = await FirebaseFirestore.instance
          .collection('Families')
          .where('familyUid', isEqualTo: familyUid)
          .get();

      if (familyQuery.docs.isEmpty) {
        throw Exception('가족을 찾을 수 없습니다.');
      }

      final familyDoc = familyQuery.docs.first;
      final familyData = familyDoc.data();
      
      // 이미 멤버인지 확인
      final members = List<Map<String, dynamic>>.from(familyData['members'] ?? []);
      if (members.any((member) => member['userId'] == userId)) {
        throw Exception('이미 가족에 속해있습니다.');
      }

      // 새 멤버 추가
      members.add({
        'userId': userId,
        'name': userName,
        'profileImageUrl': profileImageUrl,
        'role': 'parent',
        'joinedAt': Timestamp.now(),
      });

      // Firestore 업데이트
      await familyDoc.reference.update({
        'members': members,
      });

      // 사용자 정보에 familyUid 업데이트
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'familyUid': familyUid,
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 가족 초대 보내기
  Future<void> sendInvitation({
    required String invitedUserEmail,
    required String invitedUserName,
  }) async {
    if (_family == null) return;

    try {
      // 초대할 사용자 찾기
      final userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: invitedUserEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('사용자를 찾을 수 없습니다.');
      }

      final invitedUserId = userQuery.docs.first.id;

      // 이미 초대되었는지 확인
      final existingInvitation = _family!.invitations.any((invite) => 
          invite.invitedUserId == invitedUserId && invite.status == 'pending');

      if (existingInvitation) {
        throw Exception('이미 초대를 보냈습니다.');
      }

      // 초대 추가
      final newInvitation = FamilyInvitation(
        invitedUserId: invitedUserId,
        invitedUserName: invitedUserName,
        invitedUserEmail: invitedUserEmail,
        status: 'pending',
        invitedAt: Timestamp.now(),
      );

      final updatedInvitations = [..._family!.invitations, newInvitation];

      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('Families')
          .doc(_family!.id)
          .update({
        'invitations': updatedInvitations.map((i) => i.toMap()).toList(),
      });

      // 로컬 상태 업데이트
      _family = FamilyModel(
        id: _family!.id,
        familyUid: _family!.familyUid,
        familyName: _family!.familyName,
        familyLeaderId: _family!.familyLeaderId,
        members: _family!.members,
        invitations: updatedInvitations,
        createdAt: _family!.createdAt,
        createdBy: _family!.createdBy,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 초대 응답 처리
  Future<void> respondToInvitation({
    required String familyId,
    required String userId,
    required String response, // 'accepted' or 'declined'
  }) async {
    try {
      final familyDoc = await FirebaseFirestore.instance
          .collection('Families')
          .doc(familyId)
          .get();

      if (!familyDoc.exists) {
        throw Exception('가족을 찾을 수 없습니다.');
      }

      final familyData = familyDoc.data()!;
      final invitations = List<Map<String, dynamic>>.from(familyData['invitations'] ?? []);

      // 해당 초대 찾기 및 업데이트
      final invitationIndex = invitations.indexWhere((invite) => invite['invitedUserId'] == userId);
      if (invitationIndex == -1) {
        throw Exception('초대를 찾을 수 없습니다.');
      }

      invitations[invitationIndex]['status'] = response;
      invitations[invitationIndex]['respondedAt'] = Timestamp.now();

      // Firestore 업데이트
      await familyDoc.reference.update({
        'invitations': invitations,
      });

      // 수락한 경우 멤버로 추가
      if (response == 'accepted') {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final members = List<Map<String, dynamic>>.from(familyData['members'] ?? []);
          
          members.add({
            'userId': userId,
            'name': userData['nickname'] ?? '',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
            'role': 'parent',
            'joinedAt': Timestamp.now(),
          });

          await familyDoc.reference.update({
            'members': members,
          });

          // 사용자 정보에 familyUid 업데이트
          await FirebaseFirestore.instance.collection('Users').doc(userId).update({
            'familyUid': familyData['familyUid'],
          });
        }
      }

      // 로컬 상태 업데이트
      if (_family != null && _family!.id == familyId) {
        final updatedInvitations = invitations.map((invite) => FamilyInvitation.fromMap(invite)).toList();
        _family = FamilyModel(
          id: _family!.id,
          familyUid: _family!.familyUid,
          familyName: _family!.familyName,
          familyLeaderId: _family!.familyLeaderId,
          members: _family!.members,
          invitations: updatedInvitations,
          createdAt: _family!.createdAt,
          createdBy: _family!.createdBy,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}