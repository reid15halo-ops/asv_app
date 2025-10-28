/// Catch Model - Repräsentiert einen Fang
class Catch {
  final String? id;
  final int memberId;
  final String? speciesId;
  final String? speciesName; // Wird aus species Tabelle geladen
  final int? lengthCm;
  final int? weightG;
  final String? waterBodyId;
  final String? waterBodyName; // Wird aus water_body Tabelle geladen
  final String? photoUrl;
  final String privacyLevel;
  final DateTime capturedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Member Info (wird aus member Tabelle geladen)
  final String? memberName;

  Catch({
    this.id,
    required this.memberId,
    this.speciesId,
    this.speciesName,
    this.lengthCm,
    this.weightG,
    this.waterBodyId,
    this.waterBodyName,
    this.photoUrl,
    this.privacyLevel = 'club',
    required this.capturedAt,
    this.createdAt,
    this.updatedAt,
    this.memberName,
  });

  /// Erstellt Catch aus JSON
  factory Catch.fromJson(Map<String, dynamic> json) {
    return Catch(
      id: json['id'] as String?,
      memberId: json['member_id'] is int
          ? json['member_id'] as int
          : int.parse(json['member_id'].toString()),
      speciesId: json['species_id'] as String?,
      speciesName: json['species_name'] as String?,
      lengthCm: json['length_cm'] is int
          ? json['length_cm'] as int
          : (json['length_cm'] != null ? int.tryParse(json['length_cm'].toString()) : null),
      weightG: json['weight_g'] is int
          ? json['weight_g'] as int
          : (json['weight_g'] != null ? int.tryParse(json['weight_g'].toString()) : null),
      waterBodyId: json['water_body_id'] as String?,
      waterBodyName: json['water_body_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      privacyLevel: json['privacy_level'] as String? ?? 'club',
      capturedAt: DateTime.parse(json['captured_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      memberName: json['member_name'] as String?,
    );
  }

  /// Konvertiert Catch zu JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'member_id': memberId,
      if (speciesId != null) 'species_id': speciesId,
      if (lengthCm != null) 'length_cm': lengthCm,
      if (weightG != null) 'weight_g': weightG,
      if (waterBodyId != null) 'water_body_id': waterBodyId,
      if (photoUrl != null) 'photo_url': photoUrl,
      'privacy_level': privacyLevel,
      'captured_at': capturedAt.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Erstellt Kopie mit geänderten Werten
  Catch copyWith({
    String? id,
    int? memberId,
    String? speciesId,
    String? speciesName,
    int? lengthCm,
    int? weightG,
    String? waterBodyId,
    String? waterBodyName,
    String? photoUrl,
    String? privacyLevel,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? memberName,
  }) {
    return Catch(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      speciesId: speciesId ?? this.speciesId,
      speciesName: speciesName ?? this.speciesName,
      lengthCm: lengthCm ?? this.lengthCm,
      weightG: weightG ?? this.weightG,
      waterBodyId: waterBodyId ?? this.waterBodyId,
      waterBodyName: waterBodyName ?? this.waterBodyName,
      photoUrl: photoUrl ?? this.photoUrl,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberName: memberName ?? this.memberName,
    );
  }

  /// Formatiert Länge als String
  String get lengthFormatted {
    if (lengthCm == null || lengthCm == 0) return '-';
    return '$lengthCm cm';
  }

  /// Formatiert Gewicht als String
  String get weightFormatted {
    if (weightG == null || weightG == 0) return '-';
    if (weightG! >= 1000) {
      return '${(weightG! / 1000).toStringAsFixed(2)} kg';
    }
    return '$weightG g';
  }

  /// Formatiert Datum als String
  String get dateFormatted {
    return '${capturedAt.day}.${capturedAt.month}.${capturedAt.year}';
  }

  /// Formatiert Datum und Uhrzeit
  String get dateTimeFormatted {
    return '${capturedAt.day}.${capturedAt.month}.${capturedAt.year} '
        '${capturedAt.hour.toString().padLeft(2, '0')}:'
        '${capturedAt.minute.toString().padLeft(2, '0')}';
  }

  /// Gibt zurück ob Fang ein Foto hat
  bool get hasPhoto {
    return photoUrl != null && photoUrl!.isNotEmpty;
  }

  /// Prüft ob Fang vollständig ist (alle Hauptdaten vorhanden)
  bool get isComplete {
    return speciesId != null &&
           waterBodyId != null &&
           (lengthCm != null && lengthCm! > 0 || weightG != null && weightG! > 0);
  }

  /// Gibt einen Score für den Fang zurück (für Gamification)
  int get score {
    int points = 10; // Basis-Punkte

    // Punkte für Länge
    if (lengthCm != null) {
      if (lengthCm! > 50) points += 20;
      if (lengthCm! > 70) points += 30;
      if (lengthCm! > 100) points += 50;
    }

    // Punkte für Gewicht
    if (weightG != null) {
      if (weightG! > 1000) points += 15;
      if (weightG! > 5000) points += 25;
      if (weightG! > 10000) points += 40;
    }

    // Bonus für Foto
    if (hasPhoto) points += 10;

    // Bonus für vollständige Daten
    if (isComplete) points += 5;

    return points;
  }

  @override
  String toString() {
    return 'Catch{id: $id, species: $speciesName, length: $lengthFormatted, weight: $weightFormatted, date: $dateFormatted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Catch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
