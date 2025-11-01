// lib/providers/user_provider.dart
// 현재 로그인한 사용자의 상태를 관리하는 Provider입니다.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;
  User? _firebaseUser;
  bool _isLoading = true;

  UserModel? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;

  UserProvider() {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    // 현재 Firebase Auth 상태 확인
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _firebaseUser = currentUser;
      _loadUserData(currentUser.uid);
    }

    // Firebase Auth 상태 변화 감지
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadUserData(String uid) {
    _isLoading = true;
    notifyListeners();
    
    _firestoreService.getUser(uid).listen(
      (userData) {
        if (userData != null) {
          _user = userData;
          _isLoading = false;
          notifyListeners();
        } else {
          // 사용자 데이터가 없으면 새로 생성
          _createUserDocument(uid);
        }
      },
      onError: (error) {
        // 오류 발생 시에도 사용자 문서 생성 시도
        _createUserDocument(uid);
      },
    );
  }

  // Firestore에 사용자 문서가 없을 때 새로 생성
  Future<void> _createUserDocument(String uid) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userModel = UserModel(
          uid: uid,
          email: currentUser.email ?? '',
          password: '', // 보안상 비밀번호는 저장하지 않음
          nickname: currentUser.displayName ?? '사용자',
          profileImageUrl: currentUser.photoURL ?? 'default_profile.png',
          familyUid: null,
          createdAt: Timestamp.now(),
        );

        // Firestore에 사용자 문서 생성
        await _firestore.collection('Users').doc(uid).set(userModel.toFirestore());
        
        _user = userModel;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('사용자 문서 생성 오류: $e');
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 정보를 직접 설정하는 메서드
  void setUser(UserModel user) {
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  // Firebase 사용자를 설정하는 메서드
  void setFirebaseUser(User firebaseUser) {
    _firebaseUser = firebaseUser;
    notifyListeners();
  }

  // 로딩 상태를 설정하는 메서드
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String? get familyUid => _user?.familyUid;
}
