import 'package:flutter/material.dart';

/// Event-Model für Kalender/Events-System
class Event {
  final int id;
  final String title;
  final String? description;
  final String? location;

  final DateTime startDate;
  final DateTime? endDate;
  final bool allDay;

  final String? organizer;
  final String? contactEmail;
  final String? contactPhone;
  final int? maxParticipants;

  final EventStatus status;
  final bool isPublic;

  // WordPress Sync
  final int? wordpressId;
  final String? wordpressUrl;
  final DateTime? lastSyncedAt;
  final SyncSource syncSource;

  // Metadata
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Computed from participants (via join)
  final int? participantCount;
  final int? spotsAvailable;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startDate,
    this.endDate,
    this.allDay = false,
    this.organizer,
    this.contactEmail,
    this.contactPhone,
    this.maxParticipants,
    this.status = EventStatus.published,
    this.isPublic = true,
    this.wordpressId,
    this.wordpressUrl,
    this.lastSyncedAt,
    this.syncSource = SyncSource.app,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.participantCount,
    this.spotsAvailable,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      allDay: json['all_day'] as bool? ?? false,
      organizer: json['organizer'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      maxParticipants: json['max_participants'] as int?,
      status: EventStatus.fromString(json['status'] as String? ?? 'published'),
      isPublic: json['is_public'] as bool? ?? true,
      wordpressId: json['wordpress_id'] as int?,
      wordpressUrl: json['wordpress_url'] as String?,
      lastSyncedAt: json['last_synced_at'] != null ? DateTime.parse(json['last_synced_at'] as String) : null,
      syncSource: SyncSource.fromString(json['sync_source'] as String? ?? 'app'),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      participantCount: json['participant_count'] as int?,
      spotsAvailable: json['spots_available'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'all_day': allDay,
      'organizer': organizer,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'max_participants': maxParticipants,
      'status': status.value,
      'is_public': isPublic,
      'wordpress_id': wordpressId,
      'wordpress_url': wordpressUrl,
      'sync_source': syncSource.value,
      'metadata': metadata,
    };
  }

  /// Prüft ob Event in der Zukunft liegt
  bool get isUpcoming => startDate.isAfter(DateTime.now());

  /// Prüft ob Event aktuell läuft
  bool get isOngoing {
    final now = DateTime.now();
    return startDate.isBefore(now) && (endDate?.isAfter(now) ?? false);
  }

  /// Prüft ob Event vorbei ist
  bool get isPast {
    final compareDate = endDate ?? startDate;
    return compareDate.isBefore(DateTime.now());
  }

  /// Prüft ob Event ausgebucht ist
  bool get isFull {
    if (maxParticipants == null || participantCount == null) return false;
    return participantCount! >= maxParticipants!;
  }

  /// Formatierte Datumsanzeige
  String get formattedDate {
    if (allDay) {
      if (endDate != null && endDate!.day != startDate.day) {
        return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
      }
      return _formatDate(startDate);
    }

    if (endDate != null) {
      if (endDate!.day == startDate.day) {
        return '${_formatDate(startDate)}, ${_formatTime(startDate)} - ${_formatTime(endDate!)}';
      }
      return '${_formatDateTime(startDate)} - ${_formatDateTime(endDate!)}';
    }

    return _formatDateTime(startDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} Uhr';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}, ${_formatTime(date)}';
  }

  Event copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    String? organizer,
    String? contactEmail,
    String? contactPhone,
    int? maxParticipants,
    EventStatus? status,
    bool? isPublic,
    int? wordpressId,
    String? wordpressUrl,
    DateTime? lastSyncedAt,
    SyncSource? syncSource,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      allDay: allDay ?? this.allDay,
      organizer: organizer ?? this.organizer,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      wordpressId: wordpressId ?? this.wordpressId,
      wordpressUrl: wordpressUrl ?? this.wordpressUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncSource: syncSource ?? this.syncSource,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata,
      participantCount: participantCount,
      spotsAvailable: spotsAvailable,
    );
  }
}

/// Event-Status
enum EventStatus {
  draft('draft', 'Entwurf'),
  published('published', 'Veröffentlicht'),
  cancelled('cancelled', 'Abgesagt');

  final String value;
  final String label;

  const EventStatus(this.value, this.label);

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => EventStatus.published,
    );
  }
}

/// Sync-Quelle
enum SyncSource {
  app('app', 'App'),
  wordpress('wordpress', 'WordPress');

  final String value;
  final String label;

  const SyncSource(this.value, this.label);

  static SyncSource fromString(String value) {
    return SyncSource.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SyncSource.app,
    );
  }
}

/// Event-Teilnehmer
class EventParticipant {
  final int id;
  final int eventId;
  final String userId;
  final ParticipantStatus status;
  final DateTime registeredAt;
  final String? notes;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.registeredAt,
    this.notes,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as String,
      status: ParticipantStatus.fromString(json['status'] as String? ?? 'registered'),
      registeredAt: DateTime.parse(json['registered_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'status': status.value,
      'notes': notes,
    };
  }
}

enum ParticipantStatus {
  registered('registered', 'Angemeldet', Icons.check_circle, Colors.green),
  attended('attended', 'Teilgenommen', Icons.check_circle_outline, Colors.blue),
  cancelled('cancelled', 'Abgesagt', Icons.cancel, Colors.red);

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ParticipantStatus(this.value, this.label, this.icon, this.color);

  static ParticipantStatus fromString(String value) {
    return ParticipantStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ParticipantStatus.registered,
    );
  }
}
