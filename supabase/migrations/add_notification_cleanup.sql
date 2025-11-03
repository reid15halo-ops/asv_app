-- Migration: Add notification cleanup function
-- Erstellt: 2025-11-03
-- Beschreibung: Automatisches Löschen alter gelesener Notifications

-- Funktion zum Löschen alter Notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Lösche gelesene Notifications die älter als 90 Tage sind
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '90 days'
    AND read = TRUE;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  -- Log die Anzahl der gelöschten Notifications
  RAISE NOTICE 'Cleanup: % old notifications deleted', deleted_count;

  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_old_notifications IS 'Löscht gelesene Notifications die älter als 90 Tage sind. Gibt die Anzahl der gelöschten Notifications zurück.';

-- Funktion für aggressive Cleanup (löscht alle Notifications älter als 180 Tage, auch ungelesene)
CREATE OR REPLACE FUNCTION cleanup_all_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Lösche ALLE Notifications die älter als 180 Tage sind
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '180 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RAISE NOTICE 'Aggressive cleanup: % old notifications deleted', deleted_count;

  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_all_old_notifications IS 'Löscht ALLE Notifications (auch ungelesene) die älter als 180 Tage sind. Nur für administrative Zwecke.';

-- RPC Permissions (nur für authenticated users mit admin role)
-- Die Funktion kann manuell aufgerufen werden oder via cron job
GRANT EXECUTE ON FUNCTION cleanup_old_notifications TO postgres;
GRANT EXECUTE ON FUNCTION cleanup_all_old_notifications TO postgres;

-- Optional: Erstelle eine View für Cleanup-Statistiken
CREATE OR REPLACE VIEW notification_cleanup_stats AS
SELECT
  COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days' AND read = TRUE) as deletable_read,
  COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '180 days') as deletable_all,
  COUNT(*) FILTER (WHERE read = TRUE) as total_read,
  COUNT(*) as total_notifications,
  AVG(EXTRACT(EPOCH FROM (NOW() - created_at)) / 86400)::INTEGER as avg_age_days
FROM notifications;

COMMENT ON VIEW notification_cleanup_stats IS 'Statistiken über löschbare Notifications';

-- Optional: Erstelle einen scheduled job mit pg_cron (falls pg_cron extension aktiviert ist)
-- HINWEIS: pg_cron muss in Supabase aktiviert werden
-- Dieser Job läuft jeden Tag um 3 Uhr morgens
/*
-- Aktiviere pg_cron extension (einmalig als superuser)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule cleanup job (läuft täglich um 3:00 Uhr)
SELECT cron.schedule(
  'cleanup-old-notifications',
  '0 3 * * *',  -- Cron expression: täglich um 3:00
  'SELECT cleanup_old_notifications();'
);
*/

-- Hinweis für manuelle Ausführung:
-- SELECT cleanup_old_notifications(); -- Löscht gelesene Notifications älter als 90 Tage
-- SELECT cleanup_all_old_notifications(); -- Löscht ALLE Notifications älter als 180 Tage
-- SELECT * FROM notification_cleanup_stats; -- Zeigt Statistiken
