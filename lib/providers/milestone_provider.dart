// lib/providers/milestone_provider.dart
// 성장 기록의 상태를 관리하는 Provider입니다.

import 'package:flutter/material.dart';
import '../models/milestone_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class MilestoneProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService.instance;
  List<MilestoneModel> _milestones = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _currentFamilyUid;
  String? _currentChildId;

  List<MilestoneModel> get milestones => _milestones;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void initialize(String familyUid, String childId) {
    if (_isInitialized && _currentFamilyUid == familyUid && _currentChildId == childId) return;
    
    print('MilestoneProvider 초기화 시작: $familyUid / $childId');
    _isLoading = true;
    _isInitialized = true;
    _currentFamilyUid = familyUid;
    _currentChildId = childId;
    notifyListeners();
    
    _initializeAsync(familyUid, childId);
  }
  
  Future<void> _initializeAsync(String familyUid, String childId) async {
    try {
      // 먼저 로컬 캐시에서 데이터 로드
      await _loadFromCache(familyUid, childId);
      
      // 네트워크에서 최신 데이터 확인 및 동기화
      await _syncWithNetwork(familyUid, childId);
      
    } catch (error) {
      print('MilestoneProvider 초기화 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로컬 캐시에서 데이터 로드
  Future<void> _loadFromCache(String familyUid, String childId) async {
    try {
      final cachedMilestones = await _localStorage.loadMilestones(familyUid, childId);
      if (cachedMilestones.isNotEmpty) {
        print('로컬 캐시에서 ${cachedMilestones.length}개 Milestone 로드');
        _milestones = cachedMilestones;
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      print('캐시 로드 에러: $error');
    }
  }

  // 네트워크와 동기화 (업데이트만 감지)
  Future<void> _syncWithNetwork(String familyUid, String childId) async {
    try {
      // Firestore에서 Milestone 스트림 구독 (변경사항만 받음)
      _firestoreService.getMilestones(familyUid, childId).listen(
        (networkMilestones) async {
          // 업데이트가 있는지 확인 (개수나 내용이 다르면 업데이트)
          final hasUpdate = _hasUpdates(networkMilestones);
          
          if (hasUpdate) {
            print('네트워크에서 ${networkMilestones.length}개 Milestone 수신 (업데이트 감지)');
            
            // 로컬 캐시에 저장
            await _localStorage.saveMilestones(networkMilestones, familyUid, childId);
            
            // UI 업데이트
            _milestones = networkMilestones;
            _isLoading = false;
            notifyListeners();
          } else {
            print('Milestone 업데이트 없음 - 캐시 유지');
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
  bool _hasUpdates(List<MilestoneModel> networkMilestones) {
    if (networkMilestones.length != _milestones.length) return true;
    
    // ID로 비교하여 변경 확인
    final cachedIds = _milestones.map((m) => m.id).toSet();
    final networkIds = networkMilestones.map((m) => m.id).toSet();
    
    if (cachedIds != networkIds) return true;
    
    // 각 Milestone의 업데이트 시간 비교
    for (final networkMilestone in networkMilestones) {
      final cachedMilestone = _milestones.firstWhere(
        (m) => m.id == networkMilestone.id,
        orElse: () => networkMilestone,
      );
      
      if (cachedMilestone.createdAt != networkMilestone.createdAt) {
        return true;
      }
    }
    
    return false;
  }

  // 수동 새로고침
  Future<void> refresh() async {
    if (_currentFamilyUid == null || _currentChildId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _initializeAsync(_currentFamilyUid!, _currentChildId!);
    } catch (error) {
      print('새로고침 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _milestones = [];
    _isLoading = false;
    _isInitialized = false;
    _currentFamilyUid = null;
    _currentChildId = null;
    notifyListeners();
  }
}
