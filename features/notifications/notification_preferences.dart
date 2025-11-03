import 'package:flutter/material.dart';

class NotificationPreferences {
  final int id;
  final String userId;

  // Notification Type Preferences
  final bool enableEventNew;
  final bool enableEventReminder;
  final bool enableEventCancelled;
  final bool enableEventUpdated;
  final bool enableAnnouncement;
  final bool enableAchievement;
  final bool enableLevelUp;
  final bool enableSystem;

  // Push Notification Settings
  final bool enablePushNotifications;

  // Quiet Hours
  final bool enableQuietHours;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    required this.enableEventNew,
    required this.enableEventReminder,
    required this.enableEventCancelled,
    required this.enableEventUpdated,
    required this.enableAnnouncement,
    required this.enableAchievement,
    required this.enableLevelUp,
    required this.enableSystem,
    required this.enablePushNotifications,
    required this.enableQuietHours,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      enableEventNew: json['enable_event_new'] as bool,
      enableEventReminder: json['enable_event_reminder'] as bool,
      enableEventCancelled: json['enable_event_cancelled'] as bool,
      enableEventUpdated: json['enable_event_updated'] as bool,
      enableAnnouncement: json['enable_announcement'] as bool,
      enableAchievement: json['enable_achievement'] as bool,
      enableLevelUp: json['enable_level_up'] as bool,
      enableSystem: json['enable_system'] as bool,
      enablePushNotifications: json['enable_push_notifications'] as bool,
      enableQuietHours: json['enable_quiet_hours'] as bool,
      quietHoursStart: _parseTime(json['quiet_hours_start']),
      quietHoursEnd: _parseTime(json['quiet_hours_end']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_event_new': enableEventNew,
      'enable_event_reminder': enableEventReminder,
      'enable_event_cancelled': enableEventCancelled,
      'enable_event_updated': enableEventUpdated,
      'enable_announcement': enableAnnouncement,
      'enable_achievement': enableAchievement,
      'enable_level_up': enableLevelUp,
      'enable_system': enableSystem,
      'enable_push_notifications': enablePushNotifications,
      'enable_quiet_hours': enableQuietHours,
      'quiet_hours_start': _formatTime(quietHoursStart),
      'quiet_hours_end': _formatTime(quietHoursEnd),
    };
  }

  static TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  NotificationPreferences copyWith({
    bool? enableEventNew,
    bool? enableEventReminder,
    bool? enableEventCancelled,
    bool? enableEventUpdated,
    bool? enableAnnouncement,
    bool? enableAchievement,
    bool? enableLevelUp,
    bool? enableSystem,
    bool? enablePushNotifications,
    bool? enableQuietHours,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      enableEventNew: enableEventNew ?? this.enableEventNew,
      enableEventReminder: enableEventReminder ?? this.enableEventReminder,
      enableEventCancelled: enableEventCancelled ?? this.enableEventCancelled,
      enableEventUpdated: enableEventUpdated ?? this.enableEventUpdated,
      enableAnnouncement: enableAnnouncement ?? this.enableAnnouncement,
      enableAchievement: enableAchievement ?? this.enableAchievement,
      enableLevelUp: enableLevelUp ?? this.enableLevelUp,
      enableSystem: enableSystem ?? this.enableSystem,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
