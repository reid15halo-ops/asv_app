import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/repositories/catch_repository.dart';
import 'package:asv_app/repositories/member_repository.dart';

/// Provider für CatchRepository
final catchRepositoryProvider = Provider<CatchRepository>((ref) {
  return CatchRepository(Supabase.instance.client);
});

/// Provider für MemberRepository
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(Supabase.instance.client);
});

/// Provider für Catches-Liste
class CatchesNotifier extends StateNotifier<AsyncValue<List<Catch>>> {
  final CatchRepository _repository;
  final MemberRepository _memberRepository;
  int? _currentMemberId;

  CatchesNotifier(this._repository, this._memberRepository)
      : super(const AsyncValue.loading()) {
    _loadCatches();
  }

  Future<void> _loadCatches() async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Hole Member-ID für aktuellen User
      final memberId = await _memberRepository.findMemberIdForUser(userId);
      if (memberId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      _currentMemberId = memberId;

      final catches = await _repository.getCatches(memberId: memberId);
      state = AsyncValue.data(catches);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt Catches neu
  Future<void> refresh() async {
    await _loadCatches();
  }

  /// Lädt Catches für ein bestimmtes Jahr
  Future<void> loadByYear(int year) async {
    if (_currentMemberId == null) {
      await _loadCatches();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final catches = await _repository.getCatchesByYear(
        memberId: _currentMemberId!,
        year: year,
      );
      state = AsyncValue.data(catches);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Löscht einen Catch
  Future<void> deleteCatch(int catchId) async {
    try {
      await _repository.deleteCatch(catchId);

      // Update local state
      state.whenData((catches) {
        final updatedCatches = catches.where((c) => c.id != catchId).toList();
        state = AsyncValue.data(updatedCatches);
      });
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Aktualisiert einen Catch
  Future<void> updateCatch(int catchId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateCatch(catchId, updates);
      // Reload nach Update
      await refresh();
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }
}

/// Global Provider für Catches
final catchesProvider =
    StateNotifierProvider<CatchesNotifier, AsyncValue<List<Catch>>>((ref) {
  final repository = ref.watch(catchRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);
  return CatchesNotifier(repository, memberRepository);
});

/// Provider für einen einzelnen Catch
final catchByIdProvider =
    FutureProvider.family<Catch?, int>((ref, catchId) async {
  final repository = ref.watch(catchRepositoryProvider);
  return await repository.getCatchById(catchId);
});

/// Provider für Catch-Statistiken
final catchStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(catchRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return {
      'total_catches': 0,
      'total_weight_g': 0,
      'avg_weight_g': 0,
      'avg_length_cm': 0,
      'biggest_weight_g': 0,
      'biggest_length_cm': 0,
      'species_count': 0,
    };
  }

  final memberId = await memberRepository.findMemberIdForUser(userId);
  if (memberId == null) {
    return {
      'total_catches': 0,
      'total_weight_g': 0,
      'avg_weight_g': 0,
      'avg_length_cm': 0,
      'biggest_weight_g': 0,
      'biggest_length_cm': 0,
      'species_count': 0,
    };
  }

  return await repository.getCatchStats(memberId);
});

/// Provider für aktuelle Member-ID
final currentMemberIdProvider = FutureProvider<int?>((ref) async {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return await memberRepository.findMemberIdForUser(userId);
});
