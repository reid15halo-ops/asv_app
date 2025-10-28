-- Migration: Füge member_group Spalte zur member Tabelle hinzu
-- Diese Migration erweitert die member Tabelle um ein Feld für die Benutzergruppe

-- Füge die member_group Spalte hinzu
ALTER TABLE member
ADD COLUMN IF NOT EXISTS member_group TEXT
DEFAULT 'aktive'
CHECK (member_group IN ('jugend', 'aktive', 'senioren'));

-- Kommentar für die Spalte
COMMENT ON COLUMN member.member_group IS 'Benutzergruppe: jugend, aktive oder senioren';

-- Optional: Erstelle einen Index für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_member_group ON member(member_group);

-- Optional: Aktualisiere bestehende Einträge basierend auf Logik
-- Beispiel: Alle bestehenden Mitglieder werden standardmäßig als "aktive" gesetzt
UPDATE member
SET member_group = 'aktive'
WHERE member_group IS NULL;
