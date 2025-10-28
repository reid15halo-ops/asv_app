/// Enum für Mitgliedergruppen (Jugend, Aktive, Senioren)
enum MemberGroup {
  jugend('jugend', 'Jugend'),
  aktive('aktive', 'Aktive'),
  senioren('senioren', 'Senioren');

  const MemberGroup(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Konvertiert einen String-Wert aus der Datenbank zum Enum
  static MemberGroup fromString(String? value) {
    if (value == null) return MemberGroup.aktive; // Default
    switch (value.toLowerCase()) {
      case 'jugend':
        return MemberGroup.jugend;
      case 'aktive':
        return MemberGroup.aktive;
      case 'senioren':
        return MemberGroup.senioren;
      default:
        return MemberGroup.aktive; // Fallback
    }
  }

  /// Gibt das entsprechende Logo-Asset für die Gruppe zurück
  String get logoAsset {
    switch (this) {
      case MemberGroup.jugend:
        return 'assets/logos/jugend_logo.png';
      case MemberGroup.aktive:
        return 'assets/logos/asv_logo.png';
      case MemberGroup.senioren:
        return 'assets/logos/asv_logo.png'; // Kann später angepasst werden
    }
  }
}
