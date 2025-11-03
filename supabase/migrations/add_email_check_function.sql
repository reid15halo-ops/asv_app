-- Migration: Add function to check if email already exists
-- Erstellt: 2025-11-03
-- Beschreibung: RPC-Funktion für Email-Verfügbarkeitsprüfung bei der Registrierung

-- Funktion erstellen die überprüft ob eine Email bereits existiert
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = email_to_check
  );
END;
$$;

-- Kommentar hinzufügen
COMMENT ON FUNCTION check_email_exists IS 'Prüft ob eine E-Mail-Adresse bereits registriert ist. Returns true wenn E-Mail existiert, false wenn verfügbar.';

-- Grant execute permission to authenticated and anon users (für Sign-Up Check)
GRANT EXECUTE ON FUNCTION check_email_exists TO anon;
GRANT EXECUTE ON FUNCTION check_email_exists TO authenticated;
