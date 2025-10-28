# Benutzergruppen-Feature (Jugend, Aktive, Senioren)

## Übersicht

Dieses Feature ermöglicht unterschiedliche Layout-Einstellungen für verschiedene Mitgliedergruppen:
- **Jugend** - Frische, lebhafte Farben (Cyan/Türkis)
- **Aktive** - Standard ASV-Farben (Schwarz/Grau)
- **Senioren** - Ruhige, warme Farben (Braun)

## Implementierte Komponenten

### 1. Datenmodell
- **`lib/models/member_group.dart`** - Enum für Benutzergruppen mit Display-Namen und Logo-Zuordnung

### 2. Theme-System
- **`theme/theme.dart`** - Erweitert um gruppenspezifische Farbschemata
  - `buildLightTheme(MemberGroup?)` - Erstellt Light Theme basierend auf Gruppe
  - `buildDarkTheme(MemberGroup?)` - Erstellt Dark Theme basierend auf Gruppe

### 3. State Management
- **`lib/providers/member_group_provider.dart`** - Riverpod Provider für Benutzergruppen-Verwaltung
  - `loadMemberGroup()` - Lädt Gruppe aus Datenbank oder user_metadata
  - `setMemberGroup(MemberGroup)` - Setzt Gruppe manuell (für Testing)
  - `reset()` - Setzt Gruppe zurück

### 4. Repository
- **`lib/repositories/member_repository.dart`** - Datenzugriff für Mitglieder
  - `getMemberGroupForUser(String userId)` - Liest Gruppe aus DB
  - `updateMemberGroup(int memberId, MemberGroup)` - Aktualisiert Gruppe

### 5. UI-Anpassungen
- **`features/dashboard/dashboard_screen.dart`** - Dashboard zeigt gruppenspezifisches Logo und Begrüßung
- **`main.dart`** - App verwendet dynamisches Theme basierend auf Benutzergruppe

### 6. Admin-Tools
- **`features/admin/member_group_admin_screen.dart`** - Test-Screen für Entwickler
  - Wechseln zwischen Gruppen
  - Vorschau der Farben
  - Erreichbar unter `/admin/member-groups`

### 7. Datenbank
- **`supabase/migrations/add_member_group.sql`** - Migration zum Hinzufügen der `member_group` Spalte

## Setup-Anleitung

### 1. Datenbank-Migration ausführen

```bash
# Mit Supabase CLI
supabase db push

# Oder SQL direkt in Supabase Dashboard ausführen
```

Die Migration fügt folgendes hinzu:
- Spalte `member_group` zur `member` Tabelle
- CHECK Constraint für gültige Werte: 'jugend', 'aktive', 'senioren'
- Index für schnellere Abfragen
- Standard-Wert: 'aktive'

### 2. Benutzergruppe setzen

Es gibt zwei Möglichkeiten, die Benutzergruppe zu setzen:

#### Option A: In der Datenbank (empfohlen)
```sql
UPDATE member
SET member_group = 'jugend'  -- oder 'aktive' oder 'senioren'
WHERE user_id = '<user-uuid>';
```

#### Option B: In user_metadata (Supabase Auth)
```javascript
// Beim Sign-Up oder über Admin API
await supabase.auth.admin.updateUserById(userId, {
  user_metadata: { member_group: 'jugend' }
});
```

### 3. Testing

Navigiere zu `/admin/member-groups` um:
- Verschiedene Gruppen-Layouts zu testen
- Farben in Echtzeit zu sehen
- Zwischen Gruppen zu wechseln (nur in Dev-Modus)

## Verwendung im Code

### Theme automatisch laden
```dart
// main.dart - bereits implementiert
final memberGroup = ref.watch(memberGroupProvider);
theme: buildLightTheme(memberGroup),
```

### Benutzergruppe in Widget verwenden
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberGroup = ref.watch(memberGroupProvider);

    // Logo basierend auf Gruppe
    final logo = memberGroup?.logoAsset ?? 'assets/logos/asv_logo.png';

    // Name der Gruppe
    final groupName = memberGroup?.displayName ?? 'Mitglied';

    return Image.asset(logo);
  }
}
```

### Benutzergruppe beim Login laden
```dart
// Wird automatisch im DashboardScreen aufgerufen
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(memberGroupProvider.notifier).loadMemberGroup();
  });
}
```

## Farbschemata

### Jugend
- Seed Color: `#00BCD4` (Cyan/Türkis)
- Charakteristik: Frisch, modern, energiegeladen

### Aktive (Standard)
- Seed Color: `#0B0B0B` (Schwarz)
- Charakteristik: Klassisch, vereinstypisch

### Senioren
- Seed Color: `#8D6E63` (Warmes Braun)
- Charakteristik: Ruhig, warm, gut lesbar

## Logo-Zuordnung

- **Jugend**: `assets/logos/jugend_logo.png`
- **Aktive**: `assets/logos/asv_logo.png`
- **Senioren**: `assets/logos/asv_logo.png` (kann angepasst werden)

## Erweiterungsmöglichkeiten

### Weitere Gruppen hinzufügen
1. Enum in `member_group.dart` erweitern
2. Theme in `theme.dart` hinzufügen
3. Logo-Asset zuordnen
4. Datenbank-CHECK Constraint anpassen

### Gruppenspezifische Features
```dart
// Beispiel: Verschiedene Features pro Gruppe
if (memberGroup == MemberGroup.jugend) {
  // Spezielle Jugend-Features
} else if (memberGroup == MemberGroup.senioren) {
  // Größere Schrift, vereinfachte UI
}
```

### Persistenz verbessern
- Cached Preferences für Offline-Nutzung
- Automatisches Reload bei Auth-State-Änderung

## Troubleshooting

### Theme ändert sich nicht
- Prüfe ob Provider korrekt initialisiert ist: `ProviderScope` in main.dart
- Prüfe ob `loadMemberGroup()` aufgerufen wurde
- Prüfe Supabase-Verbindung und member-Tabelle

### Gruppe wird nicht aus DB geladen
- Prüfe ob Migration ausgeführt wurde: `SELECT member_group FROM member LIMIT 1;`
- Prüfe ob user_id korrekt verknüpft ist
- Prüfe Logs in `MemberGroupNotifier.loadMemberGroup()`

### Logo wird nicht angezeigt
- Prüfe ob Asset in `pubspec.yaml` registriert ist
- Prüfe Dateipfad in `member_group.dart`
- Nutze `errorBuilder` für Fallback-Anzeige

## API-Referenz

### MemberGroup Enum
```dart
MemberGroup.jugend    // Jugend-Gruppe
MemberGroup.aktive    // Aktive-Gruppe (Standard)
MemberGroup.senioren  // Senioren-Gruppe

// Properties
.value        // String für DB: 'jugend', 'aktive', 'senioren'
.displayName  // Anzeigename: 'Jugend', 'Aktive', 'Senioren'
.logoAsset    // Asset-Pfad zum Logo
```

### MemberGroupNotifier
```dart
ref.read(memberGroupProvider.notifier).loadMemberGroup()     // Lädt aus DB
ref.read(memberGroupProvider.notifier).setMemberGroup(group) // Setzt manuell
ref.read(memberGroupProvider.notifier).reset()                // Reset
ref.watch(memberGroupProvider)                                // Aktueller Wert
```

### MemberRepository
```dart
final repo = MemberRepository(supabase);
await repo.getMemberGroupForUser(userId)           // Gibt MemberGroup zurück
await repo.updateMemberGroup(memberId, group)      // Aktualisiert in DB
```
