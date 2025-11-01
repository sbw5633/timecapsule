// lib/widgets/family_invite_widget.dart
// 가족 초대 기능을 담당하는 위젯입니다.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyInviteWidget {
  static void showInviteDialog({
    required BuildContext context,
    required String familyUid,
    required String familyName,
    required String userName,
  }) {
    // 초대 메시지 생성
    final message = '''
안녕하세요! $userName님이 Time Capsule 앱에서 가족을 초대합니다.

가족명칭: $familyName
가족 UID: $familyUid

앱을 다운로드하고 위 UID를 입력하여 가족에 참여해주세요!
''';

    // 카카오톡 공유 URL 생성
    final kakaoUrl = 'https://story.kakao.com/share?url=${Uri.encodeComponent('https://timecapsule.app')}&text=${Uri.encodeComponent(message)}';
    
    // 문자 메시지 공유 URL 생성
    final smsUrl = 'sms:?body=${Uri.encodeComponent(message)}';

    // 공유 옵션 선택 다이얼로그
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
                  if (context.mounted) {
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
                  if (context.mounted) {
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
