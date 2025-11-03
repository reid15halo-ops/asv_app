import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/services/wordpress_sync_service.dart';
import 'package:asv_app/repositories/event_repository.dart';

// HINWEIS: Diese Import wird einen Fehler werfen, bis du wordpress_config.dart erstellst
// Folge der Anleitung in docs/WORDPRESS_SYNC_SETUP.md
// import 'package:asv_app/config/wordpress_config.dart';

/// WordPress Sync Service Provider
///
/// Usage:
/// ```dart
/// final syncService = ref.read(wordPressSyncServiceProvider);
/// final result = await syncService.syncBidirectional();
/// ```
final wordPressSyncServiceProvider = Provider<WordPressSyncService>((ref) {
  final repository = EventRepository(Supabase.instance.client);

  // TODO: Uncomment nach WordPress-Konfiguration
  // return WordPressSyncService(
  //   eventRepository: repository,
  //   wordpressUrl: WordPressConfig.wordpressUrl,
  //   username: WordPressConfig.username,
  //   applicationPassword: WordPressConfig.applicationPassword,
  // );

  // PLACEHOLDER: Bis WordPress konfiguriert ist
  return WordPressSyncService(
    eventRepository: repository,
    wordpressUrl: 'https://example.com', // TODO: WordPress URL
    username: 'admin', // TODO: WordPress Username
    applicationPassword: 'xxxx xxxx xxxx xxxx', // TODO: Application Password
  );
});

/// Sync Status Provider
/// Zeigt den aktuellen Status der Synchronisation
final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Last Sync Result Provider
/// Speichert das Ergebnis des letzten Syncs
final lastSyncResultProvider = StateProvider<SyncResult?>((ref) => null);

/// Sync Actions
/// Helper-Klasse für Sync-Operationen mit State Management
class SyncActions {
  final Ref _ref;

  SyncActions(this._ref);

  /// Bidirektionale Synchronisation
  Future<SyncResult> syncBidirectional() async {
    final service = _ref.read(wordPressSyncServiceProvider);
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    try {
      final result = await service.syncBidirectional();
      _ref.read(lastSyncResultProvider.notifier).state = result;
      _ref.read(syncStatusProvider.notifier).state =
          result.isSuccess ? SyncStatus.success : SyncStatus.error;
      return result;
    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    }
  }

  /// Nur WordPress → App
  Future<SyncResult> syncFromWordPress() async {
    final service = _ref.read(wordPressSyncServiceProvider);
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    try {
      final result = await service.syncFromWordPress();
      _ref.read(lastSyncResultProvider.notifier).state = result;
      _ref.read(syncStatusProvider.notifier).state =
          result.isSuccess ? SyncStatus.success : SyncStatus.error;
      return result;
    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    }
  }

  /// Nur App → WordPress
  Future<SyncResult> syncToWordPress() async {
    final service = _ref.read(wordPressSyncServiceProvider);
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    try {
      final result = await service.syncToWordPress();
      _ref.read(lastSyncResultProvider.notifier).state = result;
      _ref.read(syncStatusProvider.notifier).state =
          result.isSuccess ? SyncStatus.success : SyncStatus.error;
      return result;
    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    }
  }

  /// Sync Status zurücksetzen
  void resetStatus() {
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
  }
}

/// Provider für Sync Actions
final syncActionsProvider = Provider<SyncActions>((ref) => SyncActions(ref));
