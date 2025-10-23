import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// StorageService: handles uploads and signed URL generation for Supabase Storage.
class StorageService {
  final SupabaseClient supa;
  final String bucket;

  StorageService(this.supa, {this.bucket = 'catch_photos'});

  /// Uploads a file to path inside bucket. onProgress is best-effort and called with 0..1.
  Future<String?> uploadFile(File file, String path, {void Function(double)? onProgress, bool preferSignedUrl = true, int signedUrlExpiry = 3600}) async {
    try {
      onProgress?.call(0.0);
      await supa.storage.from(bucket).upload(path, file);
      onProgress?.call(1.0);

      // If the caller prefers a signed URL (useful for private buckets), try
      // to create one. If that fails, fall back to the public URL.
      if (preferSignedUrl) {
        try {
          final signed = await getSignedUrl(path, expiresInSeconds: signedUrlExpiry);
          if (signed != null && signed.isNotEmpty) return signed;
        } catch (_) {
          // fall through to public URL
        }
      }

      final pub = supa.storage.from(bucket).getPublicUrl(path);
      return pub.toString();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a signed URL valid for [expiresInSeconds]. Useful for private buckets.
  Future<String?> getSignedUrl(String path, {int expiresInSeconds = 3600}) async {
    try {
      final res = await supa.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
      // SDK may return a String or a Map-like response. Normalize common shapes.
      if (res == null) return null;
      if (res is String) return res;
      if (res is Map) {
        // common keys: 'signedURL', 'signed_url', 'signedUrl'
        for (final key in ['signedURL', 'signed_url', 'signedUrl', 'url']) {
          if (res.containsKey(key) && res[key] is String) return res[key] as String;
        }
        // if there's a single string value somewhere, return its toString
        try {
          final vals = res.values.where((v) => v is String).toList();
          if (vals.isNotEmpty) return vals.first as String;
        } catch (_) {}
      }
      return res.toString();
    } catch (e) {
      rethrow;
    }
  }

  /// Download the raw bytes for a stored object, or null if not found.
  Future<List<int>?> downloadBytes(String path) async {
    try {
      final res = await supa.storage.from(bucket).download(path);
      if (res is List<int>) return res;
      // some SDKs return Uint8List
      if (res is Uint8List) return res.toList();
      return null;
    } catch (e) {
      // If file doesn't exist, supabase may throw; return null to indicate missing
      return null;
    }
  }

  /// Read a JSON file from storage and decode it. Returns null if not present or on error.
  Future<dynamic> readJson(String path) async {
    try {
      final bytes = await downloadBytes(path);
      if (bytes == null) return null;
      final s = utf8.decode(bytes);
      return json.decode(s);
    } catch (e) {
      return null;
    }
  }

  /// Write JSON data to storage by creating a temporary file and uploading it.
  Future<void> writeJson(String path, dynamic data) async {
    final tmpDir = Directory.systemTemp;
    final base = p.basename(path);
    final tmp = File(p.join(tmpDir.path, 'asv_${DateTime.now().millisecondsSinceEpoch}_$base'));
    await tmp.writeAsString(json.encode(data));
    try {
      await uploadFile(tmp, path, preferSignedUrl: false);
    } finally {
      try { await tmp.delete(); } catch (_) {}
    }
  }

  /// Write arbitrary string content (e.g., CSV) to storage.
  Future<void> writeString(String path, String content) async {
    final tmpDir = Directory.systemTemp;
    final base = p.basename(path);
    final tmp = File(p.join(tmpDir.path, 'asv_${DateTime.now().millisecondsSinceEpoch}_$base'));
    await tmp.writeAsString(content);
    try {
      await uploadFile(tmp, path, preferSignedUrl: false);
    } finally {
      try { await tmp.delete(); } catch (_) {}
    }
  }
}
