import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class DynamicShareApiService {
  
  /// ดึงข้อมูลหุ้นสหกรณ์ของสมาชิก
  /// Returns: Map containing share info for the member
  static Future<Map<String, dynamic>> getShareInfo(String memberId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'share_accounts',
        'filter': {'memberid': memberId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List && (result['data'] as List).isNotEmpty) {
        return (result['data'] as List).first;
      }
      // ถ้าไม่มีข้อมูล ให้สร้างบัญชีเริ่มต้น
      return _createDefaultShareAccount(memberId);
    } else {
      throw Exception('Failed to get share info: ${response.body}');
    }
  }

  /// สร้างบัญชีหุ้นเริ่มต้นถ้ายังไม่มี
  static Future<Map<String, dynamic>> _createDefaultShareAccount(String memberId) async {
    final defaultAccount = {
      'memberid': memberId,
      'totalunits': 0,
      'totalvalue': 0.0,
      'monthlyrate': 0.0,
      'shareparvalue': 50.0,
      'dividendrate': 5.0,
      'minshareholding': 100,
      'createdat': DateTime.now().toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'share_accounts',
        'data': defaultAccount,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return defaultAccount;
    } else {
      throw Exception('Failed to create default share account: ${response.body}');
    }
  }

  /// ซื้อหุ้นเพิ่ม
  /// Creates a transaction and updates the member's share account
  static Future<Map<String, dynamic>> buyShare({
    required String memberId,
    required int units,
    required double amount,
    required String paymentMethod,
    required String paymentSourceId,
  }) async {
    final transactionId = 'SHR-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // 1. บันทึกรายการซื้อหุ้นใน share_transactions
    final transactionData = {
      'transactionid': transactionId,
      'memberid': memberId,
      'type': 'buy',
      'units': units,
      'amount': amount,
      'paymentmethod': paymentMethod,
      'paymentsourceid': paymentSourceId,
      'status': 'completed',
      'createdat': now.toIso8601String(),
    };

    final transactionResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'share_transactions',
        'data': transactionData,
      }),
    );

    if (transactionResponse.statusCode != 201 && transactionResponse.statusCode != 200) {
      throw Exception('Failed to create share transaction: ${transactionResponse.body}');
    }

    // 2. อัพเดทยอดหุ้นในบัญชี share_accounts
    final currentShare = await getShareInfo(memberId);
    final newTotalUnits = (currentShare['totalunits'] ?? 0) + units;
    final newTotalValue = (currentShare['totalvalue'] ?? 0.0) + amount;

    final updateResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'share_accounts',
        'filter': {'memberid': memberId},
        'data': {
          'totalunits': newTotalUnits,
          'totalvalue': newTotalValue,
          'updatedat': now.toIso8601String(),
        },
        'upsert': true,
      }),
    );

    if (updateResponse.statusCode == 200) {
      return {
        'status': 'success',
        'transactionId': transactionId,
        'newTotalUnits': newTotalUnits,
        'newTotalValue': newTotalValue,
      };
    } else {
      throw Exception('Failed to update share account: ${updateResponse.body}');
    }
  }

  /// ดึงประวัติการซื้อหุ้น
  static Future<Map<String, dynamic>> getShareHistory(String memberId, {int? limit, int? skip}) async {
    final body = {
      'collection': 'share_transactions',
      'filter': {'memberid': memberId},
    };
    if (limit != null) body['limit'] = limit;
    if (skip != null) body['skip'] = skip;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get share history: ${response.body}');
    }
  }

  /// ดึงข้อมูลประเภทหุ้นทั้งหมด
  static Future<List<Map<String, dynamic>>> getShareTypes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/share/list'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get share types: ${response.body}');
    }
  }

  /// สร้างประเภทหุ้นใหม่ (สำหรับเจ้าหน้าที่)
  static Future<Map<String, dynamic>> createShareType(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/share/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create share type: ${response.body}');
    }
  }

  /// แก้ไขประเภทหุ้น (สำหรับเจ้าหน้าที่)
  static Future<Map<String, dynamic>> updateShareType(String id, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/share/update/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update share type: ${response.body}');
    }
  }

  /// ลบประเภทหุ้น (Soft delete) (สำหรับเจ้าหน้าที่)
  static Future<void> deleteShareType(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/share/delete/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete share type: ${response.body}');
    }
  }
}
