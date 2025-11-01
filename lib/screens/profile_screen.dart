// lib/screens/profile_screen.dart
// 내 정보 화면입니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../utils/constants.dart';
import '../widgets/family_invite_widget.dart';
import '../services/auth_service.dart';
import '../widgets/cached_image_widget.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart'; // 임시 제거 (MissingPluginException 해결 후 복원)
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/file_upload_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
      ),
      body: Consumer2<UserProvider, FamilyProvider>(
        builder: (context, userProvider, familyProvider, child) {
          if (userProvider.isLoading || familyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.user == null) {
            return const Center(child: Text('로그인이 필요합니다.'));
          }

          final user = userProvider.user;
          final family = familyProvider.family;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 섹션
                _buildProfileSection(context, user),
                const SizedBox(height: 32),

                // 가족 정보 섹션
                _buildFamilySection(context, family),
                const SizedBox(height: 32),

                // 설정 섹션
                _buildSettingsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로필',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 프로필 사진
              GestureDetector(
                onTap: () => _onChangeAvatar(context, user),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: user?.profileImageUrl != null &&
                                user!.profileImageUrl!.isNotEmpty
                            ? CachedImageWidget(
                                imageUrl: user.profileImageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.primaryLight,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname ?? '닉네임 없음',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '이메일 없음',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(BuildContext context, dynamic family) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가족 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (family != null) ...[
            // 가족 이름
            _buildInfoRow('가족 이름', family.familyName ?? '없음'),
            const SizedBox(height: 12),

            // 가족 UID (초대 버튼 포함)
            _buildFamilyUidRow(context, family.familyUid ?? '없음'),
            const SizedBox(height: 12),

            // 가족 대표
            _buildInfoRow('가족 대표', family.familyLeader?.name ?? '없음'),
            const SizedBox(height: 12),

            // 가족 멤버 수
            _buildInfoRow('가족 멤버', '${family.members?.length ?? 0}명'),
            const SizedBox(height: 16),

            // 가족 멤버 목록
            if (family.members != null && family.members!.isNotEmpty) ...[
              Text(
                '등록된 가족들',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: family.members!.length,
                itemBuilder: (context, index) {
                  final member = family.members![index];
                  final isLeader = family.familyLeaderId == member.userId;
                  return _buildMemberCard(member, isLeader: isLeader);
                },
              ),
              const SizedBox(height: 16),
              // 가족 초대 버튼
              ElevatedButton.icon(
                onPressed: () {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  FamilyInviteWidget.showInviteDialog(
                    context: context,
                    familyUid: family.familyUid,
                    familyName: family.familyName,
                    userName: userProvider.user?.nickname ?? '사용자',
                  );
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('가족 초대하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '가족에 속해있지 않습니다.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyUidRow(BuildContext context, String familyUid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '고유번호',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: familyUid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('가족 UID가 복사되었습니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          child: Row(
            children: [
              Text(
                familyUid,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 32),
              Icon(Icons.copy, size: 18, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('복사',
                  style: TextStyle(
                      color: AppColors.textLight, fontWeight: FontWeight.w700)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(dynamic member, {bool isLeader = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLeader ? AppColors.primaryLight : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLeader ? AppColors.primary : AppColors.border,
          width: isLeader ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // 멤버 프로필 사진
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: ClipOval(
              child: member.profileImageUrl != null &&
                      member.profileImageUrl.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: member.profileImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // 멤버 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name ?? '이름 없음',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '대표',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.role ?? '역할 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _onChangeAvatar(BuildContext context, dynamic user) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (picked == null) return;

      // 임시로 크롭 기능 제거 (MissingPluginException 해결 후 복원 예정)
      // 압축만 수행
      final String target = '${picked.path}_compressed.jpg';
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        target,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );
      final File fileToUpload = File((compressed?.path ?? picked.path));

      // 업로드 (기존 파일 업로드 서비스 재활용)
      final uploadService = FileUploadService();
      final result = await uploadService.uploadFile(XFile(fileToUpload.path));
      final viewUrl = (result != null && result['view_url'] != null)
          ? uploadService.getViewUrl(result['view_url'])
          : null;
      if (viewUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('업로드 실패')));
        }
        return;
      }

      // 사용자 문서 업데이트
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({'profileImageUrl': viewUrl});

      // UserProvider는 스트림으로 갱신되므로 별도 호출 불필요

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('프로필이 변경되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('프로필 변경 실패: $e')));
      }
    }
  }
}
