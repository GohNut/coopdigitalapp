import '../domain/notification_model.dart';

class NotificationRepository {
  // Mock data - Empty by default as requested
  static final List<NotificationModel> _notifications = [];

  Future<List<NotificationModel>> getNotifications() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_notifications); // Return copy
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // In a real app we would update the server
      // Here we just replace the item with isRead = true
      // Since fields are final, we can't just set isRead = true
      // We would implementation copyWith, but for mock let's just ignore for now or simulate success
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
  }
}
