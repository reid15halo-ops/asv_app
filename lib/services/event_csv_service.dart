import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:asv_app/models/event.dart';

/// Service für CSV-Import/Export von Events
class EventCsvService {
  /// CSV-Header für Event-Export
  static const List<String> csvHeaders = [
    'ID',
    'Titel',
    'Beschreibung',
    'Start-Datum',
    'End-Datum',
    'Ganztägig',
    'Ort',
    'Event-Typ',
    'Zielgruppen',
    'Max. Teilnehmer',
    'Aktuelle Teilnehmer',
    'Organisator ID',
    'Organisator Name',
    'Bild URL',
  ];

  /// Exportiert Events als CSV
  static Future<String> exportEventsToCsv(List<Event> events) async {
    final List<List<dynamic>> rows = [];

    // Header-Zeile
    rows.add(csvHeaders);

    // Event-Daten
    for (final event in events) {
      rows.add([
        event.id,
        event.title,
        event.description,
        event.startDate.toIso8601String(),
        event.endDate?.toIso8601String() ?? '',
        event.isAllDay ? 'Ja' : 'Nein',
        event.location ?? '',
        event.type.value,
        event.targetGroups.map((g) => g.value).join(';'),
        event.maxParticipants?.toString() ?? '',
        event.currentParticipants.toString(),
        event.organizerId ?? '',
        event.organizerName ?? '',
        event.imageUrl ?? '',
      ]);
    }

    // Konvertiere zu CSV-String
    final csvString = const ListToCsvConverter().convert(rows);
    return csvString;
  }

