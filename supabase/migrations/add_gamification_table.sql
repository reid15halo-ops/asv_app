-- Migration: Erstelle Gamification-Tabelle für XP, Level und Achievements
-- Diese Tabelle speichert Gamification-Daten für Jugend-Features

-- Erstelle gamification Tabelle
CREATE TABLE IF NOT EXISTS gamification (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  xp_points INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 1,
  total_catches INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  rank INTEGER NOT NULL DEFAULT 0,
  achievements JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Kommentare für die Spalten
COMMENT ON TABLE gamification IS 'Gamification-Daten für Jugend-Features (XP, Level, Achievements)';
COMMENT ON COLUMN gamification.user_id IS 'Referenz zum Benutzer (auth.users)';
COMMENT ON COLUMN gamification.xp_points IS 'Gesammelte Experience Points';
COMMENT ON COLUMN gamification.level IS 'Aktuelles Level (berechnet aus XP)';
COMMENT ON COLUMN gamification.total_catches IS 'Gesamtanzahl erfasster Fänge';
COMMENT ON COLUMN gamification.streak IS 'Anzahl aufeinanderfolgender Tage mit Aktivität';
COMMENT ON COLUMN gamification.rank IS 'Platzierung im Ranking';
COMMENT ON COLUMN gamification.achievements IS 'JSON Array mit freigeschalteten Achievements';

-- Index für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_gamification_user_id ON gamification(user_id);
CREATE INDEX IF NOT EXISTS idx_gamification_xp_points ON gamification(xp_points DESC);
CREATE INDEX IF NOT EXISTS idx_gamification_level ON gamification(level DESC);

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_gamification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gamification_updated_at
  BEFORE UPDATE ON gamification
  FOR EACH ROW
  EXECUTE FUNCTION update_gamification_updated_at();

-- RLS (Row Level Security) Policies
ALTER TABLE gamification ENABLE ROW LEVEL SECURITY;

-- Policy: Benutzer können ihre eigenen Daten lesen
CREATE POLICY "Users can read own gamification data"
  ON gamification
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Daten erstellen
CREATE POLICY "Users can create own gamification data"
  ON gamification
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Daten aktualisieren
CREATE POLICY "Users can update own gamification data"
  ON gamification
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Optional: View für Leaderboard (Top 100)
CREATE OR REPLACE VIEW leaderboard AS
SELECT
  g.user_id,
  m.display_name,
  g.xp_points,
  g.level,
  g.total_catches,
  g.streak,
  ROW_NUMBER() OVER (ORDER BY g.xp_points DESC) as rank
FROM gamification g
LEFT JOIN member m ON m.user_id = g.user_id
ORDER BY g.xp_points DESC
LIMIT 100;

COMMENT ON VIEW leaderboard IS 'Top 100 Spieler im Leaderboard sortiert nach XP';
