import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/notification.dart';

/// Repository für Notification-Operationen
class NotificationRepository {
  final SupabaseClient supa;

  NotificationRepository(this.supa);

  /// Lädt alle Notifications für den aktuellen User
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final user = supa.auth.currentUser;
    if (user == null) return [];

    final response = await supa
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Lädt nur ungelesene Notifications
  Future<List<AppNotification>> getUnreadNotifications({
    int limit = 50,
  }) async {
    final user = supa.auth.currentUser;
    if (user == null) return [];

    final response = await supa
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .eq('read', false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Gibt die Anzahl ungelesener Notifications zurück
  Future<int> getUnreadCount() async {
    final user = supa.auth.currentUser;
    if (user == null) return 0;

    final response = await supa
        .from('notifications')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', user.id)
        .eq('read', false);

    return response.count ?? 0;
  }

  /// Markiert eine Notification als gelesen
  Future<void> markAsRead(int notificationId) async {
    await supa
        .from('notifications')
        .update({
          'read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  /// Markiert mehrere Notifications als gelesen
  Future<void> markMultipleAsRead(List<int> notificationIds) async {
    await supa
        .from('notifications')
        .update({
          'read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .in_('id', notificationIds);
  }

  /// Markiert alle Notifications als gelesen
  Future<void> markAllAsRead() async {
    final user = supa.auth.currentUser;
    if (user == null) return;

    await supa
        .from('notifications')
        .update({
          'read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('read', false);
  }

  /// Löscht eine Notification
  Future<void> deleteNotification(int notificationId) async {
    await supa
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  /// Löscht alle Notifications des Users
  Future<void> deleteAllNotifications() async {
    final user = supa.auth.currentUser;
    if (user == null) return;

    await supa
        .from('notifications')
        .delete()
        .eq('user_id', user.id);
  }

  /// Erstellt eine Notification (meist via Backend/Trigger, aber für Tests nützlich)
  Future<AppNotification?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? actionUrl,
    String? actionLabel,
    int? eventId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await supa
        .from('notifications')
        .insert({
          'user_id': userId,
          'type': type.value,
          'title': title,
          'message': message,
          'action_url': actionUrl,
          'action_label': actionLabel,
          'event_id': eventId,
          'metadata': metadata ?? {},
        })
        .select()
        .single();

    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  /// Erstellt eine Admin-Ankündigung für alle User
  Future<int> createAnnouncementForAll({
    required String title,
    required String message,
    String? actionUrl,
    String? actionLabel,
  }) async {
    final response = await supa.rpc('create_notification_for_all_users', params: {
      'p_type': 'announcement',
      'p_title': title,
      'p_message': message,
      'p_action_url': actionUrl,
      'p_action_label': actionLabel,
      'p_metadata': {},
    });

    return response as int? ?? 0;
  }

  /// Erstellt eine Notification für spezifische User
  Future<int> createNotificationForUsers({
    required List<String> userIds,
    required NotificationType type,
    required String title,
    required String message,
    String? actionUrl,
    String? actionLabel,
    int? eventId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await supa.rpc('create_notification_for_users', params: {
      'p_user_ids': userIds,
      'p_type': type.value,
      'p_title': title,
      'p_message': message,
      'p_action_url': actionUrl,
      'p_action_label': actionLabel,
      'p_event_id': eventId,
      'p_metadata': metadata ?? {},
    });

    return response as int? ?? 0;
  }

  /// Erstellt einen Stream für Realtime-Updates (neue Notifications)
  Stream<List<AppNotification>> watchNotifications() {
    final user = supa.auth.currentUser;
    if (user == null) return Stream.value([]);

    return supa
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => AppNotification.fromJson(json))
            .toList());
  }

  /// Erstellt einen Stream für ungelesene Notifications-Count
  Stream<int> watchUnreadCount() {
    final user = supa.auth.currentUser;
    if (user == null) return Stream.value(0);

    return supa
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .eq('read', false)
        .map((data) => data.length);
  }
}
