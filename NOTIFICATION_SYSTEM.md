# Notification System - Dokumentation

## Übersicht

Das Notification-System ermöglicht In-App-Benachrichtigungen für User mit folgenden Features:

- ✅ **In-App Notifications** - Benachrichtigungscenter mit Liste aller Notifications
- ✅ **Badge-Anzeige** - Ungelesene Notifications werden im AppBar-Icon angezeigt
- ✅ **Realtime Updates** - Automatic Updates via Supabase Realtime
- ✅ **Event-Integration** - Automatische Notifications bei neuen Events
- ✅ **Admin-Ankündigungen** - Admins können Announcements an alle User senden
- ✅ **Verschiedene Typen** - Events, Announcements, Achievements, etc.
- ✅ **Interaktive Notifications** - Mit Links zu relevanten Screens

## Architektur

### Komponenten

```
┌─────────────────────────────────────────┐
│  Database (Supabase)                    │
│  - notifications Tabelle                │
│  - RLS Policies                         │
│  - Trigger für Event-Notifications      │
│  - Functions für Bulk-Notifications     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Repository Layer                        │
│  - NotificationRepository                │
│  - CRUD Operations                       │
│  - Realtime Streams                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Provider Layer (Riverpod)              │
│  - notificationsProvider                │
│  - unreadNotificationsCountProvider     │
│  - State Management                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  UI Layer                                │
│  - NotificationsScreen                   │
│  - Notification Badge (AppBar)           │
│  - Admin Announcement Screen             │
└─────────────────────────────────────────┘
```

## Datenbank-Schema

### Tabelle: notifications

```sql
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  action_url TEXT,
  action_label TEXT,
  event_id BIGINT REFERENCES event(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);
```

### Notification Types

- **event_new** - Neues Event wurde erstellt
- **event_reminder** - Erinnerung an bevorstehendes Event
- **event_cancelled** - Event wurde abgesagt
- **event_updated** - Event wurde aktualisiert
- **announcement** - Admin-Ankündigung
- **achievement** - Achievement freigeschaltet (für Jugend)
- **level_up** - Level-Up (für Jugend)
- **system** - System-Nachricht

## Verwendung

### 1. Notifications anzeigen

Navigiere zu `/notifications` oder klicke auf das Glocken-Icon im AppBar.

### 2. Notification Badge

Das Badge wird automatisch aktualisiert und zeigt die Anzahl ungelesener Notifications:

```dart
// Wird automatisch in DashboardScreen und JugendDashboard angezeigt
_NotificationBadge()
```

### 3. Admin-Ankündigungen erstellen

Navigiere zu `/admin/announcements`:

```dart
// Im Code:
context.push('/admin/announcements');
```

Admins können:
- Titel und Nachricht eingeben
- Optional: Button-Text und Link hinzufügen
- Vorschau sehen
- An alle User senden

### 4. Automatische Event-Notifications

Wenn ein neues Event erstellt wird, erhalten **alle User** automatisch eine Notification:

```sql
-- Trigger wird automatisch ausgeführt
CREATE TRIGGER event_created_notification
  AFTER INSERT ON event
  FOR EACH ROW
  EXECUTE FUNCTION notify_users_on_new_event();
```

### 5. Programmatisch Notifications erstellen

```dart
// Für einen User
final repository = NotificationRepository(Supabase.instance.client);
await repository.createNotification(
  userId: 'user-uuid',
  type: NotificationType.announcement,
  title: 'Wichtig!',
  message: 'Dies ist eine Testnachricht',
  actionUrl: '/events/123',
  actionLabel: 'Event ansehen',
);

// Für alle User (Admin)
await repository.createAnnouncementForAll(
  title: 'Wichtige Ankündigung',
  message: 'Alle Member bitte lesen!',
  actionUrl: '/announcements/123',
  actionLabel: 'Mehr erfahren',
);

// Für spezifische User
await repository.createNotificationForUsers(
  userIds: ['uuid1', 'uuid2', 'uuid3'],
  type: NotificationType.eventReminder,
  title: 'Event-Erinnerung',
  message: 'Das Event startet in 1 Stunde!',
  eventId: 123,
);
```

