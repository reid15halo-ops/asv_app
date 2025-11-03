import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/repositories/event_repository.dart';

// Repository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(Supabase.instance.client);
});

// Events Provider (alle Events)
final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventsNotifier(repository);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final EventRepository _repository;

  EventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getAllEvents();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() => loadEvents();
}

// Upcoming Events Provider
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getUpcomingEvents();
});

// Past Events Provider
final pastEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getPastEvents();
});

// Single Event Provider
final eventProvider = FutureProvider.family<Event?, int>((ref, id) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEvent(id);
});

// Event Participants Provider
final eventParticipantsProvider = FutureProvider.family<List<EventParticipant>, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventParticipants(eventId);
});

// User Registration Status Provider
final isUserRegisteredProvider = FutureProvider.family<bool, int>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.isUserRegistered(eventId);
});

// Event Actions Provider
final eventActionsProvider = Provider<EventActions>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventActions(repository, ref);
});

class EventActions {
  final EventRepository _repository;
  final Ref _ref;

  EventActions(this._repository, this._ref);

  Future<Event> createEvent(Event event) async {
    final newEvent = await _repository.createEvent(event);
    // Refresh events list
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
    return newEvent;
  }

  Future<Event> updateEvent(int id, Event event) async {
    final updated = await _repository.updateEvent(id, event);
    // Refresh events
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
    _ref.invalidate(eventProvider(id));
    return updated;
  }

  Future<void> deleteEvent(int id) async {
    await _repository.deleteEvent(id);
    // Refresh events
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
  }

  Future<EventParticipant> registerForEvent(int eventId, {String? notes}) async {
    final participant = await _repository.registerForEvent(eventId, notes: notes);
    // Refresh
    _ref.invalidate(eventParticipantsProvider(eventId));
    _ref.invalidate(isUserRegisteredProvider(eventId));
    _ref.invalidate(eventProvider(eventId));
    return participant;
  }

  Future<void> unregisterFromEvent(int eventId) async {
    await _repository.unregisterFromEvent(eventId);
    // Refresh
    _ref.invalidate(eventParticipantsProvider(eventId));
    _ref.invalidate(isUserRegisteredProvider(eventId));
    _ref.invalidate(eventProvider(eventId));
  }

  Future<List<Event>> searchEvents(String query) async {
    return _repository.searchEvents(query);
  }
}
