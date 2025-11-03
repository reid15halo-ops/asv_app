# Scheduled Notifications Setup Guide (pg_cron)

## Übersicht

Diese Anleitung beschreibt, wie zeitgesteuerte (scheduled) Notifications in die ASV Großostheim App integriert werden können. Beispiele:
- Event-Erinnerungen (1 Tag/1 Stunde vor Event)
- Wöchentliche Zusammenfassungen
- Automatische Birthday-Greetings
- Inaktivitäts-Erinnerungen

**Status**: 🚧 Noch nicht implementiert - Diese Dokumentation dient als Anleitung für die zukünftige Implementierung

## Voraussetzungen

- Supabase-Projekt mit PostgreSQL
- pg_cron Extension aktiviert
- Notification System bereits implementiert
- Admin-Zugriff auf Supabase

## 1. pg_cron Extension aktivieren

### 1.1 In Supabase aktivieren

```sql
-- Als Superuser (via Supabase SQL Editor)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Verifiziere Installation
SELECT * FROM pg_extension WHERE extname = 'pg_cron';
```

**Hinweis**: In Supabase muss pg_cron möglicherweise durch Support aktiviert werden.

### 1.2 Berechtigungen prüfen

```sql
-- Prüfe ob pg_cron verfügbar ist
SELECT cron.schedule('test-job', '* * * * *', 'SELECT 1;');

-- Job wieder löschen
SELECT cron.unschedule('test-job');
```

## 2. Event-Erinnerungen implementieren

### 2.1 Scheduled Reminders Tabelle

Erstelle Tabelle für geplante Erinnerungen:

```sql
-- Migration: scheduled_notifications table
CREATE TABLE scheduled_notifications (
  id BIGSERIAL PRIMARY KEY,

  -- Scheduling
  scheduled_for TIMESTAMPTZ NOT NULL,
  executed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'executed', 'cancelled', 'failed'

  -- Notification Details
  notification_type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,

  -- Target
  target_type TEXT NOT NULL, -- 'user', 'users', 'all', 'group'
  target_user_id UUID REFERENCES auth.users(id),
  target_user_ids UUID[],
  target_group TEXT, -- z.B. 'jugend', 'mitglieder'

  -- Optional Links
  action_url TEXT,
  action_label TEXT,
  event_id BIGINT REFERENCES event(id),

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  error_message TEXT
);

CREATE INDEX idx_scheduled_notifications_scheduled_for
  ON scheduled_notifications(scheduled_for)
  WHERE status = 'pending';

CREATE INDEX idx_scheduled_notifications_status
  ON scheduled_notifications(status);

COMMENT ON TABLE scheduled_notifications IS 'Geplante Notifications die zu einem späteren Zeitpunkt versendet werden';
```

### 2.2 Function zum Verarbeiten scheduled Notifications

```sql
CREATE OR REPLACE FUNCTION process_scheduled_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  processed_count INTEGER := 0;
  scheduled_notif RECORD;
  target_users UUID[];
BEGIN
  -- Hole alle pending Notifications die fällig sind
  FOR scheduled_notif IN
    SELECT * FROM scheduled_notifications
    WHERE status = 'pending'
      AND scheduled_for <= NOW()
    ORDER BY scheduled_for
    LIMIT 100 -- Limitiere pro Durchlauf
  LOOP
    BEGIN
      -- Bestimme Ziel-User basierend auf target_type
      CASE scheduled_notif.target_type
        WHEN 'user' THEN
          target_users := ARRAY[scheduled_notif.target_user_id];

        WHEN 'users' THEN
          target_users := scheduled_notif.target_user_ids;

        WHEN 'all' THEN
          SELECT ARRAY_AGG(id) INTO target_users
          FROM auth.users;

        WHEN 'group' THEN
          -- Beispiel für Gruppen (anpassen an deine member_group Tabelle)
          SELECT ARRAY_AGG(m.user_id) INTO target_users
          FROM member m
          JOIN member_group mg ON m.member_group_id = mg.id
          WHERE mg.name = scheduled_notif.target_group;

        ELSE
          RAISE EXCEPTION 'Unknown target_type: %', scheduled_notif.target_type;
      END CASE;

      -- Erstelle Notifications für alle Target-User
      INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        action_url,
        action_label,
        event_id
      )
      SELECT
        unnest(target_users),
        scheduled_notif.notification_type,
        scheduled_notif.title,
        scheduled_notif.message,
        scheduled_notif.action_url,
        scheduled_notif.action_label,
        scheduled_notif.event_id;

      -- Markiere als executed
      UPDATE scheduled_notifications
      SET status = 'executed',
          executed_at = NOW()
      WHERE id = scheduled_notif.id;

      processed_count := processed_count + 1;

    EXCEPTION WHEN OTHERS THEN
      -- Bei Fehler: Markiere als failed
      UPDATE scheduled_notifications
      SET status = 'failed',
          error_message = SQLERRM
      WHERE id = scheduled_notif.id;
    END;
  END LOOP;

  RETURN processed_count;
END;
$$;

COMMENT ON FUNCTION process_scheduled_notifications IS 'Verarbeitet alle fälligen scheduled notifications und erstellt die eigentlichen Notifications';
```

### 2.3 Cron Job erstellen

```sql
-- Läuft jede Minute und prüft auf fällige Notifications
SELECT cron.schedule(
  'process-scheduled-notifications',
  '* * * * *',  -- Jede Minute
  'SELECT process_scheduled_notifications();'
);

-- Verifiziere Job
SELECT * FROM cron.job WHERE jobname = 'process-scheduled-notifications';

-- Job-Runs überprüfen
SELECT * FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'process-scheduled-notifications')
ORDER BY start_time DESC
LIMIT 10;
```

## 3. Event-Reminder automatisch erstellen

### 3.1 Trigger für neue Events

```sql
CREATE OR REPLACE FUNCTION schedule_event_reminders()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  event_time TIMESTAMPTZ;
BEGIN
  event_time := NEW.date;

  -- Schedule Reminder 1 Tag vorher (nur wenn Event mehr als 1 Tag in der Zukunft)
  IF event_time > NOW() + INTERVAL '1 day' THEN
    INSERT INTO scheduled_notifications (
      scheduled_for,
      notification_type,
      title,
      message,
      target_type,
      action_url,
      action_label,
      event_id
    ) VALUES (
      event_time - INTERVAL '1 day',
      'event_reminder',
      'Event-Erinnerung: ' || NEW.title,
      'Das Event "' || NEW.title || '" findet morgen statt!',
      'all',
      '/events/' || NEW.id,
      'Details ansehen',
      NEW.id
    );
  END IF;

  -- Schedule Reminder 1 Stunde vorher (nur wenn Event mehr als 1 Stunde in der Zukunft)
  IF event_time > NOW() + INTERVAL '1 hour' THEN
    INSERT INTO scheduled_notifications (
      scheduled_for,
      notification_type,
      title,
      message,
      target_type,
      action_url,
      action_label,
      event_id
    ) VALUES (
      event_time - INTERVAL '1 hour',
      'event_reminder',
      'Event startet bald: ' || NEW.title,
      'Das Event "' || NEW.title || '" beginnt in 1 Stunde!',
      'all',
      '/events/' || NEW.id,
      'Jetzt ansehen',
      NEW.id
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger erstellen
CREATE TRIGGER on_event_created_schedule_reminders
  AFTER INSERT ON event
  FOR EACH ROW
  EXECUTE FUNCTION schedule_event_reminders();

-- Trigger für Event-Updates (bei Datumsänderung)
CREATE OR REPLACE FUNCTION reschedule_event_reminders()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Wenn Datum geändert wurde
  IF NEW.date != OLD.date THEN
    -- Lösche alte Reminders
    DELETE FROM scheduled_notifications
    WHERE event_id = NEW.id
      AND status = 'pending';

    -- Erstelle neue Reminders
    PERFORM schedule_event_reminders_for_event(NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_event_updated_reschedule_reminders
  AFTER UPDATE ON event
  FOR EACH ROW
  WHEN (NEW.date IS DISTINCT FROM OLD.date)
  EXECUTE FUNCTION reschedule_event_reminders();
```

### 3.2 Helper Function für einzelnes Event

```sql
CREATE OR REPLACE FUNCTION schedule_event_reminders_for_event(event_id_param BIGINT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  event_record RECORD;
BEGIN
  SELECT * INTO event_record FROM event WHERE id = event_id_param;

  -- Rufe Trigger-Logik auf (wiederverwendbar)
  -- Implementierung ähnlich wie schedule_event_reminders()
END;
$$;
```

## 4. Weitere Use Cases

### 4.1 Wöchentliche Zusammenfassung

```sql
-- Jeden Montag um 9 Uhr
SELECT cron.schedule(
  'weekly-summary',
  '0 9 * * 1',  -- Montag 9:00
  $$
  INSERT INTO scheduled_notifications (
    scheduled_for,
    notification_type,
    title,
    message,
    target_type
  ) VALUES (
    NOW(),
    'system',
    'Wochenübersicht',
    'Hier ist deine Zusammenfassung der letzten Woche!',
    'all'
  );
  $$
);
```

### 4.2 Birthday Notifications

```sql
-- Trigger für Geburtstags-Benachrichtigungen
CREATE OR REPLACE FUNCTION schedule_birthday_notifications()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Erstelle Notifications für alle Geburtstage in den nächsten 7 Tagen
  INSERT INTO scheduled_notifications (
    scheduled_for,
    notification_type,
    title,
    message,
    target_type,
    target_user_id
  )
  SELECT
    (CURRENT_DATE + (birthday - CURRENT_DATE) % INTERVAL '1 year') + TIME '08:00:00',
    'system',
    'Herzlichen Glückwunsch!',
    'Heute hat ' || name || ' Geburtstag!',
    'all',
    NULL
  FROM member
  WHERE EXTRACT(MONTH FROM birthday) = EXTRACT(MONTH FROM CURRENT_DATE + INTERVAL '7 days')
    AND EXTRACT(DAY FROM birthday) BETWEEN EXTRACT(DAY FROM CURRENT_DATE)
                                        AND EXTRACT(DAY FROM CURRENT_DATE + INTERVAL '7 days');
END;
$$;

-- Schedule täglich um 1:00 Uhr
SELECT cron.schedule(
  'schedule-birthday-notifications',
  '0 1 * * *',
  'SELECT schedule_birthday_notifications();'
);
```

### 4.3 Inaktivitäts-Reminder

```sql
-- Erinnere User die 30 Tage inaktiv waren
CREATE OR REPLACE FUNCTION schedule_inactive_user_reminders()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  inactive_count INTEGER;
BEGIN
  INSERT INTO scheduled_notifications (
    scheduled_for,
    notification_type,
    title,
    message,
    target_type,
    target_user_id
  )
  SELECT
    NOW(),
    'system',
    'Wir vermissen dich!',
    'Du warst lange nicht mehr da. Schau doch mal rein!',
    'user',
    u.id
  FROM auth.users u
  WHERE u.last_sign_in_at < NOW() - INTERVAL '30 days'
    AND NOT EXISTS (
      SELECT 1 FROM scheduled_notifications sn
      WHERE sn.target_user_id = u.id
        AND sn.notification_type = 'system'
        AND sn.title = 'Wir vermissen dich!'
        AND sn.created_at > NOW() - INTERVAL '30 days'
    );

  GET DIAGNOSTICS inactive_count = ROW_COUNT;
  RETURN inactive_count;
END;
$$;

-- Läuft wöchentlich
SELECT cron.schedule(
  'inactive-user-reminders',
  '0 10 * * 1',  -- Montag 10:00
  'SELECT schedule_inactive_user_reminders();'
);
```

## 5. Monitoring & Maintenance

### 5.1 View für Job-Status

```sql
CREATE OR REPLACE VIEW scheduled_notification_stats AS
SELECT
  status,
  COUNT(*) as count,
  MIN(scheduled_for) as earliest,
  MAX(scheduled_for) as latest
FROM scheduled_notifications
GROUP BY status;

-- Verwenden
SELECT * FROM scheduled_notification_stats;
```

### 5.2 Cleanup alter Notifications

```sql
CREATE OR REPLACE FUNCTION cleanup_old_scheduled_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Lösche executed Notifications älter als 90 Tage
  DELETE FROM scheduled_notifications
  WHERE status IN ('executed', 'cancelled')
    AND executed_at < NOW() - INTERVAL '90 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- Schedule cleanup (monatlich)
SELECT cron.schedule(
  'cleanup-scheduled-notifications',
  '0 2 1 * *',  -- 1. Tag des Monats, 2:00 Uhr
  'SELECT cleanup_old_scheduled_notifications();'
);
```

### 5.3 Failed Notifications erneut versuchen