## Provider

### notificationsProvider

Lädt und verwaltet alle Notifications:

```dart
// Notifications laden
final notificationsAsync = ref.watch(notificationsProvider);

// Actions
ref.read(notificationsProvider.notifier).loadNotifications();
ref.read(notificationsProvider.notifier).markAsRead(notificationId);
ref.read(notificationsProvider.notifier).markAllAsRead();
ref.read(notificationsProvider.notifier).deleteNotification(notificationId);
ref.read(notificationsProvider.notifier).refresh();
```

### unreadNotificationsCountStreamProvider

Stream für Anzahl ungelesener Notifications (Realtime):

```dart
final unreadCountAsync = ref.watch(unreadNotificationsCountStreamProvider);
```

## Features

### Notification Center (/notifications)

- Liste aller Notifications
- Filter: Alle / Nur ungelesene
- Swipe-Gesten:
  - Swipe rechts: Als gelesen markieren
  - Swipe links: Löschen
- Pull-to-Refresh
- Tap auf Notification: Navigation zu Action-URL
- Menü:
  - Alle als gelesen markieren
  - Alle löschen (mit Bestätigung)

### Notification Badge

- Zeigt Anzahl ungelesener Notifications
- Realtime Updates via Supabase Stream
- Funktioniert in:
  - Standard Dashboard
  - Jugend Dashboard

### Admin-Ankündigungen

- Formular mit Validierung
- Vorschau der Notification
- Erfolgs-/Fehler-Meldungen
- Anzahl der erreichten User
- Optional: Button mit Link

## Setup-Anleitung

### 1. Datenbank-Migration ausführen

```bash
# Mit Supabase CLI
supabase db push

# Oder manuell in Supabase Dashboard
-- Führe add_notifications_table.sql aus
```

### 2. RLS Policies

Die Policies sind bereits in der Migration enthalten:

- User können nur ihre eigenen Notifications sehen
- User können ihre eigenen Notifications bearbeiten/löschen
- Service Role kann Notifications erstellen (für Backend/Trigger)

### 3. Testen

1. Login als beliebiger User
2. Navigiere zu `/notifications` - sollte leer sein
3. Als Admin: Navigiere zu `/admin/announcements`
4. Erstelle eine Test-Ankündigung
5. Überprüfe: Badge sollte "1" anzeigen
6. Öffne Notification Center - Ankündigung sollte erscheinen
7. Teste Event-Integration: Erstelle ein neues Event
8. Alle User sollten automatisch benachrichtigt werden

## Erweiterungsmöglichkeiten

### 1. Push Notifications

Aktuell: Nur In-App Notifications
Zukünftig: FCM (Firebase Cloud Messaging) Integration

```dart
// TODO: FCM Token registrieren
// TODO: Backend für Push-Notifications
// TODO: Notification-Handler für App im Background
```

### 2. Weitere Notification-Typen

```dart
// In notification.dart hinzufügen:
enum NotificationType {
  // ... existing types
  catchLiked('catch_liked', 'Fang geliked', Icons.favorite),
  comment('comment', 'Neuer Kommentar', Icons.comment),
  friendRequest('friend_request', 'Freundschaftsanfrage', Icons.person_add),
}
```

### 3. Notification-Einstellungen

Screen für User-Präferenzen:
- Welche Notifications möchte ich erhalten?
- Push-Notifications ein/aus
- Benachrichtigungs-Zeitraum

```dart
// TODO: Settings Screen
// TODO: notification_preferences Tabelle
// TODO: Integration in Backend
```

### 4. Gruppierte Notifications

Ähnliche Notifications gruppieren:
- "3 neue Events verfügbar"
- "5 neue Achievements freigeschaltet"

### 5. Scheduled Notifications

