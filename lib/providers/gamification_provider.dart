import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/gamification_data.dart';

/// Provider für Gamification-Daten (XP, Level, Achievements)
class GamificationNotifier extends StateNotifier<GamificationData?> {
  GamificationNotifier() : super(null);

  /// Lädt Gamification-Daten für den aktuellen User
  Future<void> loadGamificationData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = null;
        return;
      }

      // Versuche aus gamification Tabelle zu laden
      final response = await Supabase.instance.client
          .from('gamification')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        state = GamificationData.fromJson(response);
      } else {
        // Erstelle neue Gamification-Daten
        state = GamificationData(
          xpPoints: 0,
          level: 1,
          totalCatches: 0,
          streak: 0,
          rank: 0,
          achievements: GamificationData.defaultAchievements,
        );
      }
    } catch (e) {
      // Bei Fehler: Demo-Daten für Development
      state = GamificationData(
        xpPoints: 1250,
        level: 5,
        totalCatches: 42,
        streak: 7,
        rank: 3,
        achievements: GamificationData.defaultAchievements
            .map((a) => a.requirement <= 10 ? a.copyWith(unlocked: true) : a)
            .toList(),
      );
    }
  }

  /// Fügt XP hinzu und checked für Level-Up
  Future<void> addXp(int xp) async {
    if (state == null) return;

    final newXp = state!.xpPoints + xp;
    final newLevel = (newXp / 200).floor() + 1;

    state = GamificationData(
      xpPoints: newXp,
      level: newLevel,
      totalCatches: state!.totalCatches,
      streak: state!.streak,
      rank: state!.rank,
      achievements: state!.achievements,
    );

    // Speichere in DB (optional)
    await _saveToDatabase();
  }

  /// Erhöht die Anzahl der Fänge und prüft Achievements
  Future<void> incrementCatches() async {
    if (state == null) return;

    final newTotal = state!.totalCatches + 1;
    final updatedAchievements = _checkAchievements(newTotal);

    state = GamificationData(
      xpPoints: state!.xpPoints,
      level: state!.level,
      totalCatches: newTotal,
      streak: state!.streak,
      rank: state!.rank,
      achievements: updatedAchievements,
    );

    await _saveToDatabase();
  }

  /// Prüft welche Achievements freigeschaltet werden sollten
  List<Achievement> _checkAchievements(int totalCatches) {
    return state!.achievements.map((achievement) {
      if (!achievement.unlocked) {
        // Check catch-basierte Achievements
        if (achievement.id.startsWith('catch_')) {
          if (totalCatches >= achievement.requirement) {
            return achievement.copyWith(
              unlocked: true,
              unlockedAt: DateTime.now(),
            );
          }
        }
      }
      return achievement;
    }).toList();
  }

  /// Entsperrt ein Achievement manuell
  void unlockAchievement(String achievementId) {
    if (state == null) return;

    final updatedAchievements = state!.achievements.map((a) {
      if (a.id == achievementId && !a.unlocked) {
        return a.copyWith(unlocked: true, unlockedAt: DateTime.now());
      }
      return a;
    }).toList();

    state = GamificationData(
      xpPoints: state!.xpPoints,
      level: state!.level,
      totalCatches: state!.totalCatches,
      streak: state!.streak,
      rank: state!.rank,
      achievements: updatedAchievements,
    );

    _saveToDatabase();
  }

  /// Speichert Daten in Datenbank (optional, wenn Tabelle existiert)
  Future<void> _saveToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || state == null) return;

      await Supabase.instance.client.from('gamification').upsert({
        'user_id': user.id,
        ...state!.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore if table doesn't exist yet
    }
  }

  /// Setzt die Daten zurück
  void reset() {
    state = null;
  }
}

/// Global Provider für Gamification
final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationData?>((ref) {
  return GamificationNotifier();
});
