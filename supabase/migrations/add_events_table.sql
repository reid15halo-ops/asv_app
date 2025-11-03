-- Migration: Add Events Table with WordPress Sync
-- Erstellt: 2025-11-03
-- Beschreibung: Event-System mit bidirektionaler WordPress-Synchronisation

-- Events Tabelle
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,

  -- Event-Details
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,

  -- Zeitangaben
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  all_day BOOLEAN NOT NULL DEFAULT FALSE,

  -- Organisation
  organizer TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  max_participants INTEGER,

  -- Status
  status TEXT NOT NULL DEFAULT 'published', -- 'draft', 'published', 'cancelled'
  is_public BOOLEAN NOT NULL DEFAULT TRUE,

  -- WordPress Sync
  wordpress_id BIGINT UNIQUE, -- ID des Events in WordPress
  wordpress_url TEXT,          -- URL zum Event in WordPress
  last_synced_at TIMESTAMPTZ,  -- Letzter Sync-Zeitpunkt
  sync_source TEXT DEFAULT 'app', -- 'app' oder 'wordpress'

  -- Metadaten
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Zusätzliche Daten als JSON
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Indizes für Performance
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_wordpress_id ON events(wordpress_id);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_public ON events(is_public) WHERE is_public = TRUE;

-- Volltextsuche für Events
CREATE INDEX IF NOT EXISTS idx_events_search ON events USING gin(
  to_tsvector('german', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(location, ''))
);

-- RLS Policies
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Jeder kann öffentliche Events sehen
CREATE POLICY "Anyone can read public events"
  ON events FOR SELECT
  USING (is_public = TRUE OR auth.uid() = created_by);

-- Nur authentifizierte User können Events erstellen
CREATE POLICY "Authenticated users can create events"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Nur Creator oder Admins können Events bearbeiten
CREATE POLICY "Creators can update own events"
  ON events FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by);

-- Nur Creator oder Admins können Events löschen
CREATE POLICY "Creators can delete own events"
  ON events FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- Admin-Policy (später über member.role = 'admin')
CREATE POLICY "Admins can manage all events"
  ON events FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM member
      WHERE member.user_id = auth.uid()
        AND member.role = 'admin'
    )
  );

-- Event Participants Tabelle (für Anmeldungen)
CREATE TABLE IF NOT EXISTS event_participants (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  status TEXT NOT NULL DEFAULT 'registered', -- 'registered', 'attended', 'cancelled'
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,

  UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user ON event_participants(user_id);

-- RLS für Participants
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view event participants"
  ON event_participants FOR SELECT
  USING (TRUE);

CREATE POLICY "Users can register for events"
  ON event_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own registrations"
  ON event_participants FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can cancel own registrations"
  ON event_participants FOR DELETE
  USING (auth.uid() = user_id);

-- Updated_at Trigger
CREATE OR REPLACE FUNCTION update_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_events_updated_at();

-- Notification bei neuem Event
CREATE OR REPLACE FUNCTION notify_users_on_new_event()
RETURNS TRIGGER AS $$
BEGIN
  -- Nur bei öffentlichen Events
  IF NEW.is_public AND NEW.status = 'published' THEN
    INSERT INTO notifications (user_id, type, title, message, action_url, action_label, event_id)
    SELECT
      m.user_id,
      'event_new',
      'Neues Event: ' || NEW.title,
      'Am ' || to_char(NEW.start_date, 'DD.MM.YYYY') ||
      CASE WHEN NEW.location IS NOT NULL THEN ' in ' || NEW.location ELSE '' END,
      '/events/' || NEW.id,
      'Details ansehen',
      NEW.id
    FROM member m
    WHERE m.user_id IS NOT NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_event_created_notify
  AFTER INSERT ON events
  FOR EACH ROW
  EXECUTE FUNCTION notify_users_on_new_event();

-- View: Upcoming Events
CREATE OR REPLACE VIEW upcoming_events AS
SELECT
  e.*,
  COUNT(ep.id) as participant_count,
  CASE
    WHEN e.max_participants IS NOT NULL
    THEN e.max_participants - COUNT(ep.id)
    ELSE NULL
  END as spots_available
FROM events e
LEFT JOIN event_participants ep ON e.id = ep.event_id AND ep.status = 'registered'
WHERE e.status = 'published'
  AND e.is_public = TRUE
  AND e.start_date >= NOW()
GROUP BY e.id
ORDER BY e.start_date ASC;

-- View: Past Events
CREATE OR REPLACE VIEW past_events AS
SELECT
  e.*,
  COUNT(ep.id) as participant_count
FROM events e
LEFT JOIN event_participants ep ON e.id = ep.event_id AND ep.status = 'attended'
WHERE e.status = 'published'
  AND e.is_public = TRUE
  AND e.start_date < NOW()
GROUP BY e.id
ORDER BY e.start_date DESC;

-- Kommentare
COMMENT ON TABLE events IS 'Event-/Kalender-System mit WordPress-Synchronisation';
COMMENT ON COLUMN events.wordpress_id IS 'ID des Events in WordPress für Synchronisation';
COMMENT ON COLUMN events.sync_source IS 'Ursprung des Events: app oder wordpress';
COMMENT ON COLUMN events.last_synced_at IS 'Letzter Synchronisations-Zeitpunkt';

-- WordPress Sync Log Tabelle
CREATE TABLE IF NOT EXISTS wordpress_sync_log (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  sync_direction TEXT NOT NULL, -- 'to_wordpress' oder 'from_wordpress'
  status TEXT NOT NULL, -- 'success', 'failed', 'conflict'
  error_message TEXT,
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_sync_log_event ON wordpress_sync_log(event_id);
CREATE INDEX IF NOT EXISTS idx_sync_log_synced_at ON wordpress_sync_log(synced_at);

COMMENT ON TABLE wordpress_sync_log IS 'Log für WordPress-Synchronisation';
