import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/notification_model.dart';
import '../../data/notification_repository.dart';
import '../../../auth/domain/user_role.dart';

final notificationProvider = NotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationNotifier extends Notifier<List<NotificationModel>> {
  final NotificationRepository _repository = NotificationRepository();

  @override
  List<NotificationModel> build() {
    // CurrentUser.id might be empty initially, _loadNotifications handles it.
    _loadNotifications();
    return [];
  }

  Future<void> _loadNotifications() async {
    final userId = CurrentUser.id;
    if (userId.isNotEmpty) {
      try {
        final notifications = await _repository.getNotifications(userId);
        // Sort by timestamp descending (latest first)
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = notifications;
      } catch (e) {
        print('Error loading notifications: $e');
        state = [];
      }
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    final userId = CurrentUser.id;
    if (userId.isEmpty) return;
    await addNotificationToMember(memberId: userId, notification: notification);
  }

  Future<void> addNotificationToMember({
    required String memberId,
    required NotificationModel notification,
  }) async {
    try {
      // Save to database
      await _repository.addNotification(memberId, notification);
      
      // Only reload if it's for the current user to keep local UI in sync
      if (memberId == CurrentUser.id) {
        await _loadNotifications();
      }
    } catch (e) {
      print('Error adding notification for $memberId: $e');
      if (memberId == CurrentUser.id) {
        await _loadNotifications();
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final userId = CurrentUser.id;
    if (userId.isEmpty) return;
    
    try {
      // Optimistically update state
      state = [
        for (final notification in state)
          if (notification.id == id)
            notification.copyWith(isRead: true)
          else
            notification,
      ];
      
      // Update in database
      await _repository.markAsRead(userId, id);
    } catch (e) {
      print('Error marking notification as read: $e');
      // Reload from server on error
      await _loadNotifications();
    }
  }
  
  Future<void> markAllAsRead() async {
    final userId = CurrentUser.id;
    if (userId.isEmpty) return;
    
    try {
      // Optimistically update state
      state = [
        for (final notification in state)
          notification.copyWith(isRead: true)
      ];
      
      // Update in database
      await _repository.markAllAsRead(userId);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      // Reload from server on error
      await _loadNotifications();
    }
  }

  Future<void> clearNotifications() async {
    final userId = CurrentUser.id;
    if (userId.isEmpty) return;
    
    try {
      // Clear state immediately
      state = [];
      
      // Clear in database
      await _repository.clearNotifications(userId);
    } catch (e) {
      print('Error clearing notifications: $e');
      // Reload from server on error
      await _loadNotifications();
    }
  }

  Future<void> refresh() async {
    await _loadNotifications();
  }
}
