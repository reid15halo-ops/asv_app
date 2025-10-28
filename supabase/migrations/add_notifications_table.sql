-- Migration: Erstelle Notifications-Tabelle für In-App-Benachrichtigungen
-- Diese Tabelle speichert alle Benachrichtigungen für User (Events, Ankündigungen, etc.)
-- HINWEIS: Diese Version funktioniert OHNE event Tabelle. Event-Integration kann später hinzugefügt werden.

-- Erstelle notification_type Enum (falls noch nicht existiert)
DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM (
    'event_new',           -- Neues Event wurde erstellt
    'event_reminder',      -- Erinnerung an bevorstehendes Event
    'event_cancelled',     -- Event wurde abgesagt
    'event_updated',       -- Event wurde aktualisiert
    'announcement',        -- Admin-Ankündigung
    'achievement',         -- Achievement freigeschaltet (für Jugend)
    'level_up',           -- Level-Up (für Jugend)
    'system'              -- System-Nachricht
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Erstelle notifications Tabelle
CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,

  -- Optionale Metadaten für Links/Actions
  action_url TEXT,           -- z.B. "/events/123" zum Navigieren
  action_label TEXT,         -- z.B. "Event ansehen"

  -- Referenzen zu anderen Entities (optional, ohne FK constraint)
  event_id BIGINT,           -- Referenz zu Event (optional, ohne Foreign Key)

  -- Zeitstempel
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ,

  -- Optionale Zusatzdaten als JSON
  metadata JSONB DEFAULT '{}'
);

-- Kommentare für die Tabelle und Spalten
COMMENT ON TABLE notifications IS 'Benachrichtigungen für User (Events, Ankündigungen, Achievements)';
COMMENT ON COLUMN notifications.user_id IS 'Referenz zum Benutzer (auth.users)';
COMMENT ON COLUMN notifications.type IS 'Typ der Benachrichtigung (event_new, announcement, etc.)';
COMMENT ON COLUMN notifications.title IS 'Titel der Benachrichtigung';
COMMENT ON COLUMN notifications.message IS 'Nachrichtentext';
COMMENT ON COLUMN notifications.read IS 'Wurde die Benachrichtigung gelesen?';
COMMENT ON COLUMN notifications.action_url IS 'URL zum Navigieren (z.B. zu Event-Details)';
COMMENT ON COLUMN notifications.action_label IS 'Label für Action-Button';
COMMENT ON COLUMN notifications.event_id IS 'Referenz zu Event ID (optional)';
COMMENT ON COLUMN notifications.metadata IS 'Zusätzliche Metadaten als JSON';

-- Indizes für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_event_id ON notifications(event_id);

-- RLS (Row Level Security) Policies aktivieren
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Benutzer können nur ihre eigenen Notifications sehen
DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
CREATE POLICY "Users can read own notifications"
  ON notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Notifications als gelesen markieren
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Nur Admins können Notifications erstellen (via Service Role)
DROP POLICY IF EXISTS "Service role can insert notifications" ON notifications;
CREATE POLICY "Service role can insert notifications"
  ON notifications
  FOR INSERT
  WITH CHECK (true);  -- Service Role bypassed RLS, aber für Klarheit

