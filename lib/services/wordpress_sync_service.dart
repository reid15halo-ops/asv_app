import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asv_app/models/event.dart';
import 'package:asv_app/repositories/event_repository.dart';

/// WordPress Event Sync Service
/// Handhabt bidirektionale Synchronisation zwischen App und WordPress
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

  /// Holt alle Events von WordPress REST API
  Future<List<Map<String, dynamic>>> _fetchWordPressEvents() async {
    final response = await http.get(
      Uri.parse('$wordpressUrl/wp-json/wp/v2/events?per_page=100'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('WordPress API Fehler: ${response.statusCode}');
    }
  }

  /// Erstellt ein Event in WordPress
  Future<int> _createWordPressEvent(Event event) async {
    final wpEventData = _mapAppEventToWordPress(event);

    final response = await http.post(
      Uri.parse('$wordpressUrl/wp-json/wp/v2/events'),
      headers: _authHeaders,
      body: json.encode(wpEventData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'] as int;
    } else {
      throw Exception('WordPress Create Fehler: ${response.statusCode} - ${response.body}');
    }
  }

  /// Aktualisiert ein Event in WordPress
  Future<void> _updateWordPressEvent(Event event) async {
    if (event.wordpressId == null) {
      throw Exception('Event hat keine WordPress ID');
    }

    final wpEventData = _mapAppEventToWordPress(event);

    final response = await http.put(
      Uri.parse('$wordpressUrl/wp-json/wp/v2/events/${event.wordpressId}'),
      headers: _authHeaders,
      body: json.encode(wpEventData),
    );

    if (response.statusCode != 200) {
      throw Exception('WordPress Update Fehler: ${response.statusCode} - ${response.body}');
    }
  }

  /// Mappt WordPress Event zu App Event Format
  Map<String, dynamic> _mapWordPressToAppEvent(Map<String, dynamic> wpEvent) {
    // WordPress Custom Post Type "events" mit ACF Fields
    final acf = wpEvent['acf'] as Map<String, dynamic>? ?? {};

    return {
      'title': wpEvent['title']['rendered'] ?? '',
      'description': _stripHtml(wpEvent['content']['rendered'] ?? ''),
      'location': acf['location'] as String?,
      'start_date': _parseWordPressDate(acf['start_date']),
      'end_date': acf['end_date'] != null ? _parseWordPressDate(acf['end_date']) : null,
      'all_day': acf['all_day'] as bool? ?? false,
      'organizer': acf['organizer'] as String?,
      'contact_email': acf['contact_email'] as String?,
      'contact_phone': acf['contact_phone'] as String?,
      'max_participants': acf['max_participants'] as int?,
      'status': _mapWordPressStatus(wpEvent['status']),
      'is_public': wpEvent['status'] == 'publish',
      'wordpress_url': wpEvent['link'],
      'sync_source': 'wordpress',
    };
  }

  /// Mappt App Event zu WordPress Format
  Map<String, dynamic> _mapAppEventToWordPress(Event event) {
    return {
      'title': event.title,
      'content': event.description ?? '',
      'status': _mapAppStatusToWordPress(event.status),
      'acf': {
        'location': event.location,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'all_day': event.allDay,
        'organizer': event.organizer,
        'contact_email': event.contactEmail,
        'contact_phone': event.contactPhone,
        'max_participants': event.maxParticipants,
      },
    };
  }

  /// Konvertiert WordPress Datum zu DateTime
  String _parseWordPressDate(dynamic date) {
    if (date == null) return DateTime.now().toIso8601String();

    // WordPress ACF Date Format: YYYYMMDD oder DateTime String
    if (date is String) {
      if (date.length == 8) {
        // Format: YYYYMMDD
        final year = int.parse(date.substring(0, 4));
        final month = int.parse(date.substring(4, 6));
        final day = int.parse(date.substring(6, 8));
        return DateTime(year, month, day).toIso8601String();
      } else {
        // Bereits DateTime String
        return DateTime.parse(date).toIso8601String();
      }
    }

    return DateTime.now().toIso8601String();
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
