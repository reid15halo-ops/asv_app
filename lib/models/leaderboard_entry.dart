/// Leaderboard-Eintrag für Ranglisten
class LeaderboardEntry {
  final int rank;
  final int memberId;
  final String memberName;
  final String? memberEmail;
  final int totalScore;
  final int totalCatches;
  final int? bestCatchLength;
  final int? bestCatchWeight;
  final String? bestCatchSpecies;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.memberId,
    required this.memberName,
    this.memberEmail,
    required this.totalScore,
    required this.totalCatches,
    this.bestCatchLength,
    this.bestCatchWeight,
    this.bestCatchSpecies,
    this.isCurrentUser = false,
  });

  /// Gibt Initialen für Avatar zurück
  String get initials {
    final parts = memberName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
  }

  /// Gibt durchschnittlichen Score pro Fang zurück
  double get averageScore {
    if (totalCatches == 0) return 0.0;
    return totalScore / totalCatches;
  }

  /// Formatierte beste Länge
  String get bestLengthFormatted {
    if (bestCatchLength == null) return '-';
    return '$bestCatchLength cm';
  }

  /// Formatierte bestes Gewicht
  String get bestWeightFormatted {
    if (bestCatchWeight == null) return '-';
    if (bestCatchWeight! >= 1000) {
      return '${(bestCatchWeight! / 1000).toStringAsFixed(1)} kg';
    }
    return '$bestCatchWeight g';
  }

  /// Von JSON
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      memberId: json['member_id'] as int,
      memberName: json['member_name'] as String? ?? 'Unbekannt',
      memberEmail: json['member_email'] as String?,
      totalScore: json['total_score'] as int? ?? 0,
      totalCatches: json['total_catches'] as int? ?? 0,
      bestCatchLength: json['best_catch_length'] as int?,
      bestCatchWeight: json['best_catch_weight'] as int?,
      bestCatchSpecies: json['best_catch_species'] as String?,
      isCurrentUser: isCurrentUser,
    );
  }

  /// Zu JSON
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'member_id': memberId,
      'member_name': memberName,
      'member_email': memberEmail,
      'total_score': totalScore,
      'total_catches': totalCatches,
      'best_catch_length': bestCatchLength,
      'best_catch_weight': bestCatchWeight,
      'best_catch_species': bestCatchSpecies,
    };
  }

  /// Copy with
  LeaderboardEntry copyWith({
    int? rank,
    int? memberId,
    String? memberName,
    String? memberEmail,
    int? totalScore,
    int? totalCatches,
    int? bestCatchLength,
    int? bestCatchWeight,
    String? bestCatchSpecies,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberEmail: memberEmail ?? this.memberEmail,
      totalScore: totalScore ?? this.totalScore,
      totalCatches: totalCatches ?? this.totalCatches,
      bestCatchLength: bestCatchLength ?? this.bestCatchLength,
      bestCatchWeight: bestCatchWeight ?? this.bestCatchWeight,
      bestCatchSpecies: bestCatchSpecies ?? this.bestCatchSpecies,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

/// Zeitraum-Filter für Leaderboard
enum LeaderboardPeriod {
  monthly('monthly', 'Monat', 'Dieser Monat'),
  yearly('yearly', 'Jahr', 'Dieses Jahr'),
  allTime('all_time', 'Gesamt', 'Alle Zeit');

  const LeaderboardPeriod(this.value, this.shortName, this.displayName);

  final String value;
  final String shortName;
  final String displayName;
}
