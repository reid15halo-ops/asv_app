import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/leaderboard_entry.dart';
import 'package:asv_app/repositories/leaderboard_repository.dart';

/// Provider für LeaderboardRepository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(Supabase.instance.client);
});

/// Provider für Leaderboard-Daten
class LeaderboardNotifier extends StateNotifier<AsyncValue<List<LeaderboardEntry>>> {
  final LeaderboardRepository _repository;

  LeaderboardNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLeaderboard();
  }

  /// Lädt das Leaderboard (Top 100)
  Future<void> loadLeaderboard({int limit = 100}) async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getLeaderboard(limit: limit);
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt nur die Top N Spieler
  Future<void> loadTopPlayers(int count) async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getTopPlayers(count);
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh - lädt Leaderboard neu
  Future<void> refresh() async {
    await loadLeaderboard();
  }
}

/// Global Provider für Leaderboard
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, AsyncValue<List<LeaderboardEntry>>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return LeaderboardNotifier(repository);
});

/// Provider für User-Rang (findet den aktuellen User im Leaderboard)
final currentUserRankProvider = FutureProvider<LeaderboardEntry?>((ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  final currentUser = Supabase.instance.client.auth.currentUser;

  if (currentUser == null) return null;

  return await repository.getUserRank(currentUser.id);
});

/// Provider für Top 3 Spieler (Podium)
final topThreePlayersProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return await repository.getTopPlayers(3);
});
