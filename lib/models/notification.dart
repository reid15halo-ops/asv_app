import 'package:flutter/material.dart';

/// Notification-Typen
enum NotificationType {
  eventNew('event_new', 'Neues Event', Icons.event),
  eventReminder('event_reminder', 'Event-Erinnerung', Icons.alarm),
  eventCancelled('event_cancelled', 'Event abgesagt', Icons.event_busy),
  eventUpdated('event_updated', 'Event aktualisiert', Icons.update),
  announcement('announcement', 'Ankündigung', Icons.campaign),
  achievement('achievement', 'Achievement', Icons.emoji_events),
  levelUp('level_up', 'Level-Up', Icons.trending_up),
  system('system', 'System', Icons.info);

  const NotificationType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  /// Konvertiert einen String-Wert aus der Datenbank zum Enum
  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.system;
    switch (value.toLowerCase()) {
      case 'event_new':
        return NotificationType.eventNew;
      case 'event_reminder':
        return NotificationType.eventReminder;
      case 'event_cancelled':
        return NotificationType.eventCancelled;
      case 'event_updated':
        return NotificationType.eventUpdated;
      case 'announcement':
        return NotificationType.announcement;
      case 'achievement':
        return NotificationType.achievement;
      case 'level_up':
        return NotificationType.levelUp;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  /// Gibt die passende Farbe für den Typ zurück
  Color getColor(BuildContext context) {
    switch (this) {
      case NotificationType.eventNew:
        return Colors.blue;
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.eventCancelled:
        return Colors.red;
      case NotificationType.eventUpdated:
        return Colors.teal;
      case NotificationType.announcement:
        return Colors.purple;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.levelUp:
        return Colors.green;
      case NotificationType.system:
        return Colors.grey;
    }
  }
}

/// Notification-Datenmodell
class AppNotification {
  final int id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final String? actionUrl;
  final String? actionLabel;
  final int? eventId;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.actionUrl,
    this.actionLabel,
    this.eventId,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  /// Factory: Erstelle Notification aus JSON (Supabase Response)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? (json['id'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
      eventId: json['event_id'] as int? ?? (json['event_id'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Konvertiere zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'read': read,
      'action_url': actionUrl,
      'action_label': actionLabel,
      'event_id': eventId,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Erstelle Kopie mit geänderten Werten
  AppNotification copyWith({
    int? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? read,
    String? actionUrl,
    String? actionLabel,
    int? eventId,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Gibt einen relativen Zeitstempel zurück (z.B. "vor 5 Minuten")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'vor $minutes ${minutes == 1 ? 'Minute' : 'Minuten'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'vor $hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'vor $days ${days == 1 ? 'Tag' : 'Tagen'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'vor $weeks ${weeks == 1 ? 'Woche' : 'Wochen'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months ${months == 1 ? 'Monat' : 'Monaten'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'vor $years ${years == 1 ? 'Jahr' : 'Jahren'}';
    }
  }
}
