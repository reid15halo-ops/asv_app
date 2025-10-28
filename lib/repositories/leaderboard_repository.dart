import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/leaderboard_entry.dart';

/// Repository für Leaderboard-Operationen
class LeaderboardRepository {
  final SupabaseClient supa;

  LeaderboardRepository(this.supa);

  /// Lädt die Top 100 Spieler aus der leaderboard View
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    final response = await supa
        .from('leaderboard')
        .select('*')
        .limit(limit);

    return (response as List)
        .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Lädt einen spezifischen Spieler aus dem Leaderboard
  Future<LeaderboardEntry?> getUserRank(String userId) async {
    final response = await supa
        .from('leaderboard')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return LeaderboardEntry.fromJson(response as Map<String, dynamic>);
  }

  /// Lädt die Top N Spieler
  Future<List<LeaderboardEntry>> getTopPlayers(int count) async {
    return getLeaderboard(limit: count);
  }

  /// Stream für Realtime-Updates des Leaderboards
  /// Hinweis: Realtime funktioniert nicht auf Views, daher Polling-basiert
  Stream<List<LeaderboardEntry>> watchLeaderboard({
    int limit = 100,
    Duration pollInterval = const Duration(seconds: 10),
  }) {
    return Stream.periodic(pollInterval).asyncMap((_) async {
      return await getLeaderboard(limit: limit);
    });
  }
}
