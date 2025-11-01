// lib/services/auth_service.dart
// Firebase Auth와 관련된 로직을 처리하는 서비스입니다.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  // 사용자 친화적인 오류 메시지 생성
  String _getUserFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase 설정이 완료되지 않았습니다.\n\n해결 방법:\n1. google-services.json 파일이 android/app/ 폴더에 있는지 확인\n2. Firebase Console에서 프로젝트 설정 확인\n3. 앱을 다시 시작해보세요';
      
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 6자 이상으로 설정해주세요.';
      
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      
      case 'operation-not-allowed':
        return '이 작업이 허용되지 않습니다.';
      
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.\n\n확인사항:\n• 이메일 주소를 정확히 입력했는지 확인\n• 비밀번호를 정확히 입력했는지 확인\n• 대소문자를 구분하여 입력했는지 확인';
      
      case 'account-exists-with-different-credential':
        return '다른 방법으로 가입된 계정입니다.';
      
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인해주세요.';
      
      default:
        // Firebase Auth 오류 메시지에서 더 구체적인 정보 추출
        if (e.message != null && e.message!.isNotEmpty) {
          return '오류가 발생했습니다: ${e.message}';
        }
        return '오류가 발생했습니다: ${e.code}';
    }
  }

  // 이메일로 회원가입
  Future<Map<String, dynamic>> signUpWithEmail(String email, String password, String nickname, String profileImageUrl) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        // UserModel 구조에 맞게 Firestore에 사용자 정보 저장
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          password: password,
          nickname: nickname,
          profileImageUrl: profileImageUrl,
          familyUid: null, // 가족 등록 시 설정됨
          createdAt: Timestamp.now(),
        );
        
        await _db.collection('Users').doc(userCredential.user!.uid).set(userModel.toFirestore());
      }
      
      return {'success': true, 'user': userCredential};
    } catch (e) {
      String errorMessage = '알 수 없는 오류가 발생했습니다.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getUserFriendlyErrorMessage(e);
      } else {
        // 기타 오류 처리
        if (e.toString().contains('email address is badly formatted')) {
          errorMessage = '올바른 이메일 형식이 아닙니다.';
        } else if (e.toString().contains('Password should be at least 6 characters')) {
          errorMessage = '비밀번호가 너무 약합니다. 6자 이상으로 설정해주세요.';
        } else if (e.toString().contains('network')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        } else {
          errorMessage = '오류가 발생했습니다: ${e.toString()}';
        }
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // 이메일로 로그인
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // 로그인 성공 후 사용자 문서 확인 및 생성
      if (userCredential.user != null) {
        try {
          final userDoc = await _db.collection('Users').doc(userCredential.user!.uid).get();
          if (!userDoc.exists) {
            // 사용자 문서가 없으면 새로 생성
            final userModel = UserModel(
              uid: userCredential.user!.uid,
              email: userCredential.user!.email ?? '',
              password: '', // 보안상 비밀번호는 저장하지 않음
              nickname: userCredential.user!.displayName ?? '사용자',
              profileImageUrl: userCredential.user!.photoURL ?? 'default_profile.png',
              familyUid: null,
              createdAt: Timestamp.now(),
            );
            await _db.collection('Users').doc(userCredential.user!.uid).set(userModel.toFirestore());
          }
        } catch (e) {
          print('사용자 문서 확인/생성 오류: $e');
        }
      }
      
      return {'success': true, 'user': userCredential};
    } catch (e) {
      String errorMessage = '알 수 없는 오류가 발생했습니다.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getUserFriendlyErrorMessage(e);
      } else if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        errorMessage = 'Firebase 설정이 완료되지 않았습니다.\n\n해결 방법:\n1. google-services.json 파일이 android/app/ 폴더에 있는지 확인\n2. Firebase Console에서 프로젝트 설정 확인\n3. 앱을 다시 시작해보세요';
      } else {
        // 기타 오류 처리
        if (e.toString().contains('user-not-found')) {
          errorMessage = '등록되지 않은 이메일입니다.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = '비밀번호가 올바르지 않습니다.';
        } else if (e.toString().contains('network')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        } else {
          errorMessage = '오류가 발생했습니다: ${e.toString()}';
        }
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 사용자 정보 가져오기 (Firestore에서)
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 사용자 정보 업데이트
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('Users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 구글 로그인
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 구글 로그인 실행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': '구글 로그인이 취소되었습니다.'};
      }

      // 구글 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Firebase 인증 정보 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // 사용자 문서 확인 및 생성 (오류가 있어도 로그인은 계속 진행)
        try {
          await _createOrUpdateUserDocument(userCredential.user!);
        } catch (e) {
          print('Firestore 사용자 문서 생성 실패, 하지만 로그인은 계속 진행: $e');
        }
      }

      return {'success': true, 'user': userCredential};
    } catch (e) {
      String errorMessage = '구글 로그인 중 오류가 발생했습니다.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getUserFriendlyErrorMessage(e);
      } else {
        errorMessage = '구글 로그인 오류: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // 카카오 로그인
  Future<Map<String, dynamic>> signInWithKakao() async {
    try {
      // 카카오 로그인 실행
      await kakao.UserApi.instance.loginWithKakaoAccount();
      
      // 사용자 정보 가져오기
      kakao.User kakaoUser = await kakao.UserApi.instance.me();
      
      // Firebase 커스텀 토큰 생성 (서버에서 처리해야 함)
      // 여기서는 임시로 이메일/비밀번호 방식으로 처리
      String email = kakaoUser.kakaoAccount?.email ?? '${kakaoUser.id}@kakao.com';
      String password = 'kakao_${kakaoUser.id}'; // 임시 비밀번호
      
      try {
        // 기존 계정으로 로그인 시도
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          await _createOrUpdateUserDocument(userCredential.user!);
        }
        
        return {'success': true, 'user': userCredential};
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
          // 계정이 없으면 새로 생성
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (userCredential.user != null) {
            await _createOrUpdateUserDocument(userCredential.user!);
          }
          
          return {'success': true, 'user': userCredential};
        } else {
          rethrow;
        }
      }
    } catch (e) {
      String errorMessage = '카카오 로그인 중 오류가 발생했습니다.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getUserFriendlyErrorMessage(e);
      } else {
        errorMessage = '카카오 로그인 오류: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // 애플 로그인
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      // 애플 로그인 실행
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase 인증 정보 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Firebase에 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      
      if (userCredential.user != null) {
        // 사용자 문서 확인 및 생성 (오류가 있어도 로그인은 계속 진행)
        try {
          await _createOrUpdateUserDocument(userCredential.user!);
        } catch (e) {
          print('Firestore 사용자 문서 생성 실패, 하지만 로그인은 계속 진행: $e');
        }
      }

      return {'success': true, 'user': userCredential};
    } catch (e) {
      String errorMessage = '애플 로그인 중 오류가 발생했습니다.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getUserFriendlyErrorMessage(e);
      } else {
        errorMessage = '애플 로그인 오류: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // 사용자 문서 생성 또는 업데이트
  Future<void> _createOrUpdateUserDocument(User firebaseUser) async {
    try {
      final userDoc = await _db.collection('Users').doc(firebaseUser.uid).get();
      
      if (!userDoc.exists) {
        // 사용자 문서가 없으면 새로 생성
        final userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          password: '', // 소셜 로그인은 비밀번호 없음
          nickname: firebaseUser.displayName ?? '사용자',
          profileImageUrl: firebaseUser.photoURL ?? 'default_profile.png',
          familyUid: null,
          createdAt: Timestamp.now(),
        );
        
        await _db.collection('Users').doc(firebaseUser.uid).set(userModel.toFirestore());
        print('사용자 문서 생성 성공: ${firebaseUser.uid}');
      } else {
        print('사용자 문서 이미 존재: ${firebaseUser.uid}');
      }
    } catch (e) {
      print('사용자 문서 생성/업데이트 오류: $e');
      // Firestore 오류가 있어도 로그인은 계속 진행
      // 나중에 다시 시도하거나 다른 방법으로 처리
    }
  }

  // 소셜 로그인 로그아웃
  Future<void> signOutSocial() async {
    try {
      await _auth.signOut();
      
      // 구글 로그아웃
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // 카카오 로그아웃
      try {
        await kakao.UserApi.instance.logout();
      } catch (e) {
        print('카카오 로그아웃 오류: $e');
      }
    } catch (e) {
      print('소셜 로그아웃 오류: $e');
    }
  }
}
