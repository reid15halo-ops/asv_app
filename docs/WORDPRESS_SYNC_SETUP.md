# WordPress Event Synchronisation Setup

Diese Anleitung erklärt, wie du die bidirektionale Event-Synchronisation zwischen der ASV-App und WordPress einrichtest.

## Voraussetzungen

Die App verwendet **"The Events Calendar" Plugin** von Modern Tribe.

- WordPress mit The Events Calendar Plugin installiert
- REST API aktiviert (standardmäßig in WordPress)
- Application Password für API-Zugriff

---

## 1. WordPress konfigurieren

### 1.1 The Events Calendar installieren

1. In WordPress Admin: **Plugins > Installieren**
2. Suche nach **"The Events Calendar"**
3. Installieren und aktivieren
4. Optional: **Event Tickets** für Teilnehmerverwaltung

### 1.2 Application Password erstellen

WordPress Application Passwords ermöglichen sicheren API-Zugriff ohne dein echtes Passwort zu verwenden.

**Schritte:**

1. In WordPress Admin: **Benutzer > Profil**
2. Scrolle nach unten zu **"Anwendungspasswörter"**
3. Gib einen Namen ein (z.B. "ASV Flutter App")
4. Klicke auf **"Neues Anwendungspasswort hinzufügen"**
5. **WICHTIG:** Kopiere das generierte Passwort sofort!
   - Format: `xxxx xxxx xxxx xxxx xxxx xxxx`
   - Du kannst es später nicht mehr sehen!

**Beispiel:**
```
Passwort: a1B2 c3D4 e5F6 g7H8 i9J0 k1L2
```

### 1.3 REST API testen

Teste ob die API erreichbar ist:

```bash
curl https://deine-domain.de/wp-json/tribe/events/v1/events
```

**Erwartete Antwort:**
```json
{
  "events": [...],
  "total": 10,
  "total_pages": 1
}
```

---

## 2. Flutter App konfigurieren

### 2.1 WordPress-Credentials speichern

Erstelle eine sichere Konfigurationsdatei (NICHT im Git committen!):

**lib/config/wordpress_config.dart:**

```dart
class WordPressConfig {
  static const String wordpressUrl = 'https://deine-domain.de';
  static const String username = 'dein-username';
  static const String applicationPassword = 'xxxx xxxx xxxx xxxx xxxx xxxx';
}
```

**WICHTIG:** Füge diese Datei zur `.gitignore` hinzu:

```
# WordPress Credentials
lib/config/wordpress_config.dart
```

### 2.2 Sync-Service initialisieren

**lib/providers/wordpress_sync_provider.dart:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/services/wordpress_sync_service.dart';
import 'package:asv_app/repositories/event_repository.dart';
import 'package:asv_app/config/wordpress_config.dart';

