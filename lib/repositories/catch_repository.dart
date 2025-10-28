import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:asv_app/services/storage_service.dart';
import 'package:asv_app/repositories/member_repository.dart';
import 'package:asv_app/models/catch.dart';

String _yearKey(String userId, int year) => 'users/$userId/catches-$year.json';

String _csvKey(String userId, int year) => 'users/$userId/catches-$year.csv';

class CatchRepository {
  final SupabaseClient supa;
  CatchRepository(this.supa);
  StorageService get _storage => StorageService(supa);
  MemberRepository get _memberRepo => MemberRepository(supa);

  Future<int?> findMemberIdForUser(String userId) async {
    return _memberRepo.findMemberIdForUser(userId);
  }

  Future<void> insertCatch(Map<String, dynamic> data) async {
    // insert into DB
    await supa.from('catch').insert(data);

    // also append to per-user/year JSON file for easy export
    try {
      final userId = data['member_id']?.toString() ?? 'unknown';
      // determine year from captured_at if present
      var year = DateTime.now().year;
      if (data.containsKey('captured_at') && data['captured_at'] is String) {
        try { year = DateTime.parse(data['captured_at']).year; } catch (_) {}
      }
      final key = _yearKey(userId, year);
      final existing = await _storage.readJson(key);
      final list = (existing is List) ? List<Map<String,dynamic>>.from(existing.map((e) => Map<String,dynamic>.from(e as Map))) : <Map<String,dynamic>>[];
      list.add(Map<String,dynamic>.from(data));
      await _storage.writeJson(key, list);
    } catch (_) {
      // non-fatal; DB insert already done
    }
  }

  /// Export a user's catches for a given year to CSV and return a signed URL for download.
  Future<String?> exportUserYearCsv(String userId, int year, {int signedUrlExpiry = 3600}) async {
    final key = _yearKey(userId, year);
    final data = await _storage.readJson(key);
    if (data == null || data is! List || data.isEmpty) return null;

    // Determine CSV headers from union of keys
    final keys = <String>{};
    for (final item in data) {
      if (item is Map) keys.addAll(item.keys.map((k) => k.toString()));
    }
    final header = keys.toList();

    String _escape(String s) {
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"' + s.replaceAll('"', '""') + '"';
      }
      return s;
    }

    final rows = <String>[];
    rows.add(header.join(','));
    for (final item in data) {
      final cells = header.map((k) {
        final v = (item as Map).containsKey(k) ? item[k] : '';
        return _escape(v?.toString() ?? '');
      }).join(',');
      rows.add(cells);
    }
    final csv = rows.join('\n');

