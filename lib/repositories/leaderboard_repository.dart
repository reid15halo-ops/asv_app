import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/leaderboard_entry.dart';

/// Repository für Leaderboard-Daten
class LeaderboardRepository {
  final SupabaseClient supa;

  LeaderboardRepository(this.supa);

  /// Gibt Leaderboard für einen Zeitraum zurück
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    int limit = 100,
  }) async {
    try {
      // Bestimme Zeitraum-Filter
      DateTime? startDate;
      if (period == LeaderboardPeriod.monthly) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, 1);
      } else if (period == LeaderboardPeriod.yearly) {
        final now = DateTime.now();
        startDate = DateTime(now.year, 1, 1);
      }

      // Basis-Query: Aggregiere Catches pro Member
      String query = '''
        member_id,
        member:member_id(first_name, last_name, email)
      ''';

      var catchQuery = supa.from('catch').select(query);

      // Zeitraum-Filter anwenden
      if (startDate != null) {
        catchQuery = catchQuery.gte('captured_at', startDate.toIso8601String());
      }

      final response = await catchQuery;
      final catches = response as List;

      // Gruppiere nach Member und berechne Scores
      final Map<int, Map<String, dynamic>> memberStats = {};

      for (final catchData in catches) {
        final memberId = catchData['member_id'] as int;
        final member = catchData['member'] as Map<String, dynamic>?;

        // Berechne Score für diesen Fang (gleiche Logik wie in Catch-Model)
        final lengthCm = catchData['length_cm'] as int?;
        final weightG = catchData['weight_g'] as int?;
        final photoUrl = catchData['photo_url'] as String?;
        final score = _calculateScore(lengthCm, weightG, photoUrl != null);

        if (!memberStats.containsKey(memberId)) {
          String memberName = 'Unbekannt';
          if (member != null) {
            final firstName = member['first_name'] as String?;
            final lastName = member['last_name'] as String?;
            if (firstName != null && lastName != null) {
              memberName = '$firstName $lastName';
            } else if (firstName != null) {
              memberName = firstName;
            } else if (lastName != null) {
              memberName = lastName;
            }
          }

          memberStats[memberId] = {
            'member_id': memberId,
            'member_name': memberName,
            'member_email': member?['email'] as String?,
            'total_score': 0,
            'total_catches': 0,
            'best_catch_length': 0,
            'best_catch_weight': 0,
            'best_catch_species': null,
          };
        }

        // Aktualisiere Statistiken
        memberStats[memberId]!['total_score'] += score;
        memberStats[memberId]!['total_catches'] += 1;

        // Aktualisiere beste Werte
        if (lengthCm != null && lengthCm > (memberStats[memberId]!['best_catch_length'] as int)) {
          memberStats[memberId]!['best_catch_length'] = lengthCm;
        }
        if (weightG != null && weightG > (memberStats[memberId]!['best_catch_weight'] as int)) {
          memberStats[memberId]!['best_catch_weight'] = weightG;
          // Speichere auch die Art des besten Fangs
          if (catchData['species_id'] != null) {
            final speciesResponse = await supa
                .from('species')
                .select('name_de')
                .eq('id', catchData['species_id'])
                .maybeSingle();
            if (speciesResponse != null) {
              memberStats[memberId]!['best_catch_species'] = speciesResponse['name_de'] as String?;
            }
          }
        }
      }

      // Konvertiere zu Liste und sortiere nach Score
      final entries = memberStats.values.toList();
      entries.sort((a, b) => (b['total_score'] as int).compareTo(a['total_score'] as int));

      // Füge Ranking hinzu
      final List<LeaderboardEntry> leaderboard = [];
      for (int i = 0; i < entries.length && i < limit; i++) {
        final entry = entries[i];
        entry['rank'] = i + 1;

        // Prüfe ob aktueller User
        final currentUserId = supa.auth.currentUser?.id;
        bool isCurrentUser = false;
        if (currentUserId != null) {
          final memberResponse = await supa
              .from('member')
              .select('id')
              .eq('id', entry['member_id'])
              .eq('user_id', currentUserId)
              .maybeSingle();
          isCurrentUser = memberResponse != null;
        }

        leaderboard.add(LeaderboardEntry.fromJson(entry, isCurrentUser: isCurrentUser));
      }

      return leaderboard;
    } catch (e) {
      return [];
    }
  }

  /// Gibt Position des aktuellen Users zurück
  Future<LeaderboardEntry?> getCurrentUserPosition({
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
  }) async {
    try {
      final currentUserId = supa.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Hole Member ID
      final memberResponse = await supa
          .from('member')
          .select('id')
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (memberResponse == null) return null;
      final memberId = memberResponse['id'] as int;

      // Hole komplettes Leaderboard
      final leaderboard = await getLeaderboard(period: period, limit: 1000);

      // Finde User in Leaderboard
      for (final entry in leaderboard) {
        if (entry.memberId == memberId) {
          return entry.copyWith(isCurrentUser: true);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Berechnet Score für einen Fang (gleiche Logik wie Catch.score)
  int _calculateScore(int? lengthCm, int? weightG, bool hasPhoto) {
    int score = 10; // Basis-Score

    // Längen-Boni
    if (lengthCm != null) {
      if (lengthCm > 100) {
        score += 50;
      } else if (lengthCm > 70) {
        score += 30;
      } else if (lengthCm > 50) {
        score += 20;
      }
    }

    // Gewichts-Boni
    if (weightG != null) {
      if (weightG > 10000) {
        score += 40;
      } else if (weightG > 5000) {
        score += 25;
      } else if (weightG > 1000) {
        score += 15;
      }
    }

    // Foto-Bonus
    if (hasPhoto) {
      score += 10;
    }

    // Vollständigkeits-Bonus
    if (lengthCm != null && weightG != null && hasPhoto) {
      score += 5;
    }

    return score;
  }
}
