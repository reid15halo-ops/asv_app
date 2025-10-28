import 'package:flutter/material.dart';

/// Event-Typen
enum EventType {
  meeting('meeting', 'Versammlung', Icons.groups),
  tournament('tournament', 'Turnier', Icons.emoji_events),
  training('training', 'Training', Icons.school),
  social('social', 'Sozial', Icons.celebration),
  other('other', 'Sonstiges', Icons.event);

  const EventType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static EventType fromString(String? value) {
    if (value == null) return EventType.other;
    switch (value.toLowerCase()) {
      case 'meeting':
        return EventType.meeting;
      case 'tournament':
        return EventType.tournament;
      case 'training':
        return EventType.training;
      case 'social':
        return EventType.social;
      case 'other':
      default:
        return EventType.other;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case EventType.meeting:
        return Colors.blue;
      case EventType.tournament:
        return Colors.amber;
      case EventType.training:
        return Colors.green;
      case EventType.social:
        return Colors.purple;
      case EventType.other:
        return Colors.grey;
    }
  }
}

/// Event-Status
enum EventStatus {
  upcoming('upcoming', 'Bevorstehend'),
  cancelled('cancelled', 'Abgesagt'),
  completed('completed', 'Abgeschlossen');

  const EventStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static EventStatus fromString(String? value) {
    if (value == null) return EventStatus.upcoming;
    switch (value.toLowerCase()) {
      case 'upcoming':
        return EventStatus.upcoming;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.upcoming;
    }
  }
}

/// Model für ein Event
class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? location;
  final int? maxParticipants;
  final bool registrationRequired;
  final DateTime? registrationDeadline;
  final EventType eventType;
  final EventStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Zusätzliche Felder aus Joins/Views
  final int? registeredCount;
  final int? availableSpots;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.endDate,
    this.location,
    this.maxParticipants,
    required this.registrationRequired,
    this.registrationDeadline,
    required this.eventType,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.registeredCount,
    this.availableSpots,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: json['event_date'] is String
          ? DateTime.parse(json['event_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] is String
          ? DateTime.parse(json['end_date'] as String)
          : null,
      location: json['location'] as String?,
      maxParticipants: json['max_participants'] as int?,
      registrationRequired: json['registration_required'] as bool? ?? false,
      registrationDeadline: json['registration_deadline'] is String
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      eventType: EventType.fromString(json['event_type'] as String?),
      status: EventStatus.fromString(json['status'] as String?),
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      registeredCount: json['registered_count'] as int?,
      availableSpots: json['available_spots'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'max_participants': maxParticipants,
      'registration_required': registrationRequired,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'event_type': eventType.value,
      'status': status.value,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? endDate,
    String? location,
    int? maxParticipants,
    bool? registrationRequired,
    DateTime? registrationDeadline,
    EventType? eventType,
    EventStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? registeredCount,
    int? availableSpots,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registrationRequired: registrationRequired ?? this.registrationRequired,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registeredCount: registeredCount ?? this.registeredCount,
      availableSpots: availableSpots ?? this.availableSpots,
    );
  }

  /// Formatiert Datum als String (z.B. "15.12.2024")
  String get eventDateFormatted {
    return '${eventDate.day}.${eventDate.month}.${eventDate.year}';
  }

  /// Formatiert Datum und Uhrzeit (z.B. "15.12.2024 14:30")
  String get eventDateTimeFormatted {
    return '$eventDateFormatted ${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')} Uhr';
  }

  /// Gibt Location zurück oder "Keine Angabe"
  String get locationOrDefault => location ?? 'Keine Angabe';

  /// Prüft ob Event voll ist
  bool get isFull {
    if (maxParticipants == null) return false;
    if (registeredCount == null) return false;
    return registeredCount! >= maxParticipants!;
  }

  /// Prüft ob Anmeldeschluss überschritten
  bool get isRegistrationClosed {
    if (registrationDeadline == null) return false;
    return DateTime.now().isAfter(registrationDeadline!);
  }

  /// Prüft ob Anmeldung möglich ist
  bool get canRegister {
    return status == EventStatus.upcoming &&
        registrationRequired &&
        !isFull &&
        !isRegistrationClosed;
  }

  /// Gibt die verbleibenden Tage bis zum Event zurück
  int get daysUntilEvent {
    return eventDate.difference(DateTime.now()).inDays;
  }

  /// Prüft ob Event heute ist
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  /// Prüft ob Event in der Vergangenheit liegt
  bool get isPast {
    return eventDate.isBefore(DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $eventDateFormatted, type: ${eventType.displayName})';
  }
}

/// Registration-Status
enum RegistrationStatus {
  registered('registered', 'Angemeldet'),
  cancelled('cancelled', 'Storniert'),
  attended('attended', 'Teilgenommen');

  const RegistrationStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static RegistrationStatus fromString(String? value) {
    if (value == null) return RegistrationStatus.registered;
    switch (value.toLowerCase()) {
      case 'registered':
        return RegistrationStatus.registered;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'attended':
        return RegistrationStatus.attended;
      default:
        return RegistrationStatus.registered;
    }
  }
}

/// Model für Event-Registrierung
class EventRegistration {
  final int id;
  final int eventId;
  final String userId;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? cancelledAt;
  final String? notes;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.registeredAt,
    this.cancelledAt,
    this.notes,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as String,
      status: RegistrationStatus.fromString(json['status'] as String?),
      registeredAt: json['registered_at'] is String
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
      cancelledAt: json['cancelled_at'] is String
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'status': status.value,
      'registered_at': registeredAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventRegistration && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
