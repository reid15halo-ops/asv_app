-- Migration: Erstelle Events-Tabelle für Vereinskalender
-- Diese Tabelle speichert Events mit Kategorisierung und Mehrfachauswahl-Support

-- Erstelle events Tabelle
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  location TEXT,
  type TEXT NOT NULL DEFAULT 'sonstiges',
  target_groups TEXT[] NOT NULL DEFAULT ARRAY['alle'],
  is_all_day BOOLEAN NOT NULL DEFAULT false,
  max_participants INTEGER,
  current_participants INTEGER NOT NULL DEFAULT 0,
  image_url TEXT,
  organizer_id UUID REFERENCES auth.users(id),
  organizer_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_event_type CHECK (type IN (
    'arbeitseinsatz',
    'feier',
    'sitzung',
    'training',
    'wettkampf',
    'ausflug',
    'kurs',
    'sonstiges'
  )),
  CONSTRAINT valid_dates CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT valid_participants CHECK (
    max_participants IS NULL OR
    (max_participants >= 0 AND current_participants <= max_participants)
  )
);

-- Kommentare für die Spalten
COMMENT ON TABLE events IS 'Vereins-Events und Termine mit Kategorisierung';
COMMENT ON COLUMN events.title IS 'Event-Titel';
COMMENT ON COLUMN events.description IS 'Event-Beschreibung';
COMMENT ON COLUMN events.start_date IS 'Start-Datum und -Zeit';
COMMENT ON COLUMN events.end_date IS 'End-Datum und -Zeit (optional)';
COMMENT ON COLUMN events.location IS 'Veranstaltungsort';
COMMENT ON COLUMN events.type IS 'Event-Typ (arbeitseinsatz, feier, sitzung, etc.)';
COMMENT ON COLUMN events.target_groups IS 'Zielgruppen-Array (jugend, aktive, senioren, alle)';
COMMENT ON COLUMN events.is_all_day IS 'Ganztägiges Event (keine Uhrzeiten)';
COMMENT ON COLUMN events.max_participants IS 'Maximale Teilnehmerzahl (optional)';
COMMENT ON COLUMN events.current_participants IS 'Aktuelle Teilnehmerzahl';
COMMENT ON COLUMN events.image_url IS 'URL zum Event-Bild';
COMMENT ON COLUMN events.organizer_id IS 'ID des Organisators';
COMMENT ON COLUMN events.organizer_name IS 'Name des Organisators';

-- Indizes für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_target_groups ON events USING GIN(target_groups);
CREATE INDEX IF NOT EXISTS idx_events_organizer_id ON events(organizer_id);

-- Index für Datum-Bereich-Abfragen
CREATE INDEX IF NOT EXISTS idx_events_date_range ON events(start_date, end_date);

-- Trigger für updated_at
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

-- RLS (Row Level Security) Policies
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Policy: Jeder kann Events lesen
CREATE POLICY "Anyone can read events"
  ON events
  FOR SELECT
  USING (true);

-- Policy: Admins können Events erstellen
CREATE POLICY "Admins can create events"
  ON events
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM member WHERE member.user_metadata->>'is_admin' = 'true'
    )
    OR
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = auth.users.id
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Policy: Admins und Organisatoren können Events aktualisieren
CREATE POLICY "Admins and organizers can update events"
  ON events
  FOR UPDATE
  USING (
    auth.uid() = organizer_id
    OR
    auth.uid() IN (
      SELECT user_id FROM member WHERE member.user_metadata->>'is_admin' = 'true'
    )
    OR
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = auth.users.id
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Policy: Admins können Events löschen
CREATE POLICY "Admins can delete events"
  ON events
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT user_id FROM member WHERE member.user_metadata->>'is_admin' = 'true'
    )
    OR
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = auth.users.id
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Erstelle event_participants Tabelle für Anmeldungen
CREATE TABLE IF NOT EXISTS event_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  member_id INTEGER REFERENCES member(id) ON DELETE CASCADE,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'registered',
  notes TEXT,
  UNIQUE(event_id, user_id),
  CONSTRAINT valid_participant_status CHECK (status IN (
    'registered',
    'confirmed',
    'cancelled',
    'attended'
  ))
);

COMMENT ON TABLE event_participants IS 'Event-Teilnehmer und Anmeldungen';
COMMENT ON COLUMN event_participants.status IS 'Anmeldestatus (registered, confirmed, cancelled, attended)';

-- Indizes für Teilnehmer
CREATE INDEX IF NOT EXISTS idx_event_participants_event_id ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user_id ON event_participants(user_id);

-- RLS für Teilnehmer
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- Policy: Jeder kann seine eigenen Anmeldungen sehen
CREATE POLICY "Users can read own participations"
  ON event_participants
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Admins können alle Anmeldungen sehen
CREATE POLICY "Admins can read all participations"
  ON event_participants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = auth.users.id
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Policy: Benutzer können sich selbst anmelden
CREATE POLICY "Users can register for events"
  ON event_participants
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Anmeldungen aktualisieren
CREATE POLICY "Users can update own participations"
  ON event_participants
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Anmeldungen löschen
CREATE POLICY "Users can delete own participations"
  ON event_participants
  FOR DELETE
  USING (auth.uid() = user_id);

-- Funktion um current_participants zu aktualisieren
CREATE OR REPLACE FUNCTION update_event_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE events
    SET current_participants = (
      SELECT COUNT(*) FROM event_participants
      WHERE event_id = NEW.event_id
      AND status IN ('registered', 'confirmed', 'attended')
    )
    WHERE id = NEW.event_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE events
    SET current_participants = (
      SELECT COUNT(*) FROM event_participants
      WHERE event_id = OLD.event_id
      AND status IN ('registered', 'confirmed', 'attended')
    )
    WHERE id = OLD.event_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE events
    SET current_participants = (
      SELECT COUNT(*) FROM event_participants
      WHERE event_id = NEW.event_id
      AND status IN ('registered', 'confirmed', 'attended')
    )
    WHERE id = NEW.event_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger für automatische Teilnehmerzahl-Aktualisierung
CREATE TRIGGER update_participant_count
  AFTER INSERT OR UPDATE OR DELETE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_event_participant_count();

-- View für kommende Events
CREATE OR REPLACE VIEW upcoming_events AS
SELECT *
FROM events
WHERE start_date >= NOW()
ORDER BY start_date ASC;

COMMENT ON VIEW upcoming_events IS 'Kommende Events sortiert nach Datum';

-- View für Events nach Zielgruppe
CREATE OR REPLACE FUNCTION events_for_group(target_group TEXT)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  location TEXT,
  type TEXT,
  target_groups TEXT[],
  is_all_day BOOLEAN,
  max_participants INTEGER,
  current_participants INTEGER,
  image_url TEXT,
  organizer_id UUID,
  organizer_name TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.description,
    e.start_date,
    e.end_date,
    e.location,
    e.type,
    e.target_groups,
    e.is_all_day,
    e.max_participants,
    e.current_participants,
    e.image_url,
    e.organizer_id,
    e.organizer_name,
    e.created_at,
    e.updated_at
  FROM events e
  WHERE 'alle' = ANY(e.target_groups)
     OR target_group = ANY(e.target_groups)
  ORDER BY e.start_date ASC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION events_for_group IS 'Gibt Events für eine bestimmte Zielgruppe zurück';