  /// Speichert CSV und teilt sie
  static Future<void> exportAndShareCsv(
    List<Event> events, {
    String filename = 'events_export',
  }) async {
    try {
      // Generiere CSV
      final csvString = await exportEventsToCsv(events);

      // Speichere temporär
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filepath = '${directory.path}/${filename}_$timestamp.csv';

      final file = File(filepath);
      await file.writeAsString(csvString, encoding: utf8);

      // Teile die Datei
      await Share.shareXFiles(
        [XFile(filepath)],
        subject: 'ASV Events Export',
        text: 'Events vom ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Importiert Events aus CSV-String
  static Future<List<Event>> importEventsFromCsv(String csvContent) async {
    try {
      // Parse CSV
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        throw Exception('CSV-Datei ist leer');
      }

      // Überspringe Header-Zeile
      final dataRows = rows.skip(1);

      final List<Event> events = [];
      int rowNumber = 2; // Start bei 2 (1 ist Header)

      for (final row in dataRows) {
        try {
          if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
            continue; // Überspringe leere Zeilen
          }

          // Validiere Anzahl der Spalten
          if (row.length < csvHeaders.length) {
            throw Exception('Zeile $rowNumber: Zu wenig Spalten');
          }

          // Parse Event-Daten
          final id = row[0]?.toString() ?? '';
          final title = row[1]?.toString() ?? '';
          final description = row[2]?.toString() ?? '';
          final startDateStr = row[3]?.toString() ?? '';
          final endDateStr = row[4]?.toString() ?? '';
          final isAllDayStr = row[5]?.toString() ?? '';
          final location = row[6]?.toString();
          final typeStr = row[7]?.toString() ?? '';
          final targetGroupsStr = row[8]?.toString() ?? '';
          final maxParticipantsStr = row[9]?.toString();
          final currentParticipantsStr = row[10]?.toString() ?? '0';
          final organizerId = row[11]?.toString();
          final organizerName = row[12]?.toString();
          final imageUrl = row[13]?.toString();

          // Validierung
          if (title.trim().isEmpty) {
            throw Exception('Zeile $rowNumber: Titel fehlt');
          }

          if (startDateStr.trim().isEmpty) {
            throw Exception('Zeile $rowNumber: Start-Datum fehlt');
          }

          // Parse Datum
          DateTime startDate;
          try {
            startDate = DateTime.parse(startDateStr);
          } catch (e) {
            throw Exception('Zeile $rowNumber: Ungültiges Start-Datum: $startDateStr');
          }

          DateTime? endDate;
          if (endDateStr.isNotEmpty) {
            try {
              endDate = DateTime.parse(endDateStr);
            } catch (e) {
              throw Exception('Zeile $rowNumber: Ungültiges End-Datum: $endDateStr');
            }
          }

          // Parse Event-Typ
          EventType type;
          try {
            type = EventType.fromString(typeStr);
          } catch (e) {
            throw Exception('Zeile $rowNumber: Ungültiger Event-Typ: $typeStr');
          }

          // Parse Zielgruppen (Mehrfachauswahl mit Semikolon getrennt)
          List<EventTargetGroup> targetGroups = [];
          if (targetGroupsStr.isNotEmpty) {
            final groupStrings = targetGroupsStr.split(';');
            for (final groupStr in groupStrings) {
              try {
                targetGroups.add(EventTargetGroup.fromString(groupStr.trim()));
              } catch (e) {
                throw Exception('Zeile $rowNumber: Ungültige Zielgruppe: $groupStr');
              }
            }
          }

          if (targetGroups.isEmpty) {
            targetGroups = [EventTargetGroup.alle];
          }

          // Parse isAllDay
          final isAllDay = isAllDayStr.toLowerCase() == 'ja' ||
              isAllDayStr.toLowerCase() == 'true' ||
              isAllDayStr == '1';

          // Parse Teilnehmer
          int? maxParticipants;
          if (maxParticipantsStr != null && maxParticipantsStr.isNotEmpty) {
            try {
              maxParticipants = int.parse(maxParticipantsStr);
            } catch (e) {
              throw Exception('Zeile $rowNumber: Ungültige Max. Teilnehmer: $maxParticipantsStr');
            }
          }

          int currentParticipants = 0;
          try {
            currentParticipants = int.parse(currentParticipantsStr);
          } catch (e) {
            // Default 0
          }

          // Erstelle Event
          final event = Event(
            id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location?.isEmpty ?? true ? null : location,
            type: type,
            targetGroups: targetGroups,
            isAllDay: isAllDay,
            maxParticipants: maxParticipants,
            currentParticipants: currentParticipants,
            imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl,
            organizerId: organizerId?.isEmpty ?? true ? null : organizerId,
            organizerName: organizerName?.isEmpty ?? true ? null : organizerName,
            createdAt: DateTime.now(),
          );

          events.add(event);
        } catch (e) {
          throw Exception('Zeile $rowNumber: ${e.toString()}');
        }

        rowNumber++;
      }

      return events;
    } catch (e) {
      rethrow;
    }
  }

  /// Generiert CSV-Template zum Download
  static String generateCsvTemplate() {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add(csvHeaders);

    // Beispiel-Zeile
    rows.add([
      '', // ID (leer für neues Event)
      'Beispiel Event',
      'Dies ist eine Beschreibung',
      DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      '', // End-Datum optional
      'Nein', // Ganztägig
      'Vereinsheim',
      'feier', // Event-Typ (arbeitseinsatz, feier, sitzung, training, wettkampf, ausflug, kurs, sonstiges)
      'alle', // Zielgruppen (jugend;aktive;senioren;alle) - mit ; trennen für Mehrfachauswahl
      '50', // Max. Teilnehmer
      '0', // Aktuelle Teilnehmer
      '', // Organisator ID (optional)
      'Max Mustermann', // Organisator Name
      '', // Bild URL (optional)
    ]);

    return const ListToCsvConverter().convert(rows);
  }

  /// Speichert und teilt CSV-Template
  static Future<void> shareTemplate() async {
    try {
      final csvString = generateCsvTemplate();

      final directory = await getTemporaryDirectory();
      final filepath = '${directory.path}/events_template.csv';

      final file = File(filepath);
      await file.writeAsString(csvString, encoding: utf8);

      await Share.shareXFiles(
        [XFile(filepath)],
        subject: 'ASV Events Template',
        text: 'CSV-Vorlage für Event-Import',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Validiert CSV-Datei vor dem Import
  static Future<Map<String, dynamic>> validateCsv(String csvContent) async {
    try {
      final events = await importEventsFromCsv(csvContent);

      return {
        'valid': true,
        'eventCount': events.length,
        'events': events,
        'errors': [],
      };
    } catch (e) {
      return {
        'valid': false,
        'eventCount': 0,
        'events': [],
        'errors': [e.toString()],
      };
    }
  }
}
