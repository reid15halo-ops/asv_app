import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';

/// Repository für Event-Operationen
class EventRepository {
  final SupabaseClient supa;

  EventRepository(this.supa);

  // ========== EVENT CRUD ==========

  /// Lädt alle Events
  Future<List<Event>> getEvents({
    EventStatus? status,
    EventType? type,
    int? limit,
    bool upcomingOnly = false,
  }) async {
    var query = supa.from('event').select('*');

    if (status != null) {
      query = query.eq('status', status.value);
    }

    if (type != null) {
      query = query.eq('event_type', type.value);
    }

    if (upcomingOnly) {
      query = query
          .eq('status', EventStatus.upcoming.value)
          .gte('event_date', DateTime.now().toIso8601String());
    }

    query = query.order('event_date', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Lädt anstehende Events mit Registrierungs-Counts
  Future<List<Event>> getUpcomingEvents({int? limit}) async {
    var query = supa.from('upcoming_events').select('*');

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Lädt ein einzelnes Event by ID
  Future<Event?> getEventById(int eventId) async {
    final response = await supa
        .from('event')
        .select('*')
        .eq('id', eventId)
        .maybeSingle();

    if (response == null) return null;

    return Event.fromJson(response as Map<String, dynamic>);
  }

  /// Lädt Events für die der User angemeldet ist
  Future<List<Event>> getUserEvents() async {
    final response = await supa.from('user_events').select('*');

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Erstellt ein neues Event
  Future<Event> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? endDate,
    String? location,
    int? maxParticipants,
    bool registrationRequired = false,
    DateTime? registrationDeadline,
    EventType eventType = EventType.other,
  }) async {
    final userId = supa.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Nicht eingeloggt');
    }

    final response = await supa
        .from('event')
        .insert({
          'title': title,
          'description': description,
          'event_date': eventDate.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'location': location,
          'max_participants': maxParticipants,
          'registration_required': registrationRequired,
          'registration_deadline': registrationDeadline?.toIso8601String(),
          'event_type': eventType.value,
          'created_by': userId,
        })
        .select()
        .single();

    return Event.fromJson(response as Map<String, dynamic>);
  }

  /// Aktualisiert ein Event
  Future<void> updateEvent(int eventId, Map<String, dynamic> updates) async {
    await supa.from('event').update(updates).eq('id', eventId);
  }

  /// Löscht ein Event
  Future<void> deleteEvent(int eventId) async {
    await supa.from('event').delete().eq('id', eventId);
  }

  /// Ändert Event-Status
  Future<void> updateEventStatus(int eventId, EventStatus status) async {
    await supa
        .from('event')
        .update({'status': status.value}).eq('id', eventId);
  }

  // ========== EVENT REGISTRATIONS ==========

  /// Registriert aktuellen User für ein Event
  Future<void> registerForEvent(int eventId, {String? notes}) async {
    try {
      await supa.rpc('register_for_event', params: {
        'p_event_id': eventId,
        'p_notes': notes,
      });
    } catch (e) {
      throw Exception('Registrierung fehlgeschlagen: $e');
    }
  }

  /// Storniert Event-Registrierung
  Future<void> cancelRegistration(int eventId) async {
    try {
      await supa.rpc('cancel_event_registration', params: {
        'p_event_id': eventId,
      });
    } catch (e) {
      throw Exception('Stornierung fehlgeschlagen: $e');
    }
  }

  /// Prüft ob User für Event registriert ist
  Future<bool> isUserRegistered(int eventId) async {
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await supa
        .from('event_registration')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .eq('status', RegistrationStatus.registered.value)
        .maybeSingle();

    return response != null;
  }

  /// Lädt User-Registrierung für ein Event
  Future<EventRegistration?> getUserRegistration(int eventId) async {
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supa
        .from('event_registration')
        .select('*')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return EventRegistration.fromJson(response as Map<String, dynamic>);
  }

  /// Lädt alle Registrierungen für ein Event (nur für Event-Ersteller)
  Future<List<EventRegistration>> getEventRegistrations(int eventId) async {
    final response = await supa
        .from('event_registration')
        .select('*')
        .eq('event_id', eventId)
        .eq('status', RegistrationStatus.registered.value)
        .order('registered_at', ascending: true);

    return (response as List)
        .map((json) => EventRegistration.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Gibt Anzahl registrierter Teilnehmer zurück
  Future<int> getRegisteredCount(int eventId) async {
    final response = await supa
        .from('event_registration')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('event_id', eventId)
        .eq('status', RegistrationStatus.registered.value);

    return response.count ?? 0;
  }

  /// Markiert Teilnehmer als "attended"
  Future<void> markAsAttended(int eventId, String userId) async {
    await supa
        .from('event_registration')
        .update({'status': RegistrationStatus.attended.value})
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  // ========== STREAMS ==========

  /// Stream für Events
  Stream<List<Event>> watchEvents({EventStatus? status}) {
    var query = supa
        .from('event')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true);

    return query.map((data) {
      return data
          .map((json) => Event.fromJson(json))
          .where((event) => status == null || event.status == status)
          .toList();
    });
  }

  /// Stream für User-Registrierungen
  Stream<List<EventRegistration>> watchUserRegistrations() {
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return supa
        .from('event_registration')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .map((json) => EventRegistration.fromJson(json))
            .toList());
  }

  // ========== STATISTICS ==========

  /// Gibt Event-Statistiken zurück
  Future<Map<String, dynamic>> getEventStats() async {
    final now = DateTime.now();

    // Anstehende Events
    final upcomingResponse = await supa
        .from('event')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('status', EventStatus.upcoming.value)
        .gte('event_date', now.toIso8601String());

    final upcomingCount = upcomingResponse.count ?? 0;

    // Events diesen Monat
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final thisMonthResponse = await supa
        .from('event')
        .select('id', const FetchOptions(count: CountOption.exact))
        .gte('event_date', startOfMonth.toIso8601String())
        .lte('event_date', endOfMonth.toIso8601String());

    final thisMonthCount = thisMonthResponse.count ?? 0;

    // User's Registrierungen
    final userId = supa.auth.currentUser?.id;
    int myRegistrations = 0;

    if (userId != null) {
      final myRegResponse = await supa
          .from('event_registration')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId)
          .eq('status', RegistrationStatus.registered.value);

      myRegistrations = myRegResponse.count ?? 0;
    }

    return {
      'upcoming_events': upcomingCount,
      'events_this_month': thisMonthCount,
      'my_registrations': myRegistrations,
    };
  }
}
