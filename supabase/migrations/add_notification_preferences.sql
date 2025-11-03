-- Migration: Add notification_preferences table
-- Erstellt: 2025-11-03
-- Beschreibung: User-spezifische Notification-Einstellungen

-- Erstelle notification_preferences Tabelle
CREATE TABLE IF NOT EXISTS notification_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Notification Type Preferences
  enable_event_new BOOLEAN NOT NULL DEFAULT TRUE,
  enable_event_reminder BOOLEAN NOT NULL DEFAULT TRUE,
  enable_event_cancelled BOOLEAN NOT NULL DEFAULT TRUE,
  enable_event_updated BOOLEAN NOT NULL DEFAULT TRUE,
  enable_announcement BOOLEAN NOT NULL DEFAULT TRUE,
  enable_achievement BOOLEAN NOT NULL DEFAULT TRUE,
  enable_level_up BOOLEAN NOT NULL DEFAULT TRUE,
  enable_system BOOLEAN NOT NULL DEFAULT TRUE,

  -- Push Notification Settings (für zukünftige FCM Integration)
  enable_push_notifications BOOLEAN NOT NULL DEFAULT FALSE,

  -- Quiet Hours
  enable_quiet_hours BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ein User kann nur eine Preferences-Zeile haben
  UNIQUE(user_id)
);

-- Index für schnelle User-Lookups
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- RLS Policies
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users können nur ihre eigenen Preferences sehen
CREATE POLICY "Users can read own preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

-- Users können ihre eigenen Preferences erstellen
CREATE POLICY "Users can insert own preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users können ihre eigenen Preferences updaten
CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- Users können ihre eigenen Preferences löschen
CREATE POLICY "Users can delete own preferences"
  ON notification_preferences FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_preferences_updated_at();

-- Funktion zum Erstellen von Default Preferences für neue User
CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger der automatisch Preferences für neue User erstellt
CREATE TRIGGER on_auth_user_created_notification_preferences
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_default_notification_preferences();

-- Kommentare
COMMENT ON TABLE notification_preferences IS 'User-spezifische Einstellungen für Notifications';
COMMENT ON COLUMN notification_preferences.enable_push_notifications IS 'Aktiviert/Deaktiviert Push Notifications (FCM) - für zukünftige Implementierung';
COMMENT ON COLUMN notification_preferences.quiet_hours_start IS 'Start der Ruhezeit (keine Notifications)';
COMMENT ON COLUMN notification_preferences.quiet_hours_end IS 'Ende der Ruhezeit';
