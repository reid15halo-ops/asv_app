import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/repositories/event_repository.dart';

/// Provider für EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(Supabase.instance.client);
});

/// Provider für Events-Liste
class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final EventRepository _repository;

  EventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  /// Lädt alle Events
  Future<void> loadEvents({
    EventStatus? status,
    EventType? type,
    bool upcomingOnly = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getEvents(
        status: status,
        type: type,
        upcomingOnly: upcomingOnly,
      );
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt nur anstehende Events
  Future<void> loadUpcomingEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getUpcomingEvents();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh - lädt Events neu
  Future<void> refresh() async {
    await loadEvents();
  }

  /// Löscht ein Event
  Future<void> deleteEvent(int eventId) async {
    try {
      await _repository.deleteEvent(eventId);

      // Update local state
      state.whenData((events) {
        final updatedEvents = events.where((e) => e.id != eventId).toList();
        state = AsyncValue.data(updatedEvents);
      });
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }

  /// Aktualisiert Event-Status
  Future<void> updateEventStatus(int eventId, EventStatus status) async {
    try {
      await _repository.updateEventStatus(eventId, status);
      await refresh();
    } catch (e) {
      // Fehler ignorieren oder loggen
    }
  }
}

/// Global Provider für Events
final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventsNotifier(repository);
});

/// Provider für anstehende Events
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getUpcomingEvents();
});

/// Provider für User's Events (angemeldet)
final userEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getUserEvents();
});

/// Provider für ein einzelnes Event
final eventByIdProvider = FutureProvider.family<Event?, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getEventById(eventId);
});

/// Provider für Event-Statistiken
final eventStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getEventStats();
});

/// Provider für User-Registrierung bei einem Event
final userRegistrationProvider =
    FutureProvider.family<EventRegistration?, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getUserRegistration(eventId);
});

/// Provider für Event-Registrierungen (alle Teilnehmer)
final eventRegistrationsProvider =
    FutureProvider.family<List<EventRegistration>, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getEventRegistrations(eventId);
});

/// Provider für Registrierungs-Status
final isUserRegisteredProvider =
    FutureProvider.family<bool, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.isUserRegistered(eventId);
});

/// Provider für Anzahl registrierter Teilnehmer
final registeredCountProvider =
    FutureProvider.family<int, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getRegisteredCount(eventId);
});
