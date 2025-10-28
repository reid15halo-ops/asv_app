import 'package:flutter/material.dart';

/// Event-Typ (Kategorie)
enum EventType {
  arbeitseinsatz('arbeitseinsatz', 'Arbeitseinsatz', Icons.handyman, Color(0xFFFF9800)),
  feier('feier', 'Feier', Icons.celebration, Color(0xFFE91E63)),
  sitzung('sitzung', 'Sitzung', Icons.groups, Color(0xFF2196F3)),
  training('training', 'Training', Icons.fitness_center, Color(0xFF4CAF50)),
  wettkampf('wettkampf', 'Wettkampf', Icons.emoji_events, Color(0xFFFFC107)),
  ausflug('ausflug', 'Ausflug', Icons.directions_bus, Color(0xFF9C27B0)),
  kurs('kurs', 'Kurs', Icons.school, Color(0xFF00BCD4)),
  sonstiges('sonstiges', 'Sonstiges', Icons.event, Color(0xFF607D8B));

  const EventType(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static EventType fromString(String? value) {
    if (value == null) return EventType.sonstiges;
    return EventType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => EventType.sonstiges,
    );
  }
}

/// Event-Zielgruppe
enum EventTargetGroup {
  jugend('jugend', 'Jugend'),
  aktive('aktive', 'Aktive'),
  senioren('senioren', 'Senioren'),
  alle('alle', 'Alle');

  const EventTargetGroup(this.value, this.displayName);

  final String value;
  final String displayName;

  static EventTargetGroup fromString(String? value) {
    if (value == null) return EventTargetGroup.alle;
    return EventTargetGroup.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => EventTargetGroup.alle,
    );
  }
}

/// Event-Datenmodell
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final EventType type;
  final List<EventTargetGroup> targetGroups;
  final bool isAllDay;
  final int? maxParticipants;
  final int currentParticipants;
  final String? imageUrl;
  final String? organizerId;
  final String? organizerName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.location,
    required this.type,
    required this.targetGroups,
    this.isAllDay = false,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.imageUrl,
    this.organizerId,
    this.organizerName,
    required this.createdAt,
    this.updatedAt,
  });

  /// Prüft ob Event für eine bestimmte Zielgruppe relevant ist
  bool isRelevantFor(EventTargetGroup group) {
    return targetGroups.contains(EventTargetGroup.alle) ||
        targetGroups.contains(group);
  }

  /// Gibt formatiertes Datum zurück
  String get formattedDate {
    if (isAllDay) {
      if (endDate != null && !isSameDay(startDate, endDate!)) {
        return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
      }
      return _formatDate(startDate);
    } else {
      return '${_formatDate(startDate)} ${_formatTime(startDate)}';
    }
  }

  /// Prüft ob zwei Dates am selben Tag sind
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} Uhr';
  }

  /// Gibt Zielgruppen als String zurück
  String get targetGroupsString {
    if (targetGroups.contains(EventTargetGroup.alle)) {
      return 'Alle';
    }
    return targetGroups.map((g) => g.displayName).join(', ');
  }

  /// Prüft ob Event in der Zukunft liegt
  bool get isFuture => startDate.isAfter(DateTime.now());

  /// Prüft ob Event aktuell läuft
  bool get isOngoing {
    final now = DateTime.now();
    final end = endDate ?? startDate;
    return startDate.isBefore(now) && end.isAfter(now);
  }

  /// Prüft ob Event vorbei ist
  bool get isPast {
    final end = endDate ?? startDate;
    return end.isBefore(DateTime.now());
  }

  /// Prüft ob Event ausgebucht ist
  bool get isFullyBooked {
    if (maxParticipants == null) return false;
    return currentParticipants >= maxParticipants!;
  }

  /// Von JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse target groups from JSON array
    List<EventTargetGroup> targetGroups = [];
    if (json['target_groups'] != null) {
      if (json['target_groups'] is List) {
        targetGroups = (json['target_groups'] as List)
            .map((g) => EventTargetGroup.fromString(g.toString()))
            .toList();
      } else if (json['target_groups'] is String) {
        // Fallback für String-Format
        targetGroups = [EventTargetGroup.fromString(json['target_groups'] as String)];
      }
    }

    // Wenn keine Gruppen gesetzt, default auf "alle"
    if (targetGroups.isEmpty) {
      targetGroups = [EventTargetGroup.alle];
    }

    return Event(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      location: json['location'] as String?,
      type: EventType.fromString(json['type'] as String?),
      targetGroups: targetGroups,
      isAllDay: json['is_all_day'] as bool? ?? false,
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      organizerId: json['organizer_id'] as String?,
      organizerName: json['organizer_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'type': type.value,
      'target_groups': targetGroups.map((g) => g.value).toList(),
      'is_all_day': isAllDay,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'image_url': imageUrl,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    EventType? type,
    List<EventTargetGroup>? targetGroups,
    bool? isAllDay,
    int? maxParticipants,
    int? currentParticipants,
    String? imageUrl,
    String? organizerId,
    String? organizerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      type: type ?? this.type,
      targetGroups: targetGroups ?? this.targetGroups,
      isAllDay: isAllDay ?? this.isAllDay,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
