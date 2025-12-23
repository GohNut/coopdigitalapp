import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? route; // Route to navigate when tapped

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.info,
    this.route,
  });

  factory NotificationModel.now({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? route,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      route: route,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Extract _id - MongoDB returns it as a string in most cases
    String notificationId;
    if (json['_id'] is Map) {
      // Extended JSON format: {"$oid": "..."}
      notificationId = json['_id']['\$oid'];
    } else {
      // Simple string format
      notificationId = json['_id'].toString();
    }
    
    return NotificationModel(
      id: notificationId,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] is Map ? json['created_at']['\$date'] : json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: _typeFromString(json['type'] ?? 'info'),
      route: json['route'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': typeToString(type),
      if (route != null) 'route': route,
    };
  }

  static NotificationType _typeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'success':
        return NotificationType.success;
      case 'warning':
        return NotificationType.warning;
      case 'error':
        return NotificationType.error;
      default:
        return NotificationType.info;
    }
  }

  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'success';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.error:
        return 'error';
      case NotificationType.info:
        return 'info';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    String? route,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      route: route ?? this.route,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return LucideIcons.info;
      case NotificationType.success:
        return LucideIcons.checkCircle;
      case NotificationType.warning:
        return LucideIcons.alertTriangle;
      case NotificationType.error:
        return LucideIcons.xCircle;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
    }
  }
}
