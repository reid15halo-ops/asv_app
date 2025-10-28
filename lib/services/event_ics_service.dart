import '../models/event.dart';
import 'package:intl/intl.dart';

/// Service für ICS (iCalendar) Export von Events
/// ICS ist das universelle Format für Kalender-Kompatibilität
/// (Google Calendar, Outlook, Apple Calendar, etc.)
class EventIcsService {
  /// Exportiert eine Liste von Events als ICS-String
  static String exportEventsToIcs(List<Event> events) {
    final buffer = StringBuffer();

    // ICS Header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//ASV Grossostheim//Events Calendar//DE');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:ASV Grossostheim Events');
    buffer.writeln('X-WR-CALDESC:Veranstaltungen und Termine des ASV Grossostheim');
    buffer.writeln('X-WR-TIMEZONE:Europe/Berlin');

    // Jedes Event als VEVENT
    for (final event in events) {
      buffer.write(_createVEvent(event));
    }

    // ICS Footer
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Erstellt einen einzelnen VEVENT-Block
  static String _createVEvent(Event event) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VEVENT');

    // UID: Eindeutige ID (wichtig für Updates)
    final uid = event.id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}';
    buffer.writeln('UID:$uid@asv-grossostheim.de');

    // DTSTAMP: Zeitstempel der Erstellung
    final now = DateTime.now().toUtc();
    buffer.writeln('DTSTAMP:${_formatIcsDateTime(now)}');

    // DTSTART und DTEND
    if (event.isAllDay) {
      // Ganztägige Events: VALUE=DATE Format
      buffer.writeln('DTSTART;VALUE=DATE:${_formatIcsDate(event.startDate)}');
      // End-Datum ist exklusiv im ICS-Format, daher +1 Tag
      final endDate = event.endDate ?? event.startDate;
      buffer.writeln('DTEND;VALUE=DATE:${_formatIcsDate(endDate.add(const Duration(days: 1)))}');
    } else {
      // Events mit Uhrzeit
      buffer.writeln('DTSTART:${_formatIcsDateTime(event.startDate)}');
      final endDate = event.endDate ?? event.startDate.add(const Duration(hours: 1));
      buffer.writeln('DTEND:${_formatIcsDateTime(endDate)}');
    }

    // SUMMARY: Titel
    buffer.writeln('SUMMARY:${_escapeIcsText(event.title)}');

    // DESCRIPTION: Beschreibung + zusätzliche Infos
    final description = _buildDescription(event);
    buffer.writeln('DESCRIPTION:${_escapeAndFoldIcsText(description)}');

