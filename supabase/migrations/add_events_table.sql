-- Migration: Erstelle Event-Tabelle für Vereins-Events
-- Diese Tabelle speichert Events (Meetings, Turniere, Training, etc.)

-- Erstelle event Tabelle
CREATE TABLE IF NOT EXISTS event (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  event_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  location TEXT,
  max_participants INTEGER,
  registration_required BOOLEAN NOT NULL DEFAULT false,
  registration_deadline TIMESTAMPTZ,
  event_type TEXT NOT NULL DEFAULT 'meeting',
  status TEXT NOT NULL DEFAULT 'upcoming',
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT event_type_check CHECK (event_type IN ('meeting', 'tournament', 'training', 'social', 'other')),
  CONSTRAINT event_status_check CHECK (status IN ('upcoming', 'cancelled', 'completed'))
);

-- Kommentare für die Spalten
COMMENT ON TABLE event IS 'Vereins-Events (Meetings, Turniere, Training, etc.)';
COMMENT ON COLUMN event.title IS 'Event-Titel';
COMMENT ON COLUMN event.description IS 'Event-Beschreibung (optional)';
COMMENT ON COLUMN event.event_date IS 'Startdatum und -uhrzeit des Events';
COMMENT ON COLUMN event.end_date IS 'Enddatum und -uhrzeit des Events (optional)';
COMMENT ON COLUMN event.location IS 'Veranstaltungsort';
COMMENT ON COLUMN event.max_participants IS 'Maximale Teilnehmerzahl (NULL = unbegrenzt)';
COMMENT ON COLUMN event.registration_required IS 'Anmeldung erforderlich?';
COMMENT ON COLUMN event.registration_deadline IS 'Anmeldeschluss (optional)';
COMMENT ON COLUMN event.event_type IS 'Event-Typ (meeting, tournament, training, social, other)';
COMMENT ON COLUMN event.status IS 'Event-Status (upcoming, cancelled, completed)';
COMMENT ON COLUMN event.created_by IS 'Erstellt von (User-ID)';

-- Indizes für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_event_event_date ON event(event_date DESC);
CREATE INDEX IF NOT EXISTS idx_event_status ON event(status);
CREATE INDEX IF NOT EXISTS idx_event_type ON event(event_type);
CREATE INDEX IF NOT EXISTS idx_event_created_by ON event(created_by);

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_event_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_updated_at
  BEFORE UPDATE ON event
  FOR EACH ROW
  EXECUTE FUNCTION update_event_updated_at();

-- RLS (Row Level Security) Policies
ALTER TABLE event ENABLE ROW LEVEL SECURITY;

-- Policy: Alle können Events lesen
CREATE POLICY "Everyone can read events"
  ON event
  FOR SELECT
  USING (true);

-- Policy: Nur Admins können Events erstellen
-- (TODO: Anpassen wenn Admin-Role definiert ist, vorerst alle authentifizierten User)
CREATE POLICY "Authenticated users can create events"
  ON event
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: Nur Ersteller können Events aktualisieren
CREATE POLICY "Event creators can update own events"
  ON event
  FOR UPDATE
  USING (auth.uid() = created_by);

-- Policy: Nur Ersteller können Events löschen
CREATE POLICY "Event creators can delete own events"
  ON event
  FOR DELETE
  USING (auth.uid() = created_by);

-- ========== Event Registrations Tabelle ==========

CREATE TABLE IF NOT EXISTS event_registration (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'registered',
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE(event_id, user_id),
  CONSTRAINT registration_status_check CHECK (status IN ('registered', 'cancelled', 'attended'))
);

COMMENT ON TABLE event_registration IS 'Event-Anmeldungen';
COMMENT ON COLUMN event_registration.event_id IS 'Referenz zum Event';
COMMENT ON COLUMN event_registration.user_id IS 'Angemeldeter User';
COMMENT ON COLUMN event_registration.status IS 'Status (registered, cancelled, attended)';
COMMENT ON COLUMN event_registration.notes IS 'Notizen zur Anmeldung (optional)';