-- Policy: Benutzer können ihre eigenen Notifications löschen
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
CREATE POLICY "Users can delete own notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- Funktion: Erstelle Notification für alle User
CREATE OR REPLACE FUNCTION create_notification_for_all_users(
  p_type notification_type,
  p_title TEXT,
  p_message TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_action_label TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS INTEGER AS $$
DECLARE
  rows_inserted INTEGER;
BEGIN
  -- Erstelle Notification für alle User
  INSERT INTO notifications (user_id, type, title, message, action_url, action_label, metadata)
  SELECT
    user_id,
    p_type,
    p_title,
    p_message,
    p_action_url,
    p_action_label,
    p_metadata
  FROM member
  WHERE user_id IS NOT NULL;

  GET DIAGNOSTICS rows_inserted = ROW_COUNT;
  RETURN rows_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_notification_for_all_users IS 'Erstellt eine Notification für alle User (z.B. Admin-Ankündigung)';

-- Funktion: Erstelle Notification für spezifische User
CREATE OR REPLACE FUNCTION create_notification_for_users(
  p_user_ids UUID[],
  p_type notification_type,
  p_title TEXT,
  p_message TEXT,
  p_action_url TEXT DEFAULT NULL,
  p_action_label TEXT DEFAULT NULL,
  p_event_id BIGINT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS INTEGER AS $$
DECLARE
  rows_inserted INTEGER;
  user_id_item UUID;
BEGIN
  rows_inserted := 0;

  FOREACH user_id_item IN ARRAY p_user_ids
  LOOP
    INSERT INTO notifications (user_id, type, title, message, action_url, action_label, event_id, metadata)
    VALUES (user_id_item, p_type, p_title, p_message, p_action_url, p_action_label, p_event_id, p_metadata);

    rows_inserted := rows_inserted + 1;
  END LOOP;

  RETURN rows_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_notification_for_users IS 'Erstellt eine Notification für spezifische User';

-- View: Anzahl ungelesener Notifications pro User
CREATE OR REPLACE VIEW unread_notifications_count AS
SELECT
  user_id,
  COUNT(*) as unread_count
FROM notifications
WHERE read = FALSE
GROUP BY user_id;

COMMENT ON VIEW unread_notifications_count IS 'Anzahl ungelesener Notifications pro User';

-- OPTIONAL: Event-Integration (nur ausführen wenn event Tabelle existiert)
-- Diese Sektion fügt Foreign Key Constraint und Trigger hinzu
-- Falls event Tabelle nicht existiert, einfach überspringen

-- Füge Foreign Key Constraint hinzu (nur wenn event Tabelle existiert)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'event') THEN
    -- Füge Foreign Key hinzu
    ALTER TABLE notifications
    ADD CONSTRAINT fk_notifications_event
    FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE;

    RAISE NOTICE 'Foreign Key Constraint für event_id wurde hinzugefügt';
  ELSE
    RAISE NOTICE 'event Tabelle existiert nicht - Foreign Key Constraint übersprungen';
  END IF;
END $$;

-- Erstelle Trigger für automatische Event-Notifications (nur wenn event Tabelle existiert)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'event') THEN
    -- Erstelle Function
    CREATE OR REPLACE FUNCTION notify_users_on_new_event()
    RETURNS TRIGGER AS $trigger$
    BEGIN
      -- Erstelle Notification für alle User
      INSERT INTO notifications (user_id, type, title, message, action_url, action_label, event_id)
      SELECT
        user_id,
        'event_new',
        'Neues Event: ' || NEW.title,
        CASE
          WHEN NEW.date IS NOT NULL
          THEN 'Ein neues Event wurde erstellt für den ' || TO_CHAR(NEW.date, 'DD.MM.YYYY')
          ELSE 'Ein neues Event wurde erstellt'
        END,
        '/events/' || NEW.id,
        'Event ansehen',
        NEW.id
      FROM member
      WHERE user_id IS NOT NULL;

      RETURN NEW;
    END;
    $trigger$ LANGUAGE plpgsql;

    -- Lösche alten Trigger falls vorhanden
    DROP TRIGGER IF EXISTS event_created_notification ON event;

    -- Erstelle neuen Trigger
    CREATE TRIGGER event_created_notification
      AFTER INSERT ON event
      FOR EACH ROW
      EXECUTE FUNCTION notify_users_on_new_event();

    RAISE NOTICE 'Event-Trigger wurde erstellt';
  ELSE
    RAISE NOTICE 'event Tabelle existiert nicht - Trigger übersprungen';
  END IF;
END $$;
