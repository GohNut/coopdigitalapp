import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/notification_model.dart';
import '../../data/notification_repository.dart';

final notificationProvider = NotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationNotifier extends Notifier<List<NotificationModel>> {
  late final NotificationRepository _repository;

  @override
  List<NotificationModel> build() {
    _repository = NotificationRepository();
    // Start with empty or load
    _loadNotifications();
    return [];
  }


  Future<void> _loadNotifications() async {
    // Initial load (empty for now as requested, or from storage in real app)
    state = [];
  }

  Future<void> addNotification(NotificationModel notification) async {
    // Add to top list
    state = [notification, ...state];
    // In real app: await _repository.addNotification(notification);
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
    // In real app: await _repository.markAsRead(id);
  }
  
  Future<void> markAllAsRead() async {
    state = [
      for (final notification in state)
        notification.copyWith(isRead: true)
    ];
  }
}
