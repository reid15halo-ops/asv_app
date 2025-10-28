/// Model für einen Fang (Catch)
///
/// Repräsentiert einen erfassten Fisch mit allen relevanten Daten
class Catch {
  final int id;
  final int memberId;
  final String? speciesId;
  final String? speciesName; // Name aus JOIN
  final int? lengthCm;
  final int? weightG;
  final String? waterBodyId;
  final String? waterBodyName; // Name aus JOIN
  final String? photoUrl;
  final String privacyLevel;
  final DateTime capturedAt;
  final DateTime createdAt;

  const Catch({
    required this.id,
    required this.memberId,
    this.speciesId,
    this.speciesName,
    this.lengthCm,
    this.weightG,
    this.waterBodyId,
    this.waterBodyName,
    this.photoUrl,
    required this.privacyLevel,
    required this.capturedAt,
    required this.createdAt,
  });

  /// Erstellt ein Catch aus JSON (Supabase catch table)
  factory Catch.fromJson(Map<String, dynamic> json) {
    return Catch(
      id: json['id'] as int,
      memberId: json['member_id'] as int,
      speciesId: json['species_id'] as String?,
      speciesName: json['species_name'] as String?,
      lengthCm: json['length_cm'] as int?,
      weightG: json['weight_g'] as int?,
      waterBodyId: json['water_body_id'] as String?,
      waterBodyName: json['water_body_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      privacyLevel: json['privacy_level'] as String? ?? 'club',
      capturedAt: json['captured_at'] is String
          ? DateTime.parse(json['captured_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Konvertiert zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'species_id': speciesId,
      'length_cm': lengthCm,
      'weight_g': weightG,
      'water_body_id': waterBodyId,
      'photo_url': photoUrl,
      'privacy_level': privacyLevel,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy-Methode für Immutability
  Catch copyWith({
    int? id,
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
    );
  }

  /// Formatiert Länge als String (z.B. "42 cm")
  String get lengthFormatted => lengthCm != null ? '$lengthCm cm' : 'k.A.';

  /// Formatiert Gewicht als String (z.B. "1500 g" oder "1.5 kg")
  String get weightFormatted {
    if (weightG == null) return 'k.A.';
    if (weightG! >= 1000) {
      final kg = weightG! / 1000;
      return '${kg.toStringAsFixed(1)} kg';
    }
    return '$weightG g';
  }

  /// Gibt das Datum als formattierten String zurück
  String get capturedAtFormatted {
    return '${capturedAt.day}.${capturedAt.month}.${capturedAt.year}';
  }

  /// Gibt Fischart-Name zurück (oder "Unbekannt" als Fallback)
  String get speciesNameOrDefault => speciesName ?? 'Unbekannt';

  /// Gibt Gewässer-Name zurück (oder "Unbekannt" als Fallback)
  String get waterBodyNameOrDefault => waterBodyName ?? 'Unbekannt';

  /// Prüft ob ein Foto vorhanden ist
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Catch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Catch(id: $id, species: $speciesName, length: $lengthCm cm, weight: $weightG g, date: $capturedAtFormatted)';
  }
}
