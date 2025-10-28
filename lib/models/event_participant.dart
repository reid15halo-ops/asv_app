/// Event-Teilnehmer-Datenmodell
class EventParticipant {
  final String id;
  final String eventId;
  final String userId;
  final int? memberId;
  final String? memberName;
  final String? memberEmail;
  final DateTime registeredAt;
  final ParticipantStatus status;
  final String? notes;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    this.memberId,
    this.memberName,
    this.memberEmail,
    required this.registeredAt,
    required this.status,
    this.notes,
  });

  /// Von JSON
  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      memberId: json['member_id'] as int?,
      memberName: json['member_name'] as String?,
      memberEmail: json['member_email'] as String?,
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
      status: ParticipantStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
    );
  }

  /// Zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'member_id': memberId,
      'registered_at': registeredAt.toIso8601String(),
      'status': status.value,
      'notes': notes,
    };
  }

  /// Gibt Anzeigenamen zurück
  String get displayName {
    if (memberName != null && memberName!.isNotEmpty) {
      return memberName!;
    }
    if (memberEmail != null && memberEmail!.isNotEmpty) {
      return memberEmail!;
    }
    return 'Unbekannt';
  }

  /// Gibt Initialen zurück
  String get initials {
    if (memberName != null && memberName!.isNotEmpty) {
      final parts = memberName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return memberName![0].toUpperCase();
    }
    if (memberEmail != null && memberEmail!.isNotEmpty) {
      return memberEmail![0].toUpperCase();
    }
    return '?';
  }

  /// Copy with
  EventParticipant copyWith({
    String? id,
    String? eventId,
    String? userId,
    int? memberId,
    String? memberName,
    String? memberEmail,
    DateTime? registeredAt,
    ParticipantStatus? status,
    String? notes,
  }) {
    return EventParticipant(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberEmail: memberEmail ?? this.memberEmail,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

/// Teilnehmer-Status
enum ParticipantStatus {
  registered('registered', 'Angemeldet'),
  confirmed('confirmed', 'Bestätigt'),
  cancelled('cancelled', 'Abgesagt'),
  attended('attended', 'Teilgenommen');

  const ParticipantStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static ParticipantStatus fromString(String? value) {
    if (value == null) return ParticipantStatus.registered;
    return ParticipantStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => ParticipantStatus.registered,
    );
  }
}
