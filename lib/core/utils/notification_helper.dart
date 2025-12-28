import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notification/domain/notification_model.dart';
import '../../features/notification/presentation/providers/notification_provider.dart';
import '../../services/dynamic_deposit_api.dart';
import '../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationHelper {
  /// ส่งการแจ้งเตือนไปยังเจ้าหน้าที่ทุกคน
  static Future<void> notifyOfficers({
    required WidgetRef ref,
    required String title,
    required String message,
    required String type,
    String? route,
  }) async {
    try {
      // 1. ค้นหาเจ้าหน้าที่ทั้งหมด
      final officers = await _fetchAllOfficers();
      
      // 2. ส่งการแจ้งเตือนให้แต่ละคน
      for (final officer in officers) {
        final memberId = officer['memberid'];
        if (memberId != null) {
          await ref.read(notificationProvider.notifier).addNotificationToMember(
            memberId: memberId,
            notification: NotificationModel.now(
              title: title,
              message: message,
              type: _mapType(type),
              route: route,
            ),
          );
        }
      }
    } catch (e) {
      print('Error notifying officers: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAllOfficers() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'members',
        'filter': {'role': 'officer'},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
    }
    return [];
  }

  static NotificationType _mapType(String type) {
    switch (type) {
      case 'success': return NotificationType.success;
      case 'error': return NotificationType.error;
      case 'warning': return NotificationType.warning;
      default: return NotificationType.info;
    }
  }
}
