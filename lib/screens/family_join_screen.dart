// lib/screens/family_join_screen.dart
// 가족 조인 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyJoinScreen extends StatefulWidget {
  const FamilyJoinScreen({super.key});

  @override
  State<FamilyJoinScreen> createState() => _FamilyJoinScreenState();
}

class _FamilyJoinScreenState extends State<FamilyJoinScreen> {
  final TextEditingController _familyUidController = TextEditingController();
  bool _isLoading = false;
  bool _showConfirmSection = false;
  String? _familyName;

  @override
  void dispose() {
    _familyUidController.dispose();
    super.dispose();
  }

  void _checkFamily() async {
    if (_familyUidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족 UID를 입력해주세요.')),
      );
      return;
    }

    if (_familyUidController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족 UID는 6자리여야 합니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firestore에서 가족 정보 확인
      final familyQuery = await FirebaseFirestore.instance
          .collection('Families')
          .where('familyUid', isEqualTo: _familyUidController.text)
          .get();

      if (familyQuery.docs.isNotEmpty) {
        final familyData = familyQuery.docs.first.data();
        setState(() {
          _familyName = familyData['familyName'] as String?;
          _showConfirmSection = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 가족을 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가족 확인 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _joinFamily() async {
    if (_familyUidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족 UID를 입력해주세요.')),
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

      // 가족 참여
      await familyProvider.joinFamily(
        familyUid: _familyUidController.text,
        userId: userProvider.user!.uid,
        userName: userProvider.user!.nickname,
        userEmail: userProvider.user!.email,
        profileImageUrl: userProvider.user!.profileImageUrl,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족에 참여했습니다!')),
      );

      Navigator.pushReplacementNamed(context, '/timeline');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가족 참여 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가족 참여'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              '가족에 참여하기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '가족 UID를 입력하여\n기존 가족에 참여할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _familyUidController,
              labelText: '가족 UID (6자리)',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            if (!_showConfirmSection) ...[
              PrimaryButton(
                text: _isLoading ? '확인 중...' : '가족 확인하기',
                onPressed: _isLoading ? null : _checkFamily,
              ),
            ] else ...[
              // 가족 확인 완료 후 조인 섹션
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      color: AppColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '가족을 찾았습니다!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '가족명칭: $_familyName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '이 가족에 참여하시겠습니까?',
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
                text: _isLoading ? '참여 중...' : '가족 참여하기',
                onPressed: _isLoading ? null : _joinFamily,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
