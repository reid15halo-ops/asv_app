/// WordPress Sync Configuration
///
/// WICHTIG:
/// 1. Kopiere diese Datei zu: lib/config/wordpress_config.dart
/// 2. Fülle deine echten WordPress-Credentials ein
/// 3. Füge wordpress_config.dart zur .gitignore hinzu
///
/// Beispiel .gitignore:
///   lib/config/wordpress_config.dart
///
class WordPressConfig {
  /// WordPress Installation URL (ohne trailing slash)
  /// Beispiel: 'https://asvgrossostheim.de'
  static const String wordpressUrl = 'https://deine-domain.de';

  /// WordPress Username
  /// Der User benötigt Rechte zum Erstellen/Bearbeiten von Events
  static const String username = 'dein-username';

  /// WordPress Application Password
  ///
  /// Generierung:
  /// 1. WordPress Admin > Benutzer > Profil
  /// 2. Scrolle zu "Anwendungspasswörter"
  /// 3. Name: "ASV Flutter App"
  /// 4. "Neues Anwendungspasswort hinzufügen"
  /// 5. Passwort kopieren (Format: "xxxx xxxx xxxx xxxx xxxx xxxx")
  ///
  /// Beispiel: 'a1B2 c3D4 e5F6 g7H8 i9J0 k1L2'
  static const String applicationPassword = 'xxxx xxxx xxxx xxxx xxxx xxxx';

  /// Optional: Google Maps API Key aus WordPress
  /// (Falls du denselben Key in der App verwenden möchtest)
  static const String googleMapsApiKey = 'AIzaSyDNsicAsP6-VuGtAb1O9riI3oc_NOb7IOU';
}
