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
