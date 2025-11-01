// lib/services/s3_service.dart
// [사용 안 함] 이 파일은 더 이상 사용되지 않습니다.
// 모든 파일 업로드는 FileUploadService를 통해 files.whiteagent-w.kr을 사용합니다.
// Amazon S3에 파일(사진, 동영상)을 업로드하고 URL을 가져오는 서비스입니다.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

class S3Service {
  // TODO: S3 설정 정보를 여기에 입력하세요.
  // AWS 자격 증명 및 버킷 이름을 여기에 설정해야 합니다.
  final String _accessKey = 'YOUR_AWS_ACCESS_KEY';
  final String _secretKey = 'YOUR_AWS_SECRET_KEY';
  final String _region = 'YOUR_AWS_REGION'; // 예: 'ap-northeast-2' (서울)
  final String _bucketName = 'YOUR_S3_BUCKET_NAME';

  late final Dio _dio;

  S3Service() {
    _dio = Dio();
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));
  }

  Future<String?> uploadFile(File file, String familyId, String fileType) async {
    try {
      final String fileExtension = file.path.split('.').last;
      final String fileName = const Uuid().v4();
      final String key = 'Families/$familyId/$fileType/$fileName.$fileExtension';
      
      // 파일을 바이트로 읽기
      final bytes = await file.readAsBytes();
      
      // AWS S3에 직접 업로드
      final response = await _dio.post(
        'https://$_bucketName.s3.$_region.amazonaws.com/',
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': _getContentType(fileExtension),
            'x-amz-content-sha256': sha256.convert(bytes).toString(),
          },
        ),
        queryParameters: {
          'key': key,
        },
      );

      if (response.statusCode == 200) {
        // S3에 업로드된 객체의 URL을 반환합니다.
        return 'https://$_bucketName.s3.$_region.amazonaws.com/$key';
      } else {
        print('파일 업로드 실패: HTTP Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('파일 업로드 중 오류 발생: $e');
      return null;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}