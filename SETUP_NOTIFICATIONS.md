# Notification-System Setup - Schritt für Schritt

## 📋 Voraussetzungen

- Supabase-Projekt erstellt
- `event` Tabelle existiert bereits
- `member` Tabelle existiert bereits mit `user_id` Spalte

## 🚀 Setup über Supabase Dashboard (Empfohlen)

### Schritt 1: Supabase Dashboard öffnen

1. Gehe zu https://supabase.com
2. Logge dich ein
3. Wähle dein Projekt aus

### Schritt 2: SQL Editor öffnen

1. Klicke in der **linken Sidebar** auf **"SQL Editor"**
2. Klicke auf **"New query"**

### Schritt 3: Migration ausführen

1. **Kopiere** den kompletten Inhalt von `supabase/migrations/add_notifications_table.sql`
2. **Füge** ihn in den SQL Editor ein
3. Klicke auf **"Run"** (oder drücke Ctrl/Cmd + Enter)

### Schritt 4: Erfolg prüfen

Du solltest folgende Erfolgsmeldungen sehen:
- ✅ `CREATE TYPE notification_type`
- ✅ `CREATE TABLE notifications`
- ✅ `CREATE INDEX` (5x)
- ✅ `CREATE POLICY` (4x)
- ✅ `CREATE FUNCTION` (3x)
- ✅ `CREATE TRIGGER`
- ✅ `CREATE VIEW`

### Schritt 5: Tabelle verifizieren

1. Gehe zu **"Table Editor"** in der linken Sidebar
2. Du solltest jetzt die neue Tabelle **"notifications"** sehen
3. Klicke darauf - die Tabelle sollte leer sein

### Schritt 6: Realtime aktivieren (Wichtig!)

1. Gehe zu **"Database" → "Replication"** in der linken Sidebar
2. Suche die Tabelle **"notifications"**
3. Aktiviere den Toggle bei **"Realtime"**
4. Klicke **"Save"**

Das war's! 🎉

---

## 🧪 Testen

### Test 1: Notification manuell erstellen

Im SQL Editor:

```sql
-- Teste Notification-Erstellung (ersetze USER_ID mit deiner User-ID)
INSERT INTO notifications (user_id, type, title, message)
VALUES (
  'DEINE-USER-UUID-HIER',
  'announcement',
  'Test-Benachrichtigung',
  'Dies ist eine Test-Nachricht!'
);
```

### Test 2: In der App prüfen

1. Starte deine Flutter-App
2. Logge dich ein
3. Schaue auf das Glocken-Icon im AppBar
4. Es sollte eine **"1"** anzeigen
5. Klicke auf die Glocke
6. Du solltest die Test-Notification sehen

### Test 3: Admin-Ankündigung testen

1. In der App: Navigiere zu `/admin/announcements`
2. Erstelle eine Test-Ankündigung
3. Alle User sollten die Notification erhalten

### Test 4: Event-Trigger testen

1. Erstelle ein neues Event (über deine Event-Verwaltung)
2. Alle User sollten automatisch benachrichtigt werden

---

## 🔧 Troubleshooting

### Problem: Migration schlägt fehl

**Fehler: `relation "event" does not exist`**
- **Lösung**: Stelle sicher, dass die `event` Tabelle existiert
- Falls nicht, erstelle sie zuerst

**Fehler: `relation "member" does not exist`**
- **Lösung**: Stelle sicher, dass die `member` Tabelle existiert
- Falls nicht, erstelle sie zuerst

**Fehler: `type "notification_type" already exists`**
- **Lösung**: Das ist OK, bedeutet die Migration wurde schon ausgeführt
- Ignoriere den Fehler oder lösche die erste Zeile (`CREATE TYPE...`)

### Problem: Badge zeigt keine Zahl

1. **Prüfe Realtime**: Ist Realtime für `notifications` aktiviert?
2. **Prüfe Policies**: Führe im SQL Editor aus:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'notifications';
   ```
   Du solltest 4 Policies sehen.

3. **Prüfe Daten**: Gibt es Notifications?
   ```sql
   SELECT * FROM notifications WHERE user_id = 'DEINE-USER-UUID';
   ```

### Problem: Admin kann keine Ankündigungen senden

1. **Prüfe Function**: Im SQL Editor:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'create_notification_for_all_users';
   ```
   Sollte einen Eintrag zurückgeben.

2. **Prüfe Console**: Schaue in der Browser-Console nach Fehlern

---

## 🎯 Alternative: Setup über Supabase CLI

Falls du Supabase CLI installiert hast:

### Installation

```bash
# macOS/Linux
brew install supabase/tap/supabase

# Windows
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Ausführen

```bash
cd /home/user/asv_app

# Login
supabase login

# Link zum Projekt
supabase link --project-ref dein-projekt-ref

# Migration ausführen
supabase db push
```

---

## ✅ Checkliste

Nach dem Setup solltest du:

- [ ] Tabelle `notifications` existiert in Supabase
- [ ] 4 RLS Policies sind aktiv
- [ ] Realtime ist aktiviert für `notifications`
- [ ] Trigger `event_created_notification` existiert
- [ ] Functions `create_notification_for_all_users` und `create_notification_for_users` existieren
- [ ] View `unread_notifications_count` existiert
- [ ] Badge zeigt Anzahl ungelesener Notifications
- [ ] Notification Center ist über `/notifications` erreichbar
- [ ] Admin-Panel ist über `/admin/announcements` erreichbar

---

## 📞 Support

Wenn du Probleme hast:

1. Prüfe die Browser-Console auf Fehler
2. Prüfe die Supabase-Logs (Settings → Logs)
3. Stelle sicher, dass alle Tabellen-Referenzen korrekt sind (`event`, `member`, `auth.users`)

Viel Erfolg! 🚀
