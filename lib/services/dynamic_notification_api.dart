import 'dart:convert';
import 'package:http/http.dart' as http;

class DynamicNotificationApiService {
  static const String _baseUrl = 'https://member.rspcoop.com/api/v1/loan';

  /// ดึงการแจ้งเตือนของสมาชิก
  static Future<List<Map<String, dynamic>>> getNotifications(String memberId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'notifications',
        'filter': {'memberid': memberId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get notifications: ${response.body}');
    }
  }

  /// สร้างการแจ้งเตือน
  static Future<void> createNotification({
    required String memberId,
    required String title,
    required String message,
    required String type, // info, success, warning, error
  }) async {
    final now = DateTime.now();
    final data = {
      'notificationid': 'notif_${now.millisecondsSinceEpoch}',
      'memberid': memberId,
      'title': title,
      'message': message,
      'type': type,
      'isread': false,
      'created_at': now.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'notifications',
        'data': data,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create notification: ${response.body}');
    }
  }

  /// อ่านการแจ้งเตือนแล้ว
  static Future<void> markAsRead(String notificationId) async {
    await http.post(
      Uri.parse('$_baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'notifications',
        'filter': {'notificationid': notificationId},
        'data': {'isread': true},
      }),
    );
  }
}
