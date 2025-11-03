# Archive - Legacy Code und Tools

Dieses Verzeichnis enthält archivierte Dateien, die möglicherweise nicht mehr aktiv verwendet werden, aber aus historischen oder Referenzzwecken aufbewahrt werden.

## 📦 Inhalt

### tools/

#### annual-export/
Legacy Node.js Script für jährliche Export-Funktionalität.
- **Status**: Ersetzt durch `features/admin/export_panel.dart`
- **Archiviert am**: 2025-11-03
- **Grund**: Neue Flutter-basierte Export-Funktionalität im Admin-Panel

#### migration/
Legacy Migration-Scripts.
- **Status**: Möglicherweise veraltet
- **Archiviert am**: 2025-11-03
- **Grund**: Neuere Migrations in `supabase/migrations/`

### supabase/functions/

#### export_catches/
Legacy Supabase Edge Function für Fang-Export.
- **Status**: Ersetzt durch neues Export-System
- **Archiviert am**: 2025-11-03
- **Grund**: Neuere Export-Implementierung im Admin-Panel

## ⚠️ Hinweis

Diese Dateien sollten **nicht** für neue Entwicklung verwendet werden. Sie werden nur als Referenz aufbewahrt und könnten in Zukunft gelöscht werden.

Wenn du Funktionalität aus diesen Dateien benötigst:
1. Prüfe ob es eine neuere Alternative im Hauptprojekt gibt
2. Konsultiere die Dokumentation in `docs/`
3. Bei Bedarf: Portiere den Code in ein neues Format

## 🗑️ Lösch-Zeitplan

Diese archivierten Dateien können gelöscht werden nach:
- **Mindestens 6 Monate** ohne Verwendung
- Nach Bestätigung dass alle Funktionalität migriert wurde
- Nach Projekt-Review durch Team

---

Letzte Aktualisierung: 2025-11-03
