// lib/screens/family_registration_screen.dart
// 가족 등록 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyRegistrationScreen extends StatefulWidget {
  const FamilyRegistrationScreen({super.key});

  @override
  State<FamilyRegistrationScreen> createState() => _FamilyRegistrationScreenState();
}

class _FamilyRegistrationScreenState extends State<FamilyRegistrationScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  bool _isLoading = false;
  String? _generatedFamilyUid;
  String? _familyName;
  bool _showFamilyCreationForm = false;
  bool _familyCreated = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  void _displayFamilyCreationForm() {
    setState(() {
      _showFamilyCreationForm = true;
    });
  }

  void _goToFamilyJoin() {
    Navigator.pushNamed(context, '/familyJoin');
  }

  void _createFamily() async {
    if (_familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족명칭을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      
      if (userProvider.user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // 가족 생성
      final familyUid = await familyProvider.createFamily(
        familyName: _familyNameController.text,
        userId: userProvider.user!.uid,
        userName: userProvider.user!.nickname,
        userEmail: userProvider.user!.email,
        profileImageUrl: userProvider.user!.profileImageUrl,
      );

      if (mounted) {
        setState(() {
          _generatedFamilyUid = familyUid;
          _familyName = _familyNameController.text;
          _familyCreated = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가족이 생성되었습니다! 가족 UID: $familyUid')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가족 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _shareFamilyInvitation() async {
    if (_generatedFamilyUid == null || _familyName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족 정보가 없습니다.')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.user?.nickname ?? '사용자';
    
    // 초대 메시지 생성
    final message = '''
안녕하세요! $userName님이 Time Capsule 앱에서 가족을 초대합니다.

가족명칭: $_familyName
가족 UID: $_generatedFamilyUid

앱을 다운로드하고 위 UID를 입력하여 가족에 참여해주세요!
''';

    // 카카오톡 공유 URL 생성
    final kakaoUrl = 'https://story.kakao.com/share?url=${Uri.encodeComponent('https://timecapsule.app')}&text=${Uri.encodeComponent(message)}';
    
    // 문자 메시지 공유 URL 생성
    final smsUrl = 'sms:?body=${Uri.encodeComponent(message)}';

    // 공유 옵션 선택 다이얼로그
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('가족 초대하기'),
            content: const Text('어떤 방법으로 초대하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (await canLaunchUrl(Uri.parse(kakaoUrl))) {
                    await launchUrl(Uri.parse(kakaoUrl));
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('카카오톡을 열 수 없습니다.')),
                      );
                    }
                  }
                },
                child: const Text('카카오톡'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (await canLaunchUrl(Uri.parse(smsUrl))) {
                    await launchUrl(Uri.parse(smsUrl));
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('문자 앱을 열 수 없습니다.')),
                      );
                    }
                  }
                },
                child: const Text('문자'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('취소'),
              ),
            ],
          );
        },
      );
    }
  }

  void _goToTimeline() {
    Navigator.pushReplacementNamed(context, '/timeline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가족 등록'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showFamilyCreationForm && !_familyCreated) ...[
              // 초기 화면 - 가족 만들기 vs 가족 등록 선택
              const SizedBox(height: 40),
              Icon(
                Icons.family_restroom,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '가족과 함께 시작하기',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '새로운 가족을 만들거나\n기존 가족에 참여할 수 있습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: '가족 만들기',
                onPressed: _displayFamilyCreationForm,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _goToFamilyJoin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '가족 등록하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else if (_showFamilyCreationForm && !_familyCreated) ...[
              // 가족 생성 폼
              const SizedBox(height: 20),
              Text(
                '새로운 가족 만들기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '가족명칭을 입력하면 6자리 가족 코드가 생성됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _familyNameController,
                labelText: '가족명칭',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isLoading ? '생성 중...' : '가족 생성하기',
                onPressed: _isLoading ? null : _createFamily,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFamilyCreationForm = false;
                    _familyNameController.clear();
                  });
                },
                child: const Text('뒤로 가기'),
              ),
            ] else if (_familyCreated) ...[
              // 가족 생성 완료 후 화면
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '가족이 생성되었습니다!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '가족명칭',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _familyName ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '가족 UID',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _generatedFamilyUid ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '이제 다른 가족을 초대하거나\n타임라인으로 이동할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '가족 초대하기',
                onPressed: _shareFamilyInvitation,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _goToTimeline,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '타임라인으로',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
