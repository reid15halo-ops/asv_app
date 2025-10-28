import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/repositories/event_repository.dart';

/// Provider für Event-Repository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(Supabase.instance.client);
});

/// Provider für kommende Events
final upcomingEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getUpcomingEvents(limit: 50);
});

/// Provider für Events nach Zielgruppe
final eventsForGroupProvider = FutureProvider.autoDispose.family<List<Event>, EventTargetGroup>(
  (ref, group) async {
    final repo = ref.watch(eventRepositoryProvider);
    return repo.getEventsForGroup(group);
  },
);

/// Provider für Events nach Typ
final eventsByTypeProvider = FutureProvider.autoDispose.family<List<Event>, EventType>(
  (ref, type) async {
    final repo = ref.watch(eventRepositoryProvider);
    return repo.getEventsByType(type);
  },
);

/// Provider für einzelnes Event
final eventByIdProvider = FutureProvider.autoDispose.family<Event?, String>(
  (ref, id) async {
    final repo = ref.watch(eventRepositoryProvider);
    return repo.getEventById(id);
  },
);

/// State Notifier für Event-Verwaltung
class EventNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final EventRepository _repository;
  EventTargetGroup? _filterGroup;
  EventType? _filterType;

  EventNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  /// Lädt Events
  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getUpcomingEvents(limit: 100);
      state = AsyncValue.data(_applyFilters(events));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt Events für eine bestimmte Zielgruppe
  Future<void> loadEventsForGroup(EventTargetGroup group) async {
    state = const AsyncValue.loading();
    try {
      final events = await _repository.getEventsForGroup(group, limit: 100);
      state = AsyncValue.data(_applyFilters(events));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Setzt Filter nach Zielgruppe
  void setGroupFilter(EventTargetGroup? group) {
    _filterGroup = group;
    _reapplyFilters();
  }

  /// Setzt Filter nach Typ
  void setTypeFilter(EventType? type) {
    _filterType = type;
    _reapplyFilters();
  }

  /// Wendet Filter an
  void _reapplyFilters() {
    state.whenData((events) {
      state = AsyncValue.data(_applyFilters(events));
    });
  }

  /// Filtert Events
  List<Event> _applyFilters(List<Event> events) {
    var filtered = events;

    if (_filterGroup != null && _filterGroup != EventTargetGroup.alle) {
      filtered = filtered.where((e) => e.isRelevantFor(_filterGroup!)).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((e) => e.type == _filterType).toList();
    }

    return filtered;
  }

  /// Aktualisiert Event-Liste
  void refresh() {
    loadEvents();
  }
}

/// Global Provider für Event-Verwaltung
final eventNotifierProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<Event>>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventNotifier(repository);
});

/// Provider für meine Events (Anmeldungen)
final myEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final repo = ref.watch(eventRepositoryProvider);
  return repo.getMyEvents(user.id);
});

/// Provider für Event-Teilnahme-Status
final eventRegistrationStatusProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, eventId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  final repo = ref.watch(eventRepositoryProvider);
  return repo.isRegisteredForEvent(eventId, user.id);
});
