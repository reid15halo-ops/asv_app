import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/notification.dart';
import 'package:asv_app/repositories/notification_repository.dart';

/// Provider für NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

/// Provider für Notifications-Liste
class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;

  NotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  /// Lädt alle Notifications
  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt nur ungelesene Notifications
  Future<void> loadUnreadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getUnreadNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Markiert eine Notification als gelesen
  Future<void> markAsRead(int notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(read: true, readAt: DateTime.now());
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Markiert alle Notifications als gelesen
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((n) {
          return n.copyWith(read: true, readAt: DateTime.now());
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Löscht eine Notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications
            .where((n) => n.id != notificationId)
            .toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Löscht alle Notifications
  Future<void> deleteAllNotifications() async {
    try {
      await _repository.deleteAllNotifications();
      state = const AsyncValue.data([]);
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Refresh - lädt Notifications neu
  Future<void> refresh() async {
    await loadNotifications();
  }
}

/// Global Provider für Notifications
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository);
});

/// Provider für Anzahl ungelesener Notifications
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return await repository.getUnreadCount();
});

/// Stream Provider für Realtime unread count
final unreadNotificationsCountStreamProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount();
});

/// Stream Provider für Realtime notifications
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications();
});