    final outKey = _csvKey(userId, year);
    await _storage.writeString(outKey, csv);
    final url = await _storage.getSignedUrl(outKey, expiresInSeconds: signedUrlExpiry);
    return url;
  }

  // ========== CRUD OPERATIONS ==========

  /// Lädt alle Catches für einen bestimmten Member
  /// Optional mit JOIN auf species und water_body für Namen
  Future<List<Catch>> getCatches({
    required int memberId,
    int? limit,
    int? offset,
    String? orderBy = 'captured_at',
    bool ascending = false,
  }) async {
    var query = supa
        .from('catch')
        .select('''
          id,
          member_id,
          species_id,
          length_cm,
          weight_g,
          water_body_id,
          photo_url,
          privacy_level,
          captured_at,
          created_at,
          species:species_id(name_de),
          water_body:water_body_id(name)
        ''')
        .eq('member_id', memberId);

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 100) - 1);
    }

    final response = await query;

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json as Map);

      // Flatten nested species and water_body
      if (data['species'] != null && data['species'] is Map) {
        data['species_name'] = (data['species'] as Map)['name_de'];
      }
      if (data['water_body'] != null && data['water_body'] is Map) {
        data['water_body_name'] = (data['water_body'] as Map)['name'];
      }

      return Catch.fromJson(data);
    }).toList();
  }

  /// Lädt einen einzelnen Catch by ID
  Future<Catch?> getCatchById(int catchId) async {
    final response = await supa
        .from('catch')
        .select('''
          id,
          member_id,
          species_id,
          length_cm,
          weight_g,
          water_body_id,
          photo_url,
          privacy_level,
          captured_at,
          created_at,
          species:species_id(name_de),
          water_body:water_body_id(name)
        ''')
        .eq('id', catchId)
        .maybeSingle();

    if (response == null) return null;

    final data = Map<String, dynamic>.from(response as Map);

    // Flatten nested species and water_body
    if (data['species'] != null && data['species'] is Map) {
      data['species_name'] = (data['species'] as Map)['name_de'];
    }
    if (data['water_body'] != null && data['water_body'] is Map) {
      data['water_body_name'] = (data['water_body'] as Map)['name'];
    }

    return Catch.fromJson(data);
  }

  /// Lädt Catches für ein bestimmtes Jahr
  Future<List<Catch>> getCatchesByYear({
    required int memberId,
    required int year,
  }) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    final response = await supa
        .from('catch')
        .select('''
          id,
          member_id,
          species_id,
          length_cm,
          weight_g,
          water_body_id,
          photo_url,
          privacy_level,
          captured_at,
          created_at,
          species:species_id(name_de),
          water_body:water_body_id(name)
        ''')
        .eq('member_id', memberId)
        .gte('captured_at', startDate.toIso8601String())
        .lte('captured_at', endDate.toIso8601String())
        .order('captured_at', ascending: false);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json as Map);

      if (data['species'] != null && data['species'] is Map) {
        data['species_name'] = (data['species'] as Map)['name_de'];
      }
      if (data['water_body'] != null && data['water_body'] is Map) {
        data['water_body_name'] = (data['water_body'] as Map)['name'];
      }

      return Catch.fromJson(data);
    }).toList();
  }

  /// Aktualisiert einen Catch
  Future<void> updateCatch(int catchId, Map<String, dynamic> updates) async {
    await supa
        .from('catch')
        .update(updates)
        .eq('id', catchId);
  }

  /// Löscht einen Catch
  Future<void> deleteCatch(int catchId) async {
    await supa
        .from('catch')
        .delete()
        .eq('id', catchId);
  }

  /// Löscht alle Catches für einen Member
  Future<void> deleteAllCatches(int memberId) async {
    await supa
        .from('catch')
        .delete()
        .eq('member_id', memberId);
  }

  /// Gibt Statistiken für einen Member zurück
  Future<Map<String, dynamic>> getCatchStats(int memberId) async {
    final catches = await getCatches(memberId: memberId);

    if (catches.isEmpty) {
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

    final totalWeight = catches
        .where((c) => c.weightG != null)
        .fold<int>(0, (sum, c) => sum + c.weightG!);

    final totalLength = catches
        .where((c) => c.lengthCm != null)
        .fold<int>(0, (sum, c) => sum + c.lengthCm!);

    final weightCount = catches.where((c) => c.weightG != null).length;
    final lengthCount = catches.where((c) => c.lengthCm != null).length;

    final biggestWeight = catches
        .where((c) => c.weightG != null)
        .fold<int>(0, (max, c) => c.weightG! > max ? c.weightG! : max);

    final biggestLength = catches
        .where((c) => c.lengthCm != null)
        .fold<int>(0, (max, c) => c.lengthCm! > max ? c.lengthCm! : max);

    final uniqueSpecies = catches
        .where((c) => c.speciesId != null)
        .map((c) => c.speciesId)
        .toSet()
        .length;

    return {
      'total_catches': catches.length,
      'total_weight_g': totalWeight,
      'avg_weight_g': weightCount > 0 ? (totalWeight / weightCount).round() : 0,
      'avg_length_cm': lengthCount > 0 ? (totalLength / lengthCount).round() : 0,
      'biggest_weight_g': biggestWeight,
      'biggest_length_cm': biggestLength,
      'species_count': uniqueSpecies,
    };
  }

  /// Stream für Realtime-Updates von Catches
  Stream<List<Catch>> watchCatches({required int memberId}) {
    return supa
        .from('catch')
        .stream(primaryKey: ['id'])
        .eq('member_id', memberId)
        .order('captured_at', ascending: false)
        .map((data) {
          return data.map((json) {
            final catchData = Map<String, dynamic>.from(json);
            // Note: Stream doesn't support JOINs, so species_name and water_body_name will be null
            return Catch.fromJson(catchData);
          }).toList();
        });
  }
}