-- Indizes
CREATE INDEX IF NOT EXISTS idx_event_registration_event_id ON event_registration(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registration_user_id ON event_registration(user_id);
CREATE INDEX IF NOT EXISTS idx_event_registration_status ON event_registration(status);

-- RLS für event_registration
ALTER TABLE event_registration ENABLE ROW LEVEL SECURITY;

-- Policy: User können eigene Registrierungen sehen
CREATE POLICY "Users can read own registrations"
  ON event_registration
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Event-Ersteller können alle Registrierungen ihres Events sehen
CREATE POLICY "Event creators can read event registrations"
  ON event_registration
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM event
      WHERE event.id = event_registration.event_id
      AND event.created_by = auth.uid()
    )
  );

-- Policy: User können sich selbst anmelden
CREATE POLICY "Users can register for events"
  ON event_registration
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: User können eigene Registrierung aktualisieren (z.B. stornieren)
CREATE POLICY "Users can update own registrations"
  ON event_registration
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: User können eigene Registrierung löschen
CREATE POLICY "Users can delete own registrations"
  ON event_registration
  FOR DELETE
  USING (auth.uid() = user_id);

-- ========== Foreign Key für notifications.event_id ==========

-- Füge Foreign Key Constraint hinzu (falls notifications Tabelle existiert)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') THEN
    ALTER TABLE notifications
    ADD CONSTRAINT notifications_event_id_fkey
    FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ========== Views & Helper Functions ==========

-- View: Upcoming Events mit Registrierungs-Count
CREATE OR REPLACE VIEW upcoming_events AS
SELECT
  e.*,
  COUNT(er.id) FILTER (WHERE er.status = 'registered') as registered_count,
  CASE
    WHEN e.max_participants IS NOT NULL
    THEN e.max_participants - COUNT(er.id) FILTER (WHERE er.status = 'registered')
    ELSE NULL
  END as available_spots
FROM event e
LEFT JOIN event_registration er ON er.event_id = e.id
WHERE e.status = 'upcoming' AND e.event_date > NOW()
GROUP BY e.id
ORDER BY e.event_date ASC;

COMMENT ON VIEW upcoming_events IS 'Anstehende Events mit Anzahl Anmeldungen und verfügbaren Plätzen';

-- View: User's registered events
CREATE OR REPLACE VIEW user_events AS
SELECT
  e.*,
  er.status as registration_status,
  er.registered_at,
  er.notes as registration_notes
FROM event e
INNER JOIN event_registration er ON er.event_id = e.id
WHERE er.user_id = auth.uid()
AND e.status = 'upcoming'
ORDER BY e.event_date ASC;

COMMENT ON VIEW user_events IS 'Events für die der aktuelle User angemeldet ist';

-- Function: Registriere User für Event (mit Prüfung auf max_participants)
CREATE OR REPLACE FUNCTION register_for_event(
  p_event_id BIGINT,
  p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_max_participants INTEGER;
  v_current_count INTEGER;
  v_registration_deadline TIMESTAMPTZ;
BEGIN
  -- Hole Event-Details
  SELECT max_participants, registration_deadline
  INTO v_max_participants, v_registration_deadline
  FROM event
  WHERE id = p_event_id AND status = 'upcoming';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event nicht gefunden oder nicht verfügbar';
  END IF;

  -- Prüfe Anmeldeschluss
  IF v_registration_deadline IS NOT NULL AND v_registration_deadline < NOW() THEN
    RAISE EXCEPTION 'Anmeldeschluss überschritten';
  END IF;

  -- Prüfe max_participants
  IF v_max_participants IS NOT NULL THEN
    SELECT COUNT(*) INTO v_current_count
    FROM event_registration
    WHERE event_id = p_event_id AND status = 'registered';

    IF v_current_count >= v_max_participants THEN
      RAISE EXCEPTION 'Event ist bereits ausgebucht';
    END IF;
  END IF;

  -- Registriere User
  INSERT INTO event_registration (event_id, user_id, notes)
  VALUES (p_event_id, auth.uid(), p_notes)
  ON CONFLICT (event_id, user_id) DO UPDATE
  SET status = 'registered', cancelled_at = NULL, notes = p_notes;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION register_for_event IS 'Registriert aktuellen User für ein Event (mit Validierung)';

-- Function: Storniere Event-Registrierung
CREATE OR REPLACE FUNCTION cancel_event_registration(p_event_id BIGINT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE event_registration
  SET status = 'cancelled', cancelled_at = NOW()
  WHERE event_id = p_event_id AND user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Registrierung nicht gefunden';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cancel_event_registration IS 'Storniert Event-Registrierung des aktuellen Users';
