import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_preferences.dart';

class NotificationPreferencesRepository {
  final SupabaseClient _client;

  NotificationPreferencesRepository(this._client);

  /// Lädt die Notification Preferences für den aktuellen User
  Future<NotificationPreferences?> getPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      // Erstelle default preferences wenn keine existieren
      return await createDefaultPreferences();
    }

    return NotificationPreferences.fromJson(data);
  }

  /// Erstellt default Preferences für den aktuellen User
  Future<NotificationPreferences> createDefaultPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final data = await _client
        .from('notification_preferences')
        .insert({'user_id': userId})
        .select()
        .single();

    return NotificationPreferences.fromJson(data);
  }

  /// Updated die Preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('notification_preferences')
        .update(preferences.toJson())
        .eq('user_id', userId);
  }

  /// Updated einen einzelnen Preference-Wert
  Future<void> updatePreference(String field, dynamic value) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('notification_preferences')
        .update({field: value})
        .eq('user_id', userId);
  }

  /// Setzt alle Preferences auf Default zurück
  Future<void> resetToDefaults() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('notification_preferences')
        .update({
          'enable_event_new': true,
          'enable_event_reminder': true,
          'enable_event_cancelled': true,
          'enable_event_updated': true,
          'enable_announcement': true,
          'enable_achievement': true,
          'enable_level_up': true,
          'enable_system': true,
          'enable_push_notifications': false,
          'enable_quiet_hours': false,
          'quiet_hours_start': null,
          'quiet_hours_end': null,
        })
        .eq('user_id', userId);
  }
}
