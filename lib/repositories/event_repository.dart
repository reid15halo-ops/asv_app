import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';

class EventRepository {
  final SupabaseClient _client;

  EventRepository(this._client);

  /// Lädt alle öffentlichen Events
  Future<List<Event>> getAllEvents({bool upcomingOnly = false}) async {
    var query = _client
        .from('events')
        .select('*, participant_count:event_participants(count)')
        .eq('is_public', true)
        .eq('status', 'published')
        .order('start_date', ascending: true);

    if (upcomingOnly) {
      query = query.gte('start_date', DateTime.now().toIso8601String());
    }

    final data = await query;
    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Lädt upcoming Events (View)
  Future<List<Event>> getUpcomingEvents() async {
    final data = await _client
        .from('upcoming_events')
        .select()
        .limit(50);

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Lädt vergangene Events (View)
  Future<List<Event>> getPastEvents({int limit = 20}) async {
    final data = await _client
        .from('past_events')
        .select()
        .limit(limit);

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Lädt ein einzelnes Event
  Future<Event?> getEvent(int id) async {
    final data = await _client
        .from('events')
        .select('*, participant_count:event_participants(count)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Event.fromJson(data);
  }

  /// Erstellt ein neues Event
  Future<Event> createEvent(Event event) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = await _client
        .from('events')
        .insert({
          ...event.toJson(),
          'created_by': userId,
        })
        .select()
        .single();

    return Event.fromJson(data);
  }

  /// Aktualisiert ein Event
  Future<Event> updateEvent(int id, Event event) async {
    final data = await _client
        .from('events')
        .update(event.toJson())
        .eq('id', id)
        .select()
        .single();

    return Event.fromJson(data);
  }

  /// Löscht ein Event
  Future<void> deleteEvent(int id) async {
    await _client.from('events').delete().eq('id', id);
  }

  /// Sucht Events
  Future<List<Event>> searchEvents(String query) async {
    final data = await _client
        .from('events')
        .select()
        .textSearch('title,description,location', query, config: 'german')
        .eq('is_public', true)
        .eq('status', 'published')
        .limit(50);

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  // === Event Participants ===

  /// Lädt Teilnehmer eines Events
  Future<List<EventParticipant>> getEventParticipants(int eventId) async {
    final data = await _client
        .from('event_participants')
        .select()
        .eq('event_id', eventId)
        .order('registered_at');

    return (data as List).map((json) => EventParticipant.fromJson(json)).toList();
  }

  /// User meldet sich für Event an
  Future<EventParticipant> registerForEvent(int eventId, {String? notes}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = await _client
        .from('event_participants')
        .insert({
          'event_id': eventId,
          'user_id': userId,
          'status': 'registered',
          'notes': notes,
        })
        .select()
        .single();

    return EventParticipant.fromJson(data);
  }

  /// User meldet sich von Event ab
  Future<void> unregisterFromEvent(int eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('event_participants')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  /// Prüft ob User für Event angemeldet ist
  Future<bool> isUserRegistered(int eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final data = await _client
        .from('event_participants')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    return data != null;
  }

  /// Aktualisiert Teilnehmer-Status (z.B. auf "attended")
  Future<void> updateParticipantStatus(
    int eventId,
    String userId,
    ParticipantStatus status,
  ) async {
    await _client
        .from('event_participants')
        .update({'status': status.value})
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  // === WordPress Sync ===

  /// Markiert Event als von WordPress synchronisiert
  Future<void> markAsSyncedFromWordPress(int eventId, int wordpressId) async {
    await _client
        .from('events')
        .update({
          'wordpress_id': wordpressId,
          'last_synced_at': DateTime.now().toIso8601String(),
          'sync_source': 'wordpress',
        })
        .eq('id', eventId);
  }

  /// Lädt Events die noch nicht zu WordPress synchronisiert wurden
  Future<List<Event>> getUnsyncedEvents() async {
    final data = await _client
        .from('events')
        .select()
        .is_('wordpress_id', null)
        .eq('sync_source', 'app')
        .eq('status', 'published');

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Lädt Event anhand WordPress-ID
  Future<Event?> getEventByWordPressId(int wordpressId) async {
    final data = await _client
        .from('events')
        .select()
        .eq('wordpress_id', wordpressId)
        .maybeSingle();

    if (data == null) return null;
    return Event.fromJson(data);
  }

  /// Loggt Synchronisation
  Future<void> logSync({
    required int eventId,
    required String direction,
    required String status,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('wordpress_sync_log').insert({
      'event_id': eventId,
      'sync_direction': direction,
      'status': status,
      'error_message': errorMessage,
      'metadata': metadata,
    });
  }
}
