import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../features/notification/domain/notification_model.dart';

class NotificationApiService {
  static Future<List<NotificationModel>> getNotifications(String memberId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notification/get');
    
    print('🔔 [NOTIFICATION API] GET notifications for member: $memberId');
    print('🔔 [NOTIFICATION API] URL: $url');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'memberid': memberId}),
    );

    print('🔔 [NOTIFICATION API] Response status: ${response.statusCode}');
    print('🔔 [NOTIFICATION API] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        final List notificationsJson = data['data'];
        return notificationsJson.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  static Future<void> addNotification({
    required String memberId,
    required String title,
    required String message,
    required String type,
    String? route,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notification/add');
    
    final body = {
      'memberid': memberId,
      'title': title,
      'message': message,
      'type': type,
    };
    
    if (route != null) {
      body['route'] = route;
    }

    print('🔔 [NOTIFICATION API] ADD notification for member: $memberId');
    print('🔔 [NOTIFICATION API] URL: $url');
    print('🔔 [NOTIFICATION API] Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('🔔 [NOTIFICATION API] Response status: ${response.statusCode}');
    print('🔔 [NOTIFICATION API] Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add notification: ${response.statusCode}');
    }
  }

  static Future<void> markAsRead({
    required String memberId,
    required String notificationId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notification/mark-read');
    
    print('🔔 [NOTIFICATION API] MARK AS READ for member: $memberId');
    print('🔔 [NOTIFICATION API] Notification ID: $notificationId');
    print('🔔 [NOTIFICATION API] URL: $url');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'memberid': memberId,
        'notification_id': notificationId,
      }),
    );

    print('🔔 [NOTIFICATION API] Response status: ${response.statusCode}');
    print('🔔 [NOTIFICATION API] Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }

  static Future<void> markAllAsRead(String memberId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notification/mark-all-read');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'memberid': memberId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }

  static Future<void> clearNotifications(String memberId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notification/delete');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'memberid': memberId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear notifications: ${response.statusCode}');
    }
  }
}