final wordPressSyncServiceProvider = Provider<WordPressSyncService>((ref) {
  final repository = EventRepository(Supabase.instance.client);

  return WordPressSyncService(
    eventRepository: repository,
    wordpressUrl: WordPressConfig.wordpressUrl,
    username: WordPressConfig.username,
    applicationPassword: WordPressConfig.applicationPassword,
  );
});
```

### 2.3 Manuelle Synchronisation

```dart
// Sync Button im Admin-Bereich
ElevatedButton(
  onPressed: () async {
    final syncService = ref.read(wordPressSyncServiceProvider);

    try {
      // Bidirektionale Synchronisation
      final result = await syncService.syncBidirectional();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync erfolgreich: ${result.summary}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync mit Fehlern: ${result.summary}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync fehlgeschlagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: const Text('Mit WordPress synchronisieren'),
)
```

---

## 3. Automatische Synchronisation (Optional)

### 3.1 Periodischer Sync

Führe alle 30 Minuten einen Sync aus:

```dart
import 'dart:async';

class AutoSyncService {
  Timer? _syncTimer;
  final WordPressSyncService _syncService;

  AutoSyncService(this._syncService);

  void startAutoSync({Duration interval = const Duration(minutes: 30)}) {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(interval, (timer) async {
      try {
        await _syncService.syncBidirectional();
        print('Auto-Sync erfolgreich');
      } catch (e) {
        print('Auto-Sync Fehler: $e');
      }
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }
}
```

### 3.2 Webhook-basierter Sync

**WordPress Plugin Code** (custom plugin oder functions.php):

```php
<?php
// Webhook nach Event-Änderung senden
add_action('save_post_tribe_events', 'notify_app_on_event_change', 10, 3);

function notify_app_on_event_change($post_id, $post, $update) {
    if (wp_is_post_revision($post_id)) {
        return;
    }

    $webhook_url = 'https://your-app-backend.com/api/sync-trigger';

    wp_remote_post($webhook_url, [
        'body' => json_encode([
            'event_id' => $post_id,
            'action' => $update ? 'update' : 'create',
        ]),
        'headers' => [
            'Content-Type' => 'application/json',
        ],
    ]);
}
```

---

## 4. Event-Mapping

### WordPress → App

| The Events Calendar | App Event Model |
|-------------------|----------------|
| `title` | `title` |
| `description` | `description` |
| `start_date` | `startDate` |
| `end_date` | `endDate` |
| `all_day` | `allDay` |
| `venue.venue` | `location` |
| `organizer[0].organizer` | `organizer` |
| `organizer[0].email` | `contactEmail` |
| `organizer[0].phone` | `contactPhone` |
| `status` | `status` |
| `url` | `wordpressUrl` |

### App → WordPress

| App Event Model | The Events Calendar |
|----------------|-------------------|
| `title` | `title` |
| `description` | `description` |
| `startDate` | `start_date` (Format: "YYYY-MM-DD HH:MM:SS") |
| `endDate` | `end_date` (Format: "YYYY-MM-DD HH:MM:SS") |
| `allDay` | `all_day` |
| `location` | `venue.venue` |
| `organizer` | `organizer[0].organizer` |
| `contactEmail` | `organizer[0].email` |
| `contactPhone` | `organizer[0].phone` |
| `status` | `status` |

**Hinweis:** `max_participants` wird NICHT synchronisiert, da The Events Calendar dieses Feld nicht standardmäßig unterstützt.

---

## 5. Sync-Logs prüfen

Alle Sync-Operationen werden in der `event_sync_log` Tabelle protokolliert:

```sql
-- Letzte 10 Sync-Vorgänge
SELECT * FROM event_sync_log
ORDER BY created_at DESC
LIMIT 10;

-- Fehlgeschlagene Syncs
SELECT * FROM event_sync_log
WHERE status = 'failed'
ORDER BY created_at DESC;
```

---

## 6. Troubleshooting

### Problem: "401 Unauthorized"

**Lösung:**
- Application Password korrekt kopiert? (Keine Leerzeichen außer den 4er-Blöcken)
- Username korrekt? (Case-sensitive!)
- REST API aktiviert?

Test mit curl:
```bash
curl -u "username:xxxx xxxx xxxx xxxx" \
  https://deine-domain.de/wp-json/tribe/events/v1/events
```

### Problem: "404 Not Found"

**Lösung:**
- The Events Calendar Plugin installiert?
- Permalinks neu generieren: **Einstellungen > Permalinks > Speichern**

### Problem: "403 Forbidden"

**Lösung:**
- REST API von Security Plugin blockiert?
- Server Firewall blockiert REST API?
- `.htaccess` Regeln prüfen

### Problem: Events werden nicht erstellt

**Lösung:**
- Prüfe Sync-Logs in Supabase
- Prüfe WordPress Debug-Log
- Stelle sicher, dass User Edit-Rechte hat

---

## 7. Sicherheit

### Best Practices

1. **Application Passwords verwenden** (NIEMALS echtes Passwort in Code!)
2. **HTTPS verwenden** für WordPress-URL
3. **Credentials NICHT in Git committen**
4. **Environment Variables** für Production:

```dart
class WordPressConfig {
  static String get wordpressUrl =>
    const String.fromEnvironment('WP_URL');
  static String get username =>
    const String.fromEnvironment('WP_USER');
  static String get applicationPassword =>
    const String.fromEnvironment('WP_PASSWORD');
}
```

Build mit Env-Vars:
```bash
flutter build apk \
  --dart-define=WP_URL=https://example.com \
  --dart-define=WP_USER=admin \
  --dart-define=WP_PASSWORD="xxxx xxxx xxxx xxxx"
```

---

## 8. Testing

### Test-Szenario 1: WordPress → App

1. Erstelle Event in WordPress
2. Führe `syncFromWordPress()` aus
3. Prüfe ob Event in App erscheint

### Test-Szenario 2: App → WordPress

1. Erstelle Event in App
2. Führe `syncToWordPress()` aus
3. Prüfe ob Event in WordPress erscheint

### Test-Szenario 3: Bidirektional

1. Erstelle Event in WordPress
2. Erstelle anderes Event in App
3. Führe `syncBidirectional()` aus
4. Prüfe ob beide Events in beiden Systemen vorhanden sind

---

## 9. Google Maps Integration

Dein WordPress verwendet den Google Maps API Key:
```
AIzaSyDNsicAsP6-VuGtAb1O9riI3oc_NOb7IOU
```

**Optional:** Nutze denselben Key für die Flutter App:

**android/app/src/main/AndroidManifest.xml:**
```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDNsicAsP6-VuGtAb1O9riI3oc_NOb7IOU"/>
</application>
```

**ios/Runner/AppDelegate.swift:**
```swift
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyDNsicAsP6-VuGtAb1O9riI3oc_NOb7IOU")
```

---

## Support

Bei Problemen:
1. Prüfe Sync-Logs: `SELECT * FROM event_sync_log WHERE status = 'failed'`
2. Prüfe WordPress Debug-Log
3. Teste REST API mit curl
4. Kontaktiere WordPress-Admin

**The Events Calendar Docs:** https://docs.theeventscalendar.com/reference/rest-api/
