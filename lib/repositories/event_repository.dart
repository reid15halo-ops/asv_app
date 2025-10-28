import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/services/event_csv_service.dart';

class EventRepository {
  final SupabaseClient supa;
  EventRepository(this.supa);

  /// Gibt alle kommenden Events zurück
  Future<List<Event>> getUpcomingEvents({int limit = 50}) async {
    try {
      final response = await supa
          .from('events')
          .select('*')
          .gte('start_date', DateTime.now().toIso8601String())
          .order('start_date', ascending: true)
          .limit(limit);

      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gibt Events für eine bestimmte Zielgruppe zurück
  Future<List<Event>> getEventsForGroup(
    EventTargetGroup group, {
    int limit = 50,
    bool upcomingOnly = true,
  }) async {
    try {
      var query = supa.from('events').select('*');

      // Filter nach Datum
      if (upcomingOnly) {
        query = query.gte('start_date', DateTime.now().toIso8601String());
      }

      // Filter nach Zielgruppe (alle oder spezifische Gruppe)
      query = query.or('target_groups.cs.{alle},target_groups.cs.{${group.value}}');

      query = query.order('start_date', ascending: true).limit(limit);

      final response = await query;
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gibt Events nach Typ zurück
  Future<List<Event>> getEventsByType(
    EventType type, {
    int limit = 50,
    bool upcomingOnly = true,
  }) async {
    try {
      var query = supa.from('events').select('*').eq('type', type.value);

      if (upcomingOnly) {
        query = query.gte('start_date', DateTime.now().toIso8601String());
      }

      query = query.order('start_date', ascending: true).limit(limit);

      final response = await query;
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gibt Events in einem Datumsbereich zurück
  Future<List<Event>> getEventsByDateRange(
    DateTime start,
    DateTime end, {
    EventTargetGroup? filterGroup,
    EventType? filterType,
  }) async {
    try {
      var query = supa
          .from('events')
          .select('*')
          .gte('start_date', start.toIso8601String())
          .lte('start_date', end.toIso8601String());

      // Optionale Filter
      if (filterGroup != null && filterGroup != EventTargetGroup.alle) {
        query = query.or('target_groups.cs.{alle},target_groups.cs.{${filterGroup.value}}');
      }

      if (filterType != null) {
        query = query.eq('type', filterType.value);
      }

      query = query.order('start_date', ascending: true);

      final response = await query;
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gibt ein einzelnes Event zurück
  Future<Event?> getEventById(String id) async {
    try {
      final response = await supa
          .from('events')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Event.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Erstellt ein neues Event (nur für Admins)
  Future<Event?> createEvent(Event event) async {
    try {
      final response = await supa
          .from('events')
          .insert(event.toJson())
          .select()
          .single();

      return Event.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Aktualisiert ein Event
  Future<Event?> updateEvent(Event event) async {
    try {
      final response = await supa
          .from('events')
          .update(event.toJson())
          .eq('id', event.id)
          .select()
          .single();

      return Event.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Löscht ein Event
  Future<bool> deleteEvent(String id) async {
    try {
      await supa.from('events').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gibt die Anzahl der Events in einem Monat zurück
  Future<Map<DateTime, int>> getEventsCountByMonth(
    int year,
    int month, {
    EventTargetGroup? filterGroup,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      var query = supa
          .from('events')
          .select('start_date')
          .gte('start_date', startDate.toIso8601String())
          .lte('start_date', endDate.toIso8601String());

      if (filterGroup != null && filterGroup != EventTargetGroup.alle) {
        query = query.or('target_groups.cs.{alle},target_groups.cs.{${filterGroup.value}}');
      }

      final response = await query;
      final events = (response as List);

      // Zähle Events pro Tag
      final Map<DateTime, int> counts = {};
      for (final event in events) {
        final date = DateTime.parse(event['start_date'] as String);
        final day = DateTime(date.year, date.month, date.day);
        counts[day] = (counts[day] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Prüft ob User sich für Event anmelden kann
  Future<bool> canRegisterForEvent(String eventId, String userId) async {
    try {
      // Prüfe ob Event existiert und nicht voll ist
      final event = await getEventById(eventId);
      if (event == null) return false;
      if (event.isFullyBooked) return false;
      if (event.isPast) return false;

      // Prüfe ob User bereits angemeldet ist
      final existing = await supa
          .from('event_participants')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return existing == null;
    } catch (e) {
      return false;
    }
  }

  /// Meldet User für Event an
  Future<bool> registerForEvent(String eventId, String userId, int? memberId) async {
    try {
      await supa.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
        'member_id': memberId,
        'status': 'registered',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Meldet User von Event ab
  Future<bool> unregisterFromEvent(String eventId, String userId) async {
    try {
      await supa
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gibt Events zurück, für die der User angemeldet ist
  Future<List<Event>> getMyEvents(String userId) async {
    try {
      final response = await supa
          .from('event_participants')
          .select('event_id')
          .eq('user_id', userId)
          .in_('status', ['registered', 'confirmed']);

      final eventIds = (response as List).map((e) => e['event_id']).toList();

      if (eventIds.isEmpty) return [];

      final eventsResponse = await supa
          .from('events')
          .select('*')
          .in_('id', eventIds)
          .order('start_date', ascending: true);

      return (eventsResponse as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Prüft ob User für Event angemeldet ist
  Future<bool> isRegisteredForEvent(String eventId, String userId) async {
    try {
      final response = await supa
          .from('event_participants')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .in_('status', ['registered', 'confirmed'])
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ===== CSV Import/Export Funktionen (nur für Admins) =====

  /// Exportiert alle Events als CSV
  Future<String> exportAllEventsToCsv() async {
    try {
      final response = await supa
          .from('events')
          .select('*')
          .order('start_date', ascending: true);

      final events = (response as List).map((e) => Event.fromJson(e)).toList();
      return EventCsvService.exportEventsToCsv(events);
    } catch (e) {
      rethrow;
    }
  }

  /// Exportiert kommende Events als CSV
  Future<void> exportUpcomingEventsAndShare() async {
    try {
      final events = await getUpcomingEvents(limit: 1000);
      await EventCsvService.exportAndShareCsv(events, filename: 'kommende_events');
    } catch (e) {
      rethrow;
    }
  }

  /// Exportiert alle Events und teilt sie
  Future<void> exportAllEventsAndShare() async {
    try {
      final response = await supa
          .from('events')
          .select('*')
          .order('start_date', ascending: true);

      final events = (response as List).map((e) => Event.fromJson(e)).toList();
      await EventCsvService.exportAndShareCsv(events, filename: 'alle_events');
    } catch (e) {
      rethrow;
    }
  }

  /// Importiert Events aus CSV (nur für Admins)
  /// Returns: Map mit 'success', 'imported', 'errors'
  Future<Map<String, dynamic>> importEventsFromCsv(
    String csvContent, {
    bool replaceExisting = false,
  }) async {
    try {
      // Parse CSV
      final validation = await EventCsvService.validateCsv(csvContent);

      if (!validation['valid']) {
        return {
          'success': false,
          'imported': 0,
          'errors': validation['errors'],
        };
      }

      final List<Event> events = validation['events'];
      int imported = 0;
      final List<String> errors = [];

      for (final event in events) {
        try {
          if (replaceExisting && event.id.isNotEmpty) {
            // Prüfe ob Event existiert
            final existing = await getEventById(event.id);

            if (existing != null) {
              // Update existierendes Event
              await updateEvent(event);
            } else {
              // Erstelle neues Event
              await createEvent(event);
            }
          } else {
            // Erstelle immer neues Event
            await createEvent(event);
          }

          imported++;
        } catch (e) {
          errors.add('Event "${event.title}": ${e.toString()}');
        }
      }

      return {
        'success': true,
        'imported': imported,
        'total': events.length,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'imported': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Teilt CSV-Template
  Future<void> shareCsvTemplate() async {
    await EventCsvService.shareTemplate();
  }
}
