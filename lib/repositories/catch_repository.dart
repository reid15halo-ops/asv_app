import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:asv_app/services/storage_service.dart';
import 'package:asv_app/repositories/member_repository.dart';

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
}