```sql
CREATE OR REPLACE FUNCTION retry_failed_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  retry_count INTEGER;
BEGIN
  -- Setze failed Notifications zurück auf pending (max 3 Versuche)
  UPDATE scheduled_notifications
  SET status = 'pending',
      scheduled_for = NOW() + INTERVAL '5 minutes'
  WHERE status = 'failed'
    AND (
      SELECT COUNT(*)
      FROM scheduled_notifications sn2
      WHERE sn2.id = scheduled_notifications.id
    ) < 3;

  GET DIAGNOSTICS retry_count = ROW_COUNT;
  RETURN retry_count;
END;
$$;
```

## 6. Testing

### 6.1 Manuelle Test-Notification erstellen

```sql
-- Erstelle Test-Notification für sofort
INSERT INTO scheduled_notifications (
  scheduled_for,
  notification_type,
  title,
  message,
  target_type,
  target_user_id
) VALUES (
  NOW(),
  'system',
  'Test Notification',
  'Dies ist eine Test-Notification',
  'user',
  'YOUR_USER_ID'
);

-- Prüfe nach 1 Minute ob verarbeitet
SELECT * FROM scheduled_notifications
WHERE title = 'Test Notification';
```

### 6.2 Job manuell ausführen

```sql
-- Führe process_scheduled_notifications manuell aus
SELECT process_scheduled_notifications();

-- Prüfe Ergebnis
SELECT * FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 1;
```

## 7. Admin Interface (Optional)

### 7.1 RPC für Admin-Zugriff

```sql
-- Function zum Erstellen scheduled Notification via Admin UI
CREATE OR REPLACE FUNCTION admin_create_scheduled_notification(
  p_scheduled_for TIMESTAMPTZ,
  p_notification_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_target_type TEXT,
  p_target_user_ids UUID[] DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_id BIGINT;
BEGIN
  -- Prüfe ob User Admin ist
  IF NOT EXISTS (
    SELECT 1 FROM member
    WHERE user_id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  INSERT INTO scheduled_notifications (
    scheduled_for,
    notification_type,
    title,
    message,
    target_type,
    target_user_ids
  ) VALUES (
    p_scheduled_for,
    p_notification_type::notification_type,
    p_title,
    p_message,
    p_target_type,
    p_target_user_ids
  ) RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_create_scheduled_notification TO authenticated;
```

## 8. Best Practices

### 8.1 Performance

- Limitiere Batch-Größe (z.B. 100 pro Durchlauf)
- Verwende Indizes auf `scheduled_for` und `status`
- Cleanup alte Notifications regelmäßig

### 8.2 Error Handling

- Logge Fehler in `error_message` Spalte
- Implementiere Retry-Logik
- Alerting für konsistent failing Jobs

### 8.3 Testing

- Teste mit kurzfristigen Notifications zuerst
- Monitore Job-Run-Details in Produktion
- Verwende separate Tabelle für Test-Notifications

## 9. Troubleshooting

### Problem: Cron Job läuft nicht

```sql
-- Prüfe Job-Status
SELECT * FROM cron.job;

-- Prüfe letzte Runs
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

-- Prüfe pg_cron logs
SELECT * FROM cron.job_run_details WHERE status = 'failed';
```

### Problem: Notifications werden nicht erstellt

```sql
-- Prüfe pending Notifications
SELECT * FROM scheduled_notifications WHERE status = 'pending';

-- Führe Function manuell aus
SELECT process_scheduled_notifications();

-- Prüfe Fehler
SELECT * FROM scheduled_notifications WHERE status = 'failed';
```

### Problem: Jobs akkumulieren

- Erhöhe Batch-Limit in `process_scheduled_notifications()`
- Reduziere Cron-Intervall (z.B. alle 30 Sekunden)
- Prüfe auf Performance-Probleme

## 10. Zusammenfassung

Nach Implementierung dieser Anleitung:

✅ pg_cron aktiviert und konfiguriert
✅ `scheduled_notifications` Tabelle erstellt
✅ Automatische Event-Reminders
✅ Cron Jobs für regelmäßige Tasks
✅ Monitoring und Cleanup
✅ Error Handling und Retry-Logik
✅ Admin Interface für manuelle scheduled Notifications

## Referenzen

- [pg_cron Documentation](https://github.com/citusdata/pg_cron)
- [Supabase Cron Guide](https://supabase.com/docs/guides/database/extensions/pg_cron)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/trigger-definition.html)
