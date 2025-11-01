// lib/services/file_upload_service.dart
// 파일 업로드 서비스를 담당하는 클래스입니다.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  static const String _uploadUrl = 'https://files.whiteagent-w.kr/upload';
  
  // 단일 파일 업로드
  Future<Map<String, dynamic>?> uploadFile(XFile file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.name,
        ),
      );
      
      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // 응답이 배열 형태이므로 첫 번째 요소 반환
        if (responseData is List && responseData.isNotEmpty) {
          return responseData[0];
        }
        return responseData;
      } else {
        print('파일 업로드 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('파일 업로드 중 오류 발생: $e');
      return null;
    }
  }
  
  // 다중 파일 업로드
  Future<List<Map<String, dynamic>>> uploadMultipleFiles(List<XFile> files) async {
    List<Map<String, dynamic>> results = [];
    
    for (XFile file in files) {
      final result = await uploadFile(file);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  // 파일 URL 생성 (view_url 기준)
  String getViewUrl(String viewUrl) {
    if (viewUrl.startsWith('/')) {
      return 'https://files.whiteagent-w.kr$viewUrl';
    }
    return viewUrl;
  }
  
  // 다운로드 URL 생성 (download_url 기준)
  String getDownloadUrl(String downloadUrl) {
    if (downloadUrl.startsWith('/')) {
      return 'https://files.whiteagent-w.kr$downloadUrl';
    }
    return downloadUrl;
  }
}
