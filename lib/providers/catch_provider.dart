import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/repositories/catch_repository.dart';

/// Provider für CatchRepository
final catchRepositoryProvider = Provider<CatchRepository>((ref) {
  return CatchRepository(Supabase.instance.client);
});

/// Provider für alle Fänge
final allCatchesProvider = FutureProvider.family<List<Catch>, int>((ref, limit) async {
  final repository = ref.read(catchRepositoryProvider);
  return await repository.getAllCatches(limit: limit);
});

/// Provider für Fänge des aktuellen Users
final myCatchesProvider = FutureProvider<List<Catch>>((ref) async {
  final repository = ref.read(catchRepositoryProvider);
  return await repository.getMyCatches(limit: 100);
});

/// Provider für einen einzelnen Fang
final catchByIdProvider = FutureProvider.family<Catch?, String>((ref, catchId) async {
  final repository = ref.read(catchRepositoryProvider);
  return await repository.getCatchById(catchId);
});

/// Provider für Member-Statistiken
final memberStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, memberId) async {
  final repository = ref.read(catchRepositoryProvider);
  return await repository.getMemberStats(memberId);
});

/// StateNotifier für Catch-Management mit Filtern
class CatchNotifier extends StateNotifier<AsyncValue<List<Catch>>> {
  CatchNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadCatches();
  }

  final CatchRepository repository;

  // Filter-Optionen
  String? _filterSpeciesId;
  String? _filterWaterBodyId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  int? _filterMemberId;
  String _sortBy = 'captured_at';
  bool _ascending = false;

  // Getters für Filter
  String? get filterSpeciesId => _filterSpeciesId;
  String? get filterWaterBodyId => _filterWaterBodyId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  int? get filterMemberId => _filterMemberId;
  String get sortBy => _sortBy;
  bool get ascending => _ascending;

  /// Lädt alle Fänge
  Future<void> loadCatches() async {
    state = const AsyncValue.loading();
    try {
      List<Catch> catches;

      if (_filterStartDate != null && _filterEndDate != null) {
        // Laden mit Datum-Filter
        catches = await repository.getCatchesByDateRange(
          _filterStartDate!,
          _filterEndDate!,
          memberId: _filterMemberId,
          speciesId: _filterSpeciesId,
          waterBodyId: _filterWaterBodyId,
        );
      } else if (_filterMemberId != null) {
        // Laden für bestimmten Member
        catches = await repository.getCatchesByMember(_filterMemberId!);
      } else if (_filterSpeciesId != null) {
        // Laden nach Art
        catches = await repository.getCatchesBySpecies(_filterSpeciesId!);
      } else if (_filterWaterBodyId != null) {
        // Laden nach Gewässer
        catches = await repository.getCatchesByWaterBody(_filterWaterBodyId!);
      } else {
        // Laden aller Fänge
        catches = await repository.getAllCatches(
          orderBy: _sortBy,
          ascending: _ascending,
        );
      }

      state = AsyncValue.data(catches);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt nur meine Fänge
  Future<void> loadMyCatches() async {
    state = const AsyncValue.loading();
    try {
      final catches = await repository.getMyCatches();
      state = AsyncValue.data(catches);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Setzt Filter für Fischart
  void setSpeciesFilter(String? speciesId) {
    _filterSpeciesId = speciesId;
    loadCatches();
  }

  /// Setzt Filter für Gewässer
  void setWaterBodyFilter(String? waterBodyId) {
    _filterWaterBodyId = waterBodyId;
    loadCatches();
  }

  /// Setzt Filter für Datum-Bereich
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    loadCatches();
  }

  /// Setzt Filter für Member
  void setMemberFilter(int? memberId) {
    _filterMemberId = memberId;
    loadCatches();
  }

  /// Setzt Sortierung
  void setSorting(String sortBy, {bool ascending = false}) {
    _sortBy = sortBy;
    _ascending = ascending;
    loadCatches();
  }

  /// Entfernt alle Filter
  void clearFilters() {
    _filterSpeciesId = null;
    _filterWaterBodyId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterMemberId = null;
    loadCatches();
  }

  /// Prüft ob Filter aktiv sind
  bool get hasActiveFilters {
    return _filterSpeciesId != null ||
           _filterWaterBodyId != null ||
           _filterStartDate != null ||
           _filterEndDate != null ||
           _filterMemberId != null;
  }

  /// Erstellt einen neuen Fang
  Future<bool> createCatch(Catch catch_) async {
    try {
      final created = await repository.createCatch(catch_);
      if (created != null) {
        await loadCatches(); // Reload nach Erstellung
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Aktualisiert einen Fang
  Future<bool> updateCatch(Catch catch_) async {
    try {
      final updated = await repository.updateCatch(catch_);
      if (updated != null) {
        await loadCatches(); // Reload nach Update
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Löscht einen Fang
  Future<bool> deleteCatch(String catchId) async {
    try {
      final success = await repository.deleteCatch(catchId);
      if (success) {
        await loadCatches(); // Reload nach Löschung
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Refresh
  Future<void> refresh() async {
    await loadCatches();
  }
}

/// Provider für CatchNotifier
final catchNotifierProvider = StateNotifierProvider<CatchNotifier, AsyncValue<List<Catch>>>((ref) {
  final repository = ref.watch(catchRepositoryProvider);
  return CatchNotifier(repository);
});
