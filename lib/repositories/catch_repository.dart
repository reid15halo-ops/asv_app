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

  // ===== CRUD Operations =====

  /// Gibt alle Fänge zurück (mit Joins für Namen)
  Future<List<Catch>> getAllCatches({
    int limit = 100,
    int offset = 0,
    String? orderBy = 'captured_at',
    bool ascending = false,
  }) async {
    try {
      var query = supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .order(orderBy ?? 'captured_at', ascending: ascending)
          .limit(limit);

      if (offset > 0) {
        query = query.range(offset, offset + limit - 1);
      }

      final response = await query;
      return _parseCatchList(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Gibt Fänge für einen bestimmten Member zurück
  Future<List<Catch>> getCatchesByMember(
    int memberId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .eq('member_id', memberId)
          .order('captured_at', ascending: false)
          .limit(limit);

      return _parseCatchList(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Gibt Fänge für aktuellen User zurück
  Future<List<Catch>> getMyCatches({int limit = 100}) async {
    try {
      final userId = supa.auth.currentUser?.id;
      if (userId == null) return [];

      final memberId = await findMemberIdForUser(userId);
      if (memberId == null) return [];

      return await getCatchesByMember(memberId, limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Gibt einen einzelnen Fang zurück
  Future<Catch?> getCatchById(String catchId) async {
    try {
      final response = await supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .eq('id', catchId)
          .maybeSingle();

      if (response == null) return null;
      return _parseCatch(response);
    } catch (e) {
      return null;
    }
  }

  /// Gibt Fänge nach Zeitraum zurück
  Future<List<Catch>> getCatchesByDateRange(
    DateTime start,
    DateTime end, {
    int? memberId,
    String? speciesId,
    String? waterBodyId,
  }) async {
    try {
      var query = supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .gte('captured_at', start.toIso8601String())
          .lte('captured_at', end.toIso8601String());

      if (memberId != null) {
        query = query.eq('member_id', memberId);
      }

      if (speciesId != null) {
        query = query.eq('species_id', speciesId);
      }

      if (waterBodyId != null) {
        query = query.eq('water_body_id', waterBodyId);
      }

      query = query.order('captured_at', ascending: false);

      final response = await query;
      return _parseCatchList(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Gibt Fänge nach Fischart zurück
  Future<List<Catch>> getCatchesBySpecies(
    String speciesId, {
    int limit = 50,
  }) async {
    try {
      final response = await supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .eq('species_id', speciesId)
          .order('captured_at', ascending: false)
          .limit(limit);

      return _parseCatchList(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Gibt Fänge nach Gewässer zurück
  Future<List<Catch>> getCatchesByWaterBody(
    String waterBodyId, {
    int limit = 50,
  }) async {
    try {
      final response = await supa
          .from('catch')
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .eq('water_body_id', waterBodyId)
          .order('captured_at', ascending: false)
          .limit(limit);

      return _parseCatchList(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Gibt Statistiken für einen Member zurück
  Future<Map<String, dynamic>> getMemberStats(int memberId) async {
    try {
      final catches = await getCatchesByMember(memberId, limit: 1000);

      final totalCatches = catches.length;
      final totalWeight = catches
          .where((c) => c.weightG != null)
          .fold<int>(0, (sum, c) => sum + c.weightG!);
      final avgWeight = totalWeight > 0 && catches.isNotEmpty
          ? totalWeight / catches.where((c) => c.weightG != null).length
          : 0.0;
      final maxWeight = catches
          .where((c) => c.weightG != null)
          .fold<int>(0, (max, c) => c.weightG! > max ? c.weightG! : max);
      final maxLength = catches
          .where((c) => c.lengthCm != null)
          .fold<int>(0, (max, c) => c.lengthCm! > max ? c.lengthCm! : max);

      // Species count
      final speciesMap = <String, int>{};
      for (final catch_ in catches) {
        if (catch_.speciesName != null) {
          speciesMap[catch_.speciesName!] =
              (speciesMap[catch_.speciesName!] ?? 0) + 1;
        }
      }

      return {
        'total_catches': totalCatches,
        'total_weight_g': totalWeight,
        'avg_weight_g': avgWeight,
        'max_weight_g': maxWeight,
        'max_length_cm': maxLength,
        'species_distribution': speciesMap,
        'catches_with_photo': catches.where((c) => c.hasPhoto).length,
      };
    } catch (e) {
      return {
        'total_catches': 0,
        'total_weight_g': 0,
        'avg_weight_g': 0.0,
        'max_weight_g': 0,
        'max_length_cm': 0,
        'species_distribution': {},
        'catches_with_photo': 0,
      };
    }
  }

  /// Erstellt einen neuen Fang
  Future<Catch?> createCatch(Catch catch_) async {
    try {
      final response = await supa
          .from('catch')
          .insert(catch_.toJson())
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .single();

      return _parseCatch(response);
    } catch (e) {
      return null;
    }
  }

  /// Aktualisiert einen Fang
  Future<Catch?> updateCatch(Catch catch_) async {
    try {
      if (catch_.id == null) return null;

      final updateData = catch_.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supa
          .from('catch')
          .update(updateData)
          .eq('id', catch_.id!)
          .select('''
            *,
            species:species_id(name_de),
            water_body:water_body_id(name),
            member:member_id(first_name,last_name)
          ''')
          .single();

      return _parseCatch(response);
    } catch (e) {
      return null;
    }
  }

  /// Löscht einen Fang
  Future<bool> deleteCatch(String catchId) async {
    try {
      await supa.from('catch').delete().eq('id', catchId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== Legacy Insert Method (kompatibel mit bestehendem Code) =====

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

  // ===== Helper Methods =====

  /// Parsed einen einzelnen Catch aus JSON response
  Catch _parseCatch(Map<String, dynamic> json) {
    // Extract nested data
    String? speciesName;
    if (json['species'] is Map) {
      speciesName = json['species']['name_de'] as String?;
    }

    String? waterBodyName;
    if (json['water_body'] is Map) {
      waterBodyName = json['water_body']['name'] as String?;
    }

    String? memberName;
    if (json['member'] is Map) {
      final member = json['member'] as Map;
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

    return Catch.fromJson({
      ...json,
      'species_name': speciesName,
      'water_body_name': waterBodyName,
      'member_name': memberName,
    });
  }

  /// Parsed eine Liste von Catches
  List<Catch> _parseCatchList(List response) {
    return response.map((json) => _parseCatch(json as Map<String, dynamic>)).toList();
  }
}
