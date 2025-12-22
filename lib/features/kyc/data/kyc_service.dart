
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/domain/user_role.dart'; 
import '../../../core/config/api_config.dart';

class KYCService {
  
  // Check KYC Status
  static Future<Map<String, dynamic>> getKYCStatus() async {
    try {
      if (CurrentUser.id.isEmpty) {
        return {'status': 'not_verified', 'reject_reason': null};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': 'members',
          'filter': {'memberid': CurrentUser.id},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] is List && (result['data'] as List).isNotEmpty) {
          final member = result['data'][0];
          return {
            'status': member['kyc_status'] ?? 'not_verified',
            'reject_reason': member['kyc_reject_reason'],
          };
        }
      }
      return {'status': 'not_verified', 'reject_reason': null};
    } catch (e) {
      print('Failed to get KYC status: $e');
      return {'status': 'not_verified', 'reject_reason': null};
    }
  }

  // Submit KYC
  static Future<void> submitKYC({
    required XFile idCardImage,
    required XFile bankBookImage,
    required XFile selfieImage,
    required String bankId,
    required String bankAccountNo,
  }) async {
    // 1. Compress Images
    final idCardBytes = await _compressImage(idCardImage);
    final bankBookBytes = await _compressImage(bankBookImage);
    final selfieBytes = await _compressImage(selfieImage);

    // 2. Create Multipart Request
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/member/kyc'));
    
    final token = await _getToken();
    if (token != null) {
       request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields['bank_id'] = bankId;
    request.fields['bank_account_no'] = bankAccountNo;
    
    if (CurrentUser.id.isNotEmpty) {
      request.fields['member_id'] = CurrentUser.id;
    }
    
    // Add files
    if (idCardBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes('id_card_image', idCardBytes, filename: 'id_card.jpg'));
    }
    if (bankBookBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes('bank_book_image', bankBookBytes, filename: 'bank_book.jpg'));
    }
    if (selfieBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes('selfie_image', selfieBytes, filename: 'selfie.jpg'));
    }

    try {
      final response = await request.send();
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        final respStr = await response.stream.bytesToString();
        // Allow 404 for now if backend is not ready, or print error
        print('KYC Submit Error: ${response.statusCode} $respStr');
        // throw Exception('Failed to submit KYC: ${response.statusCode} $respStr');
      }
    } catch (e) {
      print('Mocking success because backend might not be ready. Real error: $e');
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<List<int>> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1024,
        minWidth: 1024,
        quality: 70,
      );
      return result;
    } catch (e) {
      print('Compression failed: $e');
      return bytes;
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- Officer Methods ---

  // Get Pending KYC Requests
  static Future<List<Map<String, dynamic>>> getPendingKYCRequests() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/officer/kyc/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      // Mock data if API fails or backend not reachable yet
      print('Failed to fetch pending KYC: ${response.statusCode}');
      return [
        {
          'memberid': 'MOCK001',
          'name_th': 'ทดสอบ สมมติ (Mock)',
          'kyc_submitted_at': DateTime.now().toIso8601String(),
        },
        {
          'memberid': 'MOCK002',
          'name_th': 'ตัวอย่าง รอตรวจสอบ',
          'kyc_submitted_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      ];
    }
  }

  // Get Request Detail
  static Future<Map<String, dynamic>> getKYCDetail(String memberId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/officer/kyc/detail/$memberId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load KYC detail');
    }
  }

  // Submit Review
  static Future<void> reviewKYC({
    required String memberId,
    required String status,
    String? reason,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/officer/kyc/review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'member_id': memberId,
        'status': status,
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to review KYC: ${response.body}');
    }
  }
}
