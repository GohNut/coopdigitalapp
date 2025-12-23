import '../domain/notification_model.dart';
import '../../../services/notification_api_service.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(String userId) async {
    return await NotificationApiService.getNotifications(userId);
  }

  Future<void> markAsRead(String userId, String id) async {
    await NotificationApiService.markAsRead(
      memberId: userId,
      notificationId: id,
    );
  }

  Future<void> addNotification(String userId, NotificationModel notification) async {
    await NotificationApiService.addNotification(
      memberId: userId,
      title: notification.title,
      message: notification.message,
      type: NotificationModel.typeToString(notification.type),
      route: notification.route,
    );
  }

  Future<void> clearNotifications(String userId) async {
    await NotificationApiService.clearNotifications(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    await NotificationApiService.markAllAsRead(userId);
  }
}
