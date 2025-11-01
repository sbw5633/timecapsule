// lib/screens/auth_screen.dart
// 로그인/회원가입 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    if (!_isLogin && _nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      Map<String, dynamic> result;
      
      if (_isLogin) {
        result = await authService.signInWithEmail(_emailController.text, _passwordController.text);
      } else {
        result = await authService.signUpWithEmail(_emailController.text, _passwordController.text, _nicknameController.text, 'default_profile.png');
      }

      if (result['success'] && mounted) {
        // Firebase Auth의 현재 사용자 가져오기
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // UserProvider에 Firebase 사용자 설정
          userProvider.setFirebaseUser(currentUser);
          
          if (_isLogin) {
            // 로그인의 경우 Firestore에서 사용자 정보 가져와서 설정
            final userData = await authService.getUserData(currentUser.uid);
            if (userData != null) {
              userProvider.setUser(userData);
            } else {
              // Firestore에 사용자 정보가 없는 경우 기본 정보로 생성
              final userModel = UserModel(
                uid: currentUser.uid,
                email: currentUser.email ?? '',
                password: '', // 로그인 시에는 비밀번호를 저장하지 않음
                nickname: currentUser.displayName ?? '사용자',
                profileImageUrl: currentUser.photoURL ?? 'default_profile.png',
                familyUid: null,
                createdAt: Timestamp.now(),
              );
              userProvider.setUser(userModel);
            }
          } else {
            // 회원가입의 경우 새로 생성된 사용자 정보로 설정
            final userModel = UserModel(
              uid: currentUser.uid,
              email: _emailController.text,
              password: _passwordController.text,
              nickname: _nicknameController.text,
              profileImageUrl: 'default_profile.png',
              familyUid: null,
              createdAt: Timestamp.now(),
            );
            userProvider.setUser(userModel);
          }
          
          // familyUid 여부에 따라 화면 이동
          if (userProvider.familyUid != null) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/timeline');
            }
          } else {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/familyRegistration');
            }
          }
        }
      } else if (mounted) {
        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? '알 수 없는 오류가 발생했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 구글 로그인 버튼 (정사각형)
  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : () => _handleSocialLogin('google'),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.g_mobiledata,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 카카오 로그인 버튼 (정사각형)
  Widget _buildKakaoLoginButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : () => _handleSocialLogin('kakao'),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat,
            size: 12,
            color: Color(0xFFFEE500),
          ),
        ),
      ),
    );
  }

  // 애플 로그인 버튼 (정사각형)
  Widget _buildAppleLoginButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : () => _handleSocialLogin('apple'),
        child: const Icon(
          Icons.apple,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  // 소셜 로그인 처리
  void _handleSocialLogin(String provider) async {
    final authService = AuthService();
    Map<String, dynamic> result;

    try {
      switch (provider) {
        case 'google':
          result = await authService.signInWithGoogle();
          break;
        case 'kakao':
          result = await authService.signInWithKakao();
          break;
        case 'apple':
          result = await authService.signInWithApple();
          break;
        default:
          return;
      }

      if (!mounted) return;

      if (result['success']) {
        // 로그인 성공 시 UserProvider 업데이트
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(result['user'].user);
        
        // 타임라인으로 이동
        Navigator.pushReplacementNamed(context, '/timeline');
      } else {
        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Time Capsule',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '가족과 함께 특별한 순간을 기록하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _emailController,
                labelText: '이메일',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: '비밀번호',
                obscureText: true,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nicknameController,
                  labelText: '닉네임',
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isLoading 
                  ? (_isLogin ? '로그인 중...' : '회원가입 중...') 
                  : (_isLogin ? '로그인' : '회원가입'),
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(_isLogin ? '회원가입하기' : '로그인하기'),
              ),
              const SizedBox(height: 24),
              //소셜 로그인
              Column(
                children: [
                  const Text(
                    '또는',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGoogleLoginButton(),
                      const SizedBox(width: 12),
                      _buildKakaoLoginButton(),
                      const SizedBox(width: 12),
                      _buildAppleLoginButton(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