    // LOCATION: Ort
    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeIcsText(event.location!)}');
    }

    // ORGANIZER: Organisator
    if (event.organizerName != null && event.organizerName!.isNotEmpty) {
      buffer.writeln('ORGANIZER;CN=${_escapeIcsText(event.organizerName!)}:mailto:info@asv-grossostheim.de');
    }

    // STATUS
    buffer.writeln('STATUS:CONFIRMED');

    // CATEGORIES: Event-Typ als Kategorie
    final category = _getEventTypeCategory(event.type);
    buffer.writeln('CATEGORIES:$category');

    // URL: Link zur Event-Details (optional)
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      buffer.writeln('URL:${event.imageUrl}');
    }

    buffer.writeln('END:VEVENT');

    return buffer.toString();
  }

  /// Erstellt die Beschreibung mit zusätzlichen Event-Informationen
  static String _buildDescription(Event event) {
    final buffer = StringBuffer();

    // Haupt-Beschreibung
    if (event.description != null && event.description!.isNotEmpty) {
      buffer.write(event.description);
      buffer.write('\\n\\n');
    }

    // Event-Typ
    buffer.write('Event-Typ: ${_getEventTypeLabel(event.type)}\\n');

    // Zielgruppen
    if (event.targetGroups.isNotEmpty) {
      final groups = event.targetGroups.map((g) => _getTargetGroupLabel(g)).join(', ');
      buffer.write('Zielgruppen: $groups\\n');
    }

    // Teilnehmer-Info
    if (event.maxParticipants != null) {
      buffer.write('Teilnehmer: ${event.currentParticipants ?? 0}/${event.maxParticipants}\\n');
    }

    // Organisator
    if (event.organizerName != null && event.organizerName!.isNotEmpty) {
      buffer.write('Organisator: ${event.organizerName}\\n');
    }

    // Footer
    buffer.write('\\n---\\nASV Grossostheim e.V.');

    return buffer.toString();
  }

  /// Formatiert DateTime als ICS DateTime (UTC): YYYYMMDDTHHMMSSZ
  static String _formatIcsDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateFormat('yyyyMMddTHHmmss').format(utc) + 'Z';
  }

  /// Formatiert Date als ICS Date: YYYYMMDD
  static String _formatIcsDate(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  /// Escaped Sonderzeichen für ICS-Text
  static String _escapeIcsText(String text) {
    return text
        .replaceAll('\\', '\\\\')  // Backslash escape
        .replaceAll(';', '\\;')     // Semicolon escape
        .replaceAll(',', '\\,')     // Comma escape
        .replaceAll('\n', '\\n')    // Newline escape
        .replaceAll('\r', '');      // Remove carriage return
  }

  /// Escaped und faltet Text für ICS DESCRIPTION
  /// ICS-Zeilen sollten max 75 Zeichen haben
  static String _escapeAndFoldIcsText(String text) {
    final escaped = _escapeIcsText(text);

    // Folding: Zeilen über 75 Zeichen werden mit CRLF + Space umgebrochen
    final buffer = StringBuffer();
    var currentLine = '';

    for (var i = 0; i < escaped.length; i++) {
      currentLine += escaped[i];

      if (currentLine.length >= 74) {
        buffer.write(currentLine);
        buffer.write('\r\n '); // Fold mit Space
        currentLine = '';
      }
    }

    if (currentLine.isNotEmpty) {
      buffer.write(currentLine);
    }

    return buffer.toString();
  }

  /// Konvertiert EventType zu lesbarer Kategorie
  static String _getEventTypeCategory(EventType type) {
    switch (type) {
      case EventType.arbeitseinsatz:
        return 'Arbeitseinsatz';
      case EventType.feier:
        return 'Feier';
      case EventType.sitzung:
        return 'Sitzung';
      case EventType.training:
        return 'Training';
      case EventType.wettkampf:
        return 'Wettkampf';
      case EventType.ausflug:
        return 'Ausflug';
      case EventType.kurs:
        return 'Kurs';
      case EventType.sonstiges:
        return 'Sonstiges';
    }
  }

  /// Konvertiert EventType zu lesbarem Label
  static String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.arbeitseinsatz:
        return 'Arbeitseinsatz';
      case EventType.feier:
        return 'Feier';
      case EventType.sitzung:
        return 'Sitzung';
      case EventType.training:
        return 'Training';
      case EventType.wettkampf:
        return 'Wettkampf';
      case EventType.ausflug:
        return 'Ausflug';
      case EventType.kurs:
        return 'Kurs';
      case EventType.sonstiges:
        return 'Sonstiges';
    }
  }

  /// Konvertiert EventTargetGroup zu lesbarem Label
  static String _getTargetGroupLabel(EventTargetGroup group) {
    switch (group) {
      case EventTargetGroup.jugend:
        return 'Jugend';
      case EventTargetGroup.aktive:
        return 'Aktive';
      case EventTargetGroup.senioren:
        return 'Senioren';
      case EventTargetGroup.alle:
        return 'Alle';
    }
  }

  /// Generiert einen ICS-Template mit Beispiel-Event
  static String generateIcsTemplate() {
    final exampleEvent = Event(
      id: 'example-1',
      title: 'Beispiel Arbeitseinsatz',
      description: 'Dies ist ein Beispiel-Event für den ICS-Export.',
      startDate: DateTime(2025, 11, 15, 9, 0),
      endDate: DateTime(2025, 11, 15, 12, 0),
      isAllDay: false,
      location: 'Vereinsgelände',
      type: EventType.arbeitseinsatz,
      targetGroups: [EventTargetGroup.aktive, EventTargetGroup.senioren],
      maxParticipants: 20,
      currentParticipants: 5,
      organizerName: 'Max Mustermann',
      imageUrl: null,
      createdAt: DateTime.now(),
    );

    return exportEventsToIcs([exampleEvent]);
  }
}
