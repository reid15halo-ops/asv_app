/// Model für einen Leaderboard-Eintrag
///
/// Repräsentiert einen Spieler im Leaderboard mit allen relevanten Daten
class LeaderboardEntry {
  final String userId;
  final String? displayName;
  final int xpPoints;
  final int level;
  final int totalCatches;
  final int streak;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    this.displayName,
    required this.xpPoints,
    required this.level,
    required this.totalCatches,
    required this.streak,
    required this.rank,
  });

  /// Erstellt ein LeaderboardEntry aus JSON (Supabase leaderboard view)
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      xpPoints: json['xp_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      totalCatches: json['total_catches'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }

  /// Konvertiert zu JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'xp_points': xpPoints,
      'level': level,
      'total_catches': totalCatches,
      'streak': streak,
      'rank': rank,
    };
  }

  /// Copy-Methode für Immutability
  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    int? xpPoints,
    int? level,
    int? totalCatches,
    int? streak,
    int? rank,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      totalCatches: totalCatches ?? this.totalCatches,
      streak: streak ?? this.streak,
      rank: rank ?? this.rank,
    );
  }

  /// Gibt einen Anzeigenamen zurück (oder "Unbekannt" als Fallback)
  String get displayNameOrDefault => displayName ?? 'Unbekannt';

  /// Prüft ob dies der aktuelle User ist
  bool isCurrentUser(String? currentUserId) {
    return currentUserId != null && userId == currentUserId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, displayName: $displayName, xp: $xpPoints, level: $level)';
  }
}