Event-Erinnerungen zu bestimmten Zeiten:
- 1 Tag vor Event
- 1 Stunde vor Event

```sql
-- TODO: Scheduled Function in Supabase
-- TODO: pg_cron für zeitgesteuerte Notifications
```

### 6. Rich Notifications

- Bilder in Notifications
- Videos
- Interaktive Buttons

## Troubleshooting

### Badge zeigt keine Zahl an

- Prüfe: Sind Notifications in der DB vorhanden?
- Prüfe: RLS Policies korrekt?
- Prüfe: Realtime aktiviert in Supabase?
- Console-Fehler checken

### Notifications werden nicht geladen

- Migration ausgeführt?
  ```sql
  SELECT * FROM notifications LIMIT 1;
  ```
- RLS Policies vorhanden?
  ```sql
  SELECT * FROM pg_policies WHERE tablename = 'notifications';
  ```
- Network-Fehler? (Browser Console)

### Event-Notifications funktionieren nicht

- Trigger vorhanden?
  ```sql
  SELECT * FROM pg_trigger WHERE tgname = 'event_created_notification';
  ```
- Function vorhanden?
  ```sql
  SELECT * FROM pg_proc WHERE proname = 'notify_users_on_new_event';
  ```

### Admin kann keine Ankündigungen senden

- Function vorhanden?
  ```sql
  SELECT * FROM pg_proc WHERE proname = 'create_notification_for_all_users';
  ```
- Service Role Permissions?
- Error in Console checken

## Performance

### Optimierungen

1. **Indizes** - Bereits implementiert für:
   - user_id
   - created_at
   - read
   - type

2. **Pagination** - Repository unterstützt limit/offset

3. **Realtime** - Nur für unread count, nicht für komplette Liste

4. **Caching** - Riverpod cached automatisch

### Skalierung

Für große User-Anzahlen:

1. **Lazy Loading** - Nur X Notifications auf einmal laden
2. **Background Jobs** - Bulk-Notifications asynchron erstellen
3. **Notification-Archivierung** - Alte Notifications automatisch löschen

```sql
-- TODO: Cleanup Job für alte Notifications
DELETE FROM notifications
WHERE created_at < NOW() - INTERVAL '90 days'
  AND read = TRUE;
```

## Security

### RLS Policies

Alle Policies sind bereits implementiert:

```sql
-- Users können nur eigene Notifications sehen
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users können nur eigene Notifications updaten
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Nur Service Role kann Notifications erstellen
-- (via Backend oder Trigger)
```

### Best Practices

1. ✅ Verwende NIEMALS client-seitige INSERT direkt
2. ✅ Alle Bulk-Operations via Backend-Functions
3. ✅ Validiere Input in Functions
4. ✅ Rate-Limiting für Admin-Announcements (TODO)
5. ✅ Escape HTML in Messages (bereits via Flutter)

## Testing

### Unit Tests

```dart
// TODO: Tests für Repository
test('getNotifications returns list', () async {
  final repo = NotificationRepository(mockSupabase);
  final notifications = await repo.getNotifications();
  expect(notifications, isA<List<AppNotification>>());
});
```

### Integration Tests

```dart
// TODO: E2E Test für kompletten Flow
testWidgets('User receives notification', (tester) async {
  // 1. Login
  // 2. Admin sendet Announcement
  // 3. Badge sollte "1" zeigen
  // 4. Öffne Notification Center
  // 5. Notification sollte sichtbar sein
});
```

## Zusammenfassung

Das Notification-System ist vollständig implementiert und produktionsbereit für:

✅ In-App Notifications
✅ Event-Benachrichtigungen (automatisch)
✅ Admin-Ankündigungen
✅ Realtime Badge-Updates
✅ Notification Center mit allen Features
✅ Swipe-Gesten, Filter, Refresh
✅ Responsive UI für alle Geräte

Für zukünftige Entwicklung siehe "Erweiterungsmöglichkeiten" oben.
