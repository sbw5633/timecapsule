// lib/providers/story_provider.dart
// 스토리 목록의 상태를 관리하는 Provider입니다.

import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class StoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService.instance;
  List<StoryModel> _stories = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _currentFamilyUid;

  List<StoryModel> get stories => _stories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void initialize(String familyUid) {
    if (_isInitialized && _currentFamilyUid == familyUid) return;
    
    print('StoryProvider 초기화 시작: $familyUid');
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
      print('StoryProvider 초기화 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로컬 캐시에서 데이터 로드
  Future<void> _loadFromCache(String familyUid) async {
    try {
      final cachedStories = await _localStorage.loadStories(familyUid);
      if (cachedStories.isNotEmpty) {
        print('로컬 캐시에서 ${cachedStories.length}개 스토리 로드');
        _stories = cachedStories;
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
      // Firestore에서 스토리 스트림 구독 (변경사항만 받음)
      _firestoreService.getStories(familyUid).listen(
        (networkStories) async {
          // 업데이트가 있는지 확인 (개수나 내용이 다르면 업데이트)
          final hasUpdate = _hasUpdates(networkStories);
          
          if (hasUpdate) {
            print('네트워크에서 ${networkStories.length}개 스토리 수신 (업데이트 감지)');
            
            // 로컬 캐시에 저장
            await _localStorage.saveStories(networkStories);
            
            // 마지막 동기화 시간 업데이트
            await _localStorage.updateLastSyncTime('stories_$familyUid', DateTime.now().millisecondsSinceEpoch);
            
            // UI 업데이트
            _stories = networkStories;
            _isLoading = false;
            notifyListeners();
          } else {
            print('스토리 업데이트 없음 - 캐시 유지');
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
  bool _hasUpdates(List<StoryModel> networkStories) {
    if (networkStories.length != _stories.length) return true;
    
    // ID로 비교하여 변경 확인
    final cachedIds = _stories.map((s) => s.id).toSet();
    final networkIds = networkStories.map((s) => s.id).toSet();
    
    if (cachedIds != networkIds) return true;
    
    // 각 스토리의 업데이트 시간 비교
    for (final networkStory in networkStories) {
      final cachedStory = _stories.firstWhere(
        (s) => s.id == networkStory.id,
        orElse: () => networkStory,
      );
      
      if (cachedStory.createdAt != networkStory.createdAt) {
        return true;
      }
    }
    
    return false;
  }

  // 수동 새로고침
  Future<void> refresh() async {
    if (_currentFamilyUid == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 캐시 무효화 후 다시 로드
      await _localStorage.clearCache();
      await _initializeAsync(_currentFamilyUid!);
    } catch (error) {
      print('새로고침 에러: $error');
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _stories = [];
    _isLoading = false;
    _isInitialized = false;
    _currentFamilyUid = null;
    notifyListeners();
  }
}
