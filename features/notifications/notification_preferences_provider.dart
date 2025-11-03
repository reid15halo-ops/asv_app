import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_preferences.dart';
import 'notification_preferences_repository.dart';

final notificationPreferencesRepositoryProvider = Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepository(Supabase.instance.client);
});

final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, AsyncValue<NotificationPreferences>>((ref) {
  final repository = ref.watch(notificationPreferencesRepositoryProvider);
  return NotificationPreferencesNotifier(repository);
});

class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationPreferencesRepository _repository;

  NotificationPreferencesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();
    try {
      final preferences = await _repository.getPreferences();
      if (preferences != null) {
        state = AsyncValue.data(preferences);
      } else {
        // Erstelle default preferences
        final defaultPrefs = await _repository.createDefaultPreferences();
        state = AsyncValue.data(defaultPrefs);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePreference(String field, dynamic value) async {
    try {
      await _repository.updatePreference(field, value);
      await loadPreferences();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await _repository.updatePreferences(preferences);
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetToDefaults() async {
    try {
      await _repository.resetToDefaults();
      await loadPreferences();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleEventNew() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableEventNew: !current.enableEventNew));
  }

  Future<void> toggleEventReminder() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableEventReminder: !current.enableEventReminder));
  }

  Future<void> toggleEventCancelled() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableEventCancelled: !current.enableEventCancelled));
  }

  Future<void> toggleEventUpdated() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableEventUpdated: !current.enableEventUpdated));
  }

  Future<void> toggleAnnouncement() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableAnnouncement: !current.enableAnnouncement));
  }

  Future<void> toggleAchievement() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableAchievement: !current.enableAchievement));
  }

  Future<void> toggleLevelUp() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableLevelUp: !current.enableLevelUp));
  }

  Future<void> toggleSystem() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableSystem: !current.enableSystem));
  }

  Future<void> togglePushNotifications() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enablePushNotifications: !current.enablePushNotifications));
  }

  Future<void> toggleQuietHours() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(enableQuietHours: !current.enableQuietHours));
  }

  Future<void> setQuietHours(TimeOfDay? start, TimeOfDay? end) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updatePreferences(current.copyWith(
      quietHoursStart: start,
      quietHoursEnd: end,
    ));
  }
}
