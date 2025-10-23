import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple key-based cache backed by SharedPreferences.
/// Stores JSON-serializable values with a timestamp and TTL in seconds.
class CacheService {
  final SharedPreferences _prefs;

  CacheService._(this._prefs);

  static Future<CacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheService._(prefs);
  }

  Future<void> setJson(String key, Object value) async {
    final wrapper = jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'v': value});
    await _prefs.setString(key, wrapper);
  }

  /// Returns null if not found or expired.
  dynamic getJson(String key, {int? ttlSeconds}) {
    final s = _prefs.getString(key);
    if (s == null) return null;
    try {
      final Map<String, dynamic> wrapper = jsonDecode(s);
      final ts = wrapper['ts'] as int?;
      final v = wrapper['v'];
      if (ts == null) return null;
      if (ttlSeconds != null) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > ttlSeconds * 1000) return null;
      }
      return v;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async => _prefs.remove(key);
}
