import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asv_app/models/event.dart';
import 'package:asv_app/repositories/event_repository.dart';

/// WordPress Event Sync Service für "The Events Calendar" Plugin
/// Handhabt bidirektionale Synchronisation zwischen App und WordPress
///
/// REST API Dokumentation: https://docs.theeventscalendar.com/reference/rest-api/
class WordPressSyncService {
  final EventRepository _eventRepository;
  final String wordpressUrl;
  final String username;
  final String applicationPassword;

  WordPressSyncService({
    required EventRepository eventRepository,
    required this.wordpressUrl,
    required this.username,
    required this.applicationPassword,
  }) : _eventRepository = eventRepository;

  /// HTTP-Headers mit Basic Auth
  Map<String, String> get _authHeaders {
    final auth = base64Encode(utf8.encode('$username:$applicationPassword'));
    return {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
    };
  }

  /// Sync: WordPress → App
  /// Holt alle Events von WordPress und erstellt/aktualisiert sie lokal
  Future<SyncResult> syncFromWordPress() async {
    int created = 0;
    int updated = 0;
    int errors = 0;
    final errorMessages = <String>[];

    try {
      // Hole alle Events von WordPress
      final wpEvents = await _fetchWordPressEvents();

      for (final wpEvent in wpEvents) {
        try {
          // Prüfe ob Event bereits existiert (anhand wordpress_id)
          final existingEvent = await _eventRepository.getEventByWordPressId(wpEvent['id']);

          if (existingEvent == null) {
            // Neu erstellen
            final eventData = _mapWordPressToAppEvent(wpEvent);
            final newEvent = await _eventRepository.createEvent(eventData);
            await _eventRepository.markAsSyncedFromWordPress(newEvent.id, wpEvent['id']);
            created++;
          } else {
            // Aktualisieren (nur wenn WordPress neuer ist)
            final wpModified = DateTime.parse(wpEvent['modified']);
            if (wpModified.isAfter(existingEvent.lastSyncedAt ?? DateTime(2000))) {
              final eventData = _mapWordPressToAppEvent(wpEvent);
              await _eventRepository.updateEvent(existingEvent.id, eventData);
              await _eventRepository.markAsSyncedFromWordPress(existingEvent.id, wpEvent['id']);
              updated++;
            }
          }

          // Log erfolgreichen Sync
          await _eventRepository.logSync(
            existingEvent?.id ?? 0,
            'from_wordpress',
            'success',
          );
        } catch (e) {
          errors++;
          errorMessages.add('WordPress Event ${wpEvent['id']}: $e');

          // Log fehlgeschlagenen Sync
          final existingEvent = await _eventRepository.getEventByWordPressId(wpEvent['id']);
          if (existingEvent != null) {
            await _eventRepository.logSync(
              existingEvent.id,
              'from_wordpress',
              'failed',
              errorMessage: e.toString(),
            );
          }
        }
      }
    } catch (e) {
      errorMessages.add('WordPress Fetch Error: $e');
      errors++;
    }

    return SyncResult(
      created: created,
      updated: updated,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  /// Sync: App → WordPress
  /// Pusht alle unsynced Events von der App zu WordPress
  Future<SyncResult> syncToWordPress() async {
    int created = 0;
    int updated = 0;
    int errors = 0;
    final errorMessages = <String>[];

    try {
      // Hole alle Events die noch nicht synced sind
      final unsyncedEvents = await _eventRepository.getUnsyncedEvents();

      for (final event in unsyncedEvents) {
        try {
          if (event.wordpressId == null) {
            // Neu in WordPress erstellen
            final wpEventId = await _createWordPressEvent(event);
            await _eventRepository.markAsSyncedFromWordPress(event.id, wpEventId);
            created++;
          } else {
            // In WordPress aktualisieren
            await _updateWordPressEvent(event);
            await _eventRepository.markAsSyncedFromWordPress(event.id, event.wordpressId!);
            updated++;
          }

          // Log erfolgreichen Sync
          await _eventRepository.logSync(
            event.id,
            'to_wordpress',
            'success',
          );
        } catch (e) {
          errors++;
          errorMessages.add('App Event ${event.id}: $e');

          // Log fehlgeschlagenen Sync
          await _eventRepository.logSync(
            event.id,
            'to_wordpress',
            'failed',
            errorMessage: e.toString(),
          );
        }
      }
    } catch (e) {
      errorMessages.add('Sync Error: $e');
      errors++;
    }

    return SyncResult(
      created: created,
      updated: updated,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  /// Bidirektionaler Sync: WordPress ↔ App
  /// Führt beide Sync-Richtungen aus
  Future<SyncResult> syncBidirectional() async {
    // Erst WordPress → App
    final fromWP = await syncFromWordPress();

    // Dann App → WordPress
    final toWP = await syncToWordPress();

    return SyncResult(
      created: fromWP.created + toWP.created,
      updated: fromWP.updated + toWP.updated,
      errors: fromWP.errors + toWP.errors,
      errorMessages: [...fromWP.errorMessages, ...toWP.errorMessages],
    );
  }

  /// Holt alle Events von The Events Calendar REST API
  Future<List<Map<String, dynamic>>> _fetchWordPressEvents() async {
    final response = await http.get(
      Uri.parse('$wordpressUrl/wp-json/tribe/events/v1/events?per_page=100&status=publish,draft'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> events = data['events'] ?? [];
      return events.cast<Map<String, dynamic>>();
    } else {
      throw Exception('The Events Calendar API Fehler: ${response.statusCode} - ${response.body}');
    }
  }

  /// Erstellt ein Event in The Events Calendar
  Future<int> _createWordPressEvent(Event event) async {
    final wpEventData = _mapAppEventToWordPress(event);

    final response = await http.post(
      Uri.parse('$wordpressUrl/wp-json/tribe/events/v1/events'),
      headers: _authHeaders,
      body: json.encode(wpEventData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'] as int;
    } else {
      throw Exception('The Events Calendar Create Fehler: ${response.statusCode} - ${response.body}');
    }
  }

  /// Aktualisiert ein Event in The Events Calendar
  Future<void> _updateWordPressEvent(Event event) async {
    if (event.wordpressId == null) {
      throw Exception('Event hat keine WordPress ID');
    }

    final wpEventData = _mapAppEventToWordPress(event);

    final response = await http.post(
      Uri.parse('$wordpressUrl/wp-json/tribe/events/v1/events/${event.wordpressId}'),
      headers: _authHeaders,
      body: json.encode(wpEventData),
    );

    if (response.statusCode != 200) {
      throw Exception('The Events Calendar Update Fehler: ${response.statusCode} - ${response.body}');
    }
  }

  /// Mappt The Events Calendar Event zu App Event Format
  Map<String, dynamic> _mapWordPressToAppEvent(Map<String, dynamic> wpEvent) {
    // The Events Calendar JSON Structure
    final venue = wpEvent['venue'] as Map<String, dynamic>?;
    final organizer = wpEvent['organizer'] as List<dynamic>?;
    final firstOrganizer = organizer?.isNotEmpty == true
        ? organizer!.first as Map<String, dynamic>?
        : null;

    // Kombiniere Venue-Informationen zu einem Location-String
    String? location;
    if (venue != null) {
      final parts = <String>[];
      if (venue['venue'] != null) parts.add(venue['venue']);
      if (venue['address'] != null) parts.add(venue['address']);
      if (venue['city'] != null) parts.add(venue['city']);
      location = parts.isNotEmpty ? parts.join(', ') : null;
    }

    return {
      'title': wpEvent['title'] ?? '',
      'description': _stripHtml(wpEvent['description'] ?? ''),
      'location': location,
      'start_date': wpEvent['start_date'],
      'end_date': wpEvent['end_date'],
      'all_day': wpEvent['all_day'] as bool? ?? false,
      'organizer': firstOrganizer?['organizer'] as String?,
      'contact_email': firstOrganizer?['email'] as String?,
      'contact_phone': firstOrganizer?['phone'] as String?,
      'max_participants': null, // The Events Calendar hat kein max_participants field
      'status': _mapWordPressStatus(wpEvent['status'] ?? 'publish'),
      'is_public': wpEvent['status'] == 'publish',
      'wordpress_url': wpEvent['url'],
      'sync_source': 'wordpress',
    };
  }

  /// Mappt App Event zu The Events Calendar Format
  Map<String, dynamic> _mapAppEventToWordPress(Event event) {
    // The Events Calendar erwartet start_date/end_date im Format: "YYYY-MM-DD HH:MM:SS"
    final startDate = _formatDateForTribeEvents(event.startDate);
    final endDate = event.endDate != null
        ? _formatDateForTribeEvents(event.endDate!)
        : startDate;

    final data = {
      'title': event.title,
      'description': event.description ?? '',
      'start_date': startDate,
      'end_date': endDate,
      'all_day': event.allDay,
      'status': _mapAppStatusToWordPress(event.status),
    };

    // Optional: Venue erstellen (wenn Location vorhanden)
    if (event.location != null && event.location!.isNotEmpty) {
      data['venue'] = {
        'venue': event.location,
      };
    }

    // Optional: Organizer erstellen (wenn Organizer-Daten vorhanden)
    if (event.organizer != null ||
        event.contactEmail != null ||
        event.contactPhone != null) {
      data['organizer'] = [
        {
          'organizer': event.organizer ?? 'ASV Großostheim',
          'email': event.contactEmail,
          'phone': event.contactPhone,
        }
      ];
    }

    return data;
  }

  /// Formatiert DateTime für The Events Calendar
  /// Format: "YYYY-MM-DD HH:MM:SS"
  String _formatDateForTribeEvents(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }


  /// Konvertiert WordPress Status zu App Status
  String _mapWordPressStatus(String wpStatus) {
    switch (wpStatus) {
      case 'publish':
        return 'published';
      case 'draft':
        return 'draft';
      case 'private':
        return 'draft';
      default:
        return 'published';
    }
  }

  /// Konvertiert App Status zu WordPress Status
  String _mapAppStatusToWordPress(EventStatus status) {
    switch (status) {
      case EventStatus.published:
        return 'publish';
      case EventStatus.draft:
        return 'draft';
      case EventStatus.cancelled:
        return 'draft'; // WordPress hat kein "cancelled" status
    }
  }

  /// Entfernt HTML Tags aus String
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

/// Sync Result
class SyncResult {
  final int created;
  final int updated;
  final int errors;
  final List<String> errorMessages;

  SyncResult({
    required this.created,
    required this.updated,
    required this.errors,
    required this.errorMessages,
  });

  bool get hasErrors => errors > 0;
  bool get isSuccess => errors == 0;

  String get summary {
    final parts = <String>[];
    if (created > 0) parts.add('$created erstellt');
    if (updated > 0) parts.add('$updated aktualisiert');
    if (errors > 0) parts.add('$errors Fehler');
    return parts.join(', ');
  }

  @override
  String toString() => summary;
}
