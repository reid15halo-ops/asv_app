/// Gamification-Datenmodell für Jugend-Features
class GamificationData {
  final int xpPoints;
  final int level;
  final int totalCatches;
  final int streak;
  final int rank;
  final List<Achievement> achievements;

  GamificationData({
    required this.xpPoints,
    required this.level,
    required this.totalCatches,
    required this.streak,
    required this.rank,
    required this.achievements,
  });

  /// Berechnet XP für nächstes Level
  int get xpForNextLevel => level * 200;

  /// Berechnet aktuellen Fortschritt zum nächsten Level (0.0 - 1.0)
  double get progressToNextLevel {
    final currentLevelXp = (level - 1) * 200;
    final xpInCurrentLevel = xpPoints - currentLevelXp;
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  /// Berechnet XP im aktuellen Level
  int get xpInCurrentLevel {
    final currentLevelXp = (level - 1) * 200;
    return xpPoints - currentLevelXp;
  }

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    return GamificationData(
      xpPoints: json['xp_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      totalCatches: json['total_catches'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp_points': xpPoints,
      'level': level,
      'total_catches': totalCatches,
      'streak': streak,
      'rank': rank,
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }

  /// Berechnet XP basierend auf Fang
  static int calculateXpForCatch({
    required double lengthCm,
    required double weightG,
    bool isRare = false,
  }) {
    int baseXp = 10;

    // Bonus für Größe
    if (lengthCm > 50) baseXp += 20;
    if (lengthCm > 70) baseXp += 30;

    // Bonus für Gewicht
    if (weightG > 1000) baseXp += 15;
    if (weightG > 5000) baseXp += 25;

    // Bonus für seltene Arten
    if (isRare) baseXp += 50;

    return baseXp;
  }

  /// Standard-Achievements
  static List<Achievement> get defaultAchievements => [
        Achievement(
          id: 'first_catch',
          title: 'Erster Fang',
          description: 'Erfasse deinen ersten Fang',
          iconName: 'check_circle',
          unlocked: false,
          requirement: 1,
        ),
        Achievement(
          id: 'catch_10',
          title: '10 Fänge',
          description: 'Erfasse 10 Fänge',
          iconName: 'emoji_events',
          unlocked: false,
          requirement: 10,
        ),
        Achievement(
          id: 'catch_25',
          title: '25 Fänge',
          description: 'Erfasse 25 Fänge',
          iconName: 'military_tech',
          unlocked: false,
          requirement: 25,
        ),
        Achievement(
          id: 'catch_50',
          title: '50 Fänge',
          description: 'Erfasse 50 Fänge',
          iconName: 'workspace_premium',
          unlocked: false,
          requirement: 50,
        ),
        Achievement(
          id: 'big_catch',
          title: 'Großer Fang',
          description: 'Fange einen Fisch über 70cm',
          iconName: 'stars',
          unlocked: false,
          requirement: 1,
        ),
        Achievement(
          id: 'week_streak',
          title: '7-Tage Streak',
          description: 'Angel 7 Tage hintereinander',
          iconName: 'local_fire_department',
          unlocked: false,
          requirement: 7,
        ),
      ];
}

/// Achievement (Errungenschaft)
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool unlocked;
  final int requirement;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlocked,
    required this.requirement,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'emoji_events',
      unlocked: json['unlocked'] as bool? ?? false,
      requirement: json['requirement'] as int? ?? 1,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'unlocked': unlocked,
      'requirement': requirement,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    bool? unlocked,
    int? requirement,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      unlocked: unlocked ?? this.unlocked,
      requirement: requirement ?? this.requirement,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
