import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asv_app/features/notifications/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('fromJson sollte korrekt deserialisieren', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'enable_event_new': true,
        'enable_event_reminder': true,
        'enable_event_cancelled': true,
        'enable_event_updated': true,
        'enable_announcement': true,
        'enable_achievement': true,
        'enable_level_up': true,
        'enable_system': true,
        'enable_push_notifications': false,
        'enable_quiet_hours': false,
        'quiet_hours_start': null,
        'quiet_hours_end': null,
        'created_at': '2025-01-01T12:00:00Z',
        'updated_at': '2025-01-01T12:00:00Z',
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.id, 1);
      expect(prefs.userId, 'user-123');
      expect(prefs.enableEventNew, true);
      expect(prefs.enablePushNotifications, false);
      expect(prefs.enableQuietHours, false);
      expect(prefs.quietHoursStart, null);
      expect(prefs.quietHoursEnd, null);
    });

    test('fromJson sollte Quiet Hours korrekt parsen', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'enable_event_new': true,
        'enable_event_reminder': true,
        'enable_event_cancelled': true,
        'enable_event_updated': true,
        'enable_announcement': true,
        'enable_achievement': true,
        'enable_level_up': true,
        'enable_system': true,
        'enable_push_notifications': false,
        'enable_quiet_hours': true,
        'quiet_hours_start': '22:00:00',
        'quiet_hours_end': '07:00:00',
        'created_at': '2025-01-01T12:00:00Z',
        'updated_at': '2025-01-01T12:00:00Z',
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.enableQuietHours, true);
      expect(prefs.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
      expect(prefs.quietHoursEnd, const TimeOfDay(hour: 7, minute: 0));
    });

    test('toJson sollte korrekt serialisieren', () {
      final prefs = NotificationPreferences(
        id: 1,
        userId: 'user-123',
        enableEventNew: true,
        enableEventReminder: true,
        enableEventCancelled: true,
        enableEventUpdated: true,
        enableAnnouncement: true,
        enableAchievement: true,
        enableLevelUp: true,
        enableSystem: true,
        enablePushNotifications: false,
        enableQuietHours: false,
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final json = prefs.toJson();

      expect(json['enable_event_new'], true);
      expect(json['enable_push_notifications'], false);
      expect(json['enable_quiet_hours'], false);
      expect(json['quiet_hours_start'], null);
      expect(json['quiet_hours_end'], null);
    });

    test('toJson sollte Quiet Hours korrekt formatieren', () {
      final prefs = NotificationPreferences(
        id: 1,
        userId: 'user-123',
        enableEventNew: true,
        enableEventReminder: true,
        enableEventCancelled: true,
        enableEventUpdated: true,
        enableAnnouncement: true,
        enableAchievement: true,
        enableLevelUp: true,
        enableSystem: true,
        enablePushNotifications: false,
        enableQuietHours: true,
        quietHoursStart: const TimeOfDay(hour: 22, minute: 30),
        quietHoursEnd: const TimeOfDay(hour: 7, minute: 15),
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final json = prefs.toJson();

      expect(json['quiet_hours_start'], '22:30:00');
      expect(json['quiet_hours_end'], '07:15:00');
    });

    test('copyWith sollte Werte korrekt übernehmen', () {
      final prefs = NotificationPreferences(
        id: 1,
        userId: 'user-123',
        enableEventNew: true,
        enableEventReminder: true,
        enableEventCancelled: true,
        enableEventUpdated: true,
        enableAnnouncement: true,
        enableAchievement: true,
        enableLevelUp: true,
        enableSystem: true,
        enablePushNotifications: false,
        enableQuietHours: false,
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final updated = prefs.copyWith(
        enableEventNew: false,
        enablePushNotifications: true,
      );

      expect(updated.id, prefs.id);
      expect(updated.userId, prefs.userId);
      expect(updated.enableEventNew, false);
      expect(updated.enablePushNotifications, true);
      expect(updated.enableEventReminder, prefs.enableEventReminder);

      // Original sollte unverändert sein
      expect(prefs.enableEventNew, true);
      expect(prefs.enablePushNotifications, false);
    });

    test('copyWith sollte Quiet Hours aktualisieren können', () {
      final prefs = NotificationPreferences(
        id: 1,
        userId: 'user-123',
        enableEventNew: true,
        enableEventReminder: true,
        enableEventCancelled: true,
        enableEventUpdated: true,
        enableAnnouncement: true,
        enableAchievement: true,
        enableLevelUp: true,
        enableSystem: true,
        enablePushNotifications: false,
        enableQuietHours: false,
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final updated = prefs.copyWith(
        enableQuietHours: true,
        quietHoursStart: const TimeOfDay(hour: 23, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 6, minute: 0),
      );

      expect(updated.enableQuietHours, true);
      expect(updated.quietHoursStart, const TimeOfDay(hour: 23, minute: 0));
      expect(updated.quietHoursEnd, const TimeOfDay(hour: 6, minute: 0));
    });
  });
}
