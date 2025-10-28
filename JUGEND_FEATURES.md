# Jugend-Features - Modernes Design & Gamification

## Übersicht

Das Jugend-Layout ist speziell für junge Vereinsmitglieder designt und unterscheidet sich **stark** von den anderen Modi (Aktive/Senioren). Es bietet:

- 🎨 **Moderne Farbverläufe** (Gradients) in Cyan, Pink und Lila
- 🎮 **Gamification** mit XP, Levels und Achievements
- ✨ **Animationen** und flüssige Übergänge
- 📱 **Modernes UI** mit großen, runden Buttons und Cards
- 🏆 **Leaderboards** und Ranglisten
- 🔥 **Streak-System** für tägliche Aktivität

## Implementierte Features

### 1. Visuelles Design

#### Farbschema
```dart
// Hauptfarben
Primary: #00BCD4 (Cyan/Türkis)
Secondary: #FF4081 (Pink)
Tertiary: #7C4DFF (Lila)
Success: #00C853 (Grün)

// Farbverläufe
- Primary Gradient: Cyan → Hellcyan
- Accent Gradient: Pink → Hellpink
- Purple Gradient: Lila → Helllila
- Success Gradient: Grün → Hellgrün
```

#### Design-Elemente
- **Große, runde Buttons** (28px Radius) mit Gradient-Hintergründen
- **Erhöhte Cards** (20px Radius) mit Schatten-Effekten
- **Größere Schriftarten** (18px-36px) für bessere Lesbarkeit
- **Animierte Interaktionen** (Scale, Fade, Slide)

### 2. Gamification-System

#### XP & Leveling
```dart
// XP-Berechnung pro Fang
Basis XP: 10 Punkte
+ Länge > 50cm: +20 Punkte
+ Länge > 70cm: +30 Punkte
+ Gewicht > 1kg: +15 Punkte
+ Gewicht > 5kg: +25 Punkte
+ Seltene Art: +50 Punkte

// Level-Berechnung
Level = (XP / 200) + 1
XP für nächstes Level = Level * 200
```

#### Achievements
6 Standard-Achievements:
1. **Erster Fang** - Erfasse deinen ersten Fang
2. **10 Fänge** - Erfasse 10 Fänge
3. **25 Fänge** - Erfasse 25 Fänge
4. **50 Fänge** - Erfasse 50 Fänge
5. **Großer Fang** - Fange einen Fisch über 70cm
6. **7-Tage Streak** - Angel 7 Tage hintereinander

#### Stats & Tracking
- **Gesamtfänge** - Anzahl aller erfassten Fänge
- **Streak** - Aufeinanderfolgende Tage mit Aktivität
- **Rang** - Platzierung im Leaderboard
- **XP-Fortschritt** - Visueller Progress Bar zum nächsten Level

### 3. Spezielle UI-Komponenten

#### JugendGradientButton
Großer, animierter Button mit Gradient-Hintergrund:
```dart
JugendGradientButton(
  label: 'Fang erfassen',
  icon: Icons.add_circle_outline,
  gradient: JugendGradients.primaryGradient,
  onPressed: () { },
)
```

Features:
- Gradient-Hintergrund
- Icon + Text
- Scale-Animation beim Tap
- Schatten-Effekt

#### JugendCard
Moderne Card mit Gradient und Animation:
```dart
JugendCard(
  gradient: JugendGradients.purpleGradient,
  onTap: () { },
  child: Widget(),
)
```

Features:
- Optionaler Gradient-Hintergrund
- Hover/Tap Animation
- Erhöhter Schatten
- Abgerundete Ecken (20px)

#### JugendStatsBadge
Kompakte Badge für Stats-Anzeige:
```dart
JugendStatsBadge(
  label: 'Fänge',
  value: '42',
  icon: Icons.phishing,
  gradient: JugendGradients.primaryGradient,
)
```

Features:
- Icon oben
- Wert in großer Schrift
- Label unten
- Gradient-Hintergrund mit Schatten

#### JugendProgressBar
Animierter Fortschrittsbalken:
```dart
JugendProgressBar(
  progress: 0.65,
  label: '650 / 1000 XP',
  gradient: JugendGradients.primaryGradient,
)
```

#### JugendAchievementBadge
Badge für Achievements:
```dart
JugendAchievementBadge(
  title: 'Erster Fang',
  icon: Icons.check_circle,
  unlocked: true,
  gradient: JugendGradients.successGradient,
)
```

Features:
- Runder Badge mit Icon
- Graustufen wenn locked
- Gradient + Schatten wenn unlocked
- Titel unterhalb

### 4. Dashboard-Layout

Das Jugend-Dashboard ist komplett anders aufgebaut:

#### Struktur
```
┌─────────────────────────────────┐
│  Gradient AppBar (Cyan)         │
├─────────────────────────────────┤
│  Welcome Card (Lila Gradient)   │
│  - Icon + Level + XP            │
├─────────────────────────────────┤
│  Stats Row (3 Badges)           │
│  - Fänge | Streak | Rang        │
├─────────────────────────────────┤
│  Level Progress Card            │
│  - Progress Bar zum Next Level  │
├─────────────────────────────────┤
│  Quick Actions (3 Buttons)      │
│  - Fang erfassen (groß)         │
│  - Ranking | Wetter (klein)     │
├─────────────────────────────────┤
│  Achievements (4 Badges)        │
│  - Erste 4 Achievements         │
└─────────────────────────────────┘
```

#### Features
- **Gradient AppBar** mit animiertem Hintergrund
- **Fade + Slide Animation** beim Laden
- **Scroll-fähiges Layout** mit CustomScrollView
- **Automatisches Laden** von Gamification-Daten

## Datenmodelle

### GamificationData
```dart
class GamificationData {
  final int xpPoints;
  final int level;
  final int totalCatches;
  final int streak;
  final int rank;
  final List<Achievement> achievements;

  // Berechnete Properties
  int get xpForNextLevel;
  double get progressToNextLevel;
  int get xpInCurrentLevel;
}
```

### Achievement
```dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool unlocked;
  final int requirement;
  final DateTime? unlockedAt;
}
```

## Providers

### GamificationProvider
```dart
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationData?>();

// Verwenden
ref.read(gamificationProvider.notifier).loadGamificationData();
ref.read(gamificationProvider.notifier).addXp(50);
ref.read(gamificationProvider.notifier).incrementCatches();
ref.read(gamificationProvider.notifier).unlockAchievement('first_catch');
```

## Datenbankschema

### Tabelle: gamification
```sql
CREATE TABLE gamification (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  xp_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  total_catches INTEGER DEFAULT 0,
  streak INTEGER DEFAULT 0,
  rank INTEGER DEFAULT 0,
  achievements JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### View: leaderboard
```sql
CREATE VIEW leaderboard AS
SELECT
  user_id,
  display_name,
  xp_points,
  level,
  total_catches,
  ROW_NUMBER() OVER (ORDER BY xp_points DESC) as rank
FROM gamification
LEFT JOIN member ON member.user_id = gamification.user_id
ORDER BY xp_points DESC
LIMIT 100;
```

## Setup-Anleitung

### 1. Datenbank-Migration ausführen
```bash
# Mit Supabase CLI
supabase db push

# Oder manuell in Supabase Dashboard
-- Führe add_gamification_table.sql aus
```

### 2. Benutzer zur Jugend-Gruppe zuweisen
```sql
-- In der member Tabelle
UPDATE member
SET member_group = 'jugend'
WHERE user_id = '<user-uuid>';
```

### 3. Testen
1. Login als Jugend-User
2. Dashboard wird automatisch als Jugend-Layout angezeigt
3. Teste verschiedene Funktionen:
   - Fang erfassen → XP werden berechnet
   - Achievements werden automatisch freigeschaltet
   - Level steigt bei genug XP

### 4. Admin-Test-Screen
Navigiere zu `/admin/member-groups` um:
- Zwischen Gruppen zu wechseln
- Jugend-Layout live zu testen
- Farben und Designs zu vergleichen

## Unterschiede zu Aktive/Senioren

| Feature | Jugend | Aktive | Senioren |
|---------|--------|--------|----------|
| **Farbschema** | Cyan/Pink/Lila | Schwarz/Grau | Braun/Warm |
| **Buttons** | Groß, Rund, Gradient | Standard | Standard |
| **Schriftgröße** | 18-36px | 14-24px | 14-24px |
| **Gamification** | ✅ XP, Level, Achievements | ❌ | ❌ |
| **Animationen** | ✅ Fade, Slide, Scale | Minimal | Minimal |
| **Dashboard** | Komplett anders | Standard | Standard |
| **Cards** | Gradient, Schatten | Einfach | Einfach |
| **Stats-Anzeige** | Badges mit Gradients | Einfache Liste | Einfache Liste |

## Verwendung im Code

### Dashboard automatisch anzeigen
```dart
// In dashboard_screen.dart
if (memberGroup == MemberGroup.jugend) {
  return const JugendDashboard();
}
```

### Gamification-Daten laden
```dart
// In initState
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(gamificationProvider.notifier).loadGamificationData();
});

// Im Build
final gamificationData = ref.watch(gamificationProvider);
final xp = gamificationData?.xpPoints ?? 0;
final level = gamificationData?.level ?? 1;
```

### XP nach Fang hinzufügen
```dart
// In catch_create_screen.dart nach Erfassung
final xp = GamificationData.calculateXpForCatch(
  lengthCm: length,
  weightG: weight,
  isRare: false,
);
await ref.read(gamificationProvider.notifier).addXp(xp);
await ref.read(gamificationProvider.notifier).incrementCatches();
```

### Custom Widgets verwenden
```dart
// Gradient Button
JugendGradientButton(
  label: 'Action',
  icon: Icons.add,
  gradient: JugendGradients.accentGradient,
  onPressed: () { },
)

// Card mit Gradient
JugendCard(
  gradient: JugendGradients.purpleGradient,
  child: Column(children: [...]),
)

// Stats Badge
JugendStatsBadge(
  label: 'XP',
  value: '1250',
  icon: Icons.star,
  gradient: JugendGradients.primaryGradient,
)
```

## Erweiterungsmöglichkeiten

### Weitere Achievements hinzufügen
```dart
// In gamification_data.dart
Achievement(
  id: 'master_angler',
  title: 'Meister-Angler',
  description: 'Erfasse 100 Fänge',
  iconName: 'workspace_premium',
  unlocked: false,
  requirement: 100,
)
```

### Neue Gradients erstellen
```dart
// In theme.dart
class JugendGradients {
  static const newGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

### Streak-System implementieren
```dart
// Prüfe ob User heute aktiv war
final lastActivity = await getLastActivity(userId);
final today = DateTime.now();
final daysSince = today.difference(lastActivity).inDays;

if (daysSince == 1) {
  // Streak fortsetzen
  await incrementStreak();
} else if (daysSince > 1) {
  // Streak zurücksetzen
  await resetStreak();
}
```

### Leaderboard-Screen erstellen
```dart
// Neue Route in app_router.dart
GoRoute(
  path: '/leaderboard',
  builder: (_, __) => const JugendLeaderboardScreen(),
)

// Screen nutzt leaderboard View
final leaderboard = await supabase
  .from('leaderboard')
  .select('*')
  .limit(100);
```

## Troubleshooting

### Dashboard zeigt nicht Jugend-Layout
- Prüfe ob `member_group = 'jugend'` in DB gesetzt ist
- Prüfe ob `loadMemberGroup()` aufgerufen wird
- Checke Browser Console für Fehler

### Gamification-Daten werden nicht geladen
- Prüfe ob Migration ausgeführt wurde: `SELECT * FROM gamification LIMIT 1;`
- Prüfe ob RLS-Policies korrekt sind
- Prüfe ob `loadGamificationData()` aufgerufen wird

### Achievements werden nicht freigeschaltet
- Prüfe Logik in `_checkAchievements()`
- Prüfe ob `incrementCatches()` nach Fang aufgerufen wird
- Checke `total_catches` Wert in DB

### Animationen ruckeln
- Prüfe ob `SingleTickerProviderStateMixin` verwendet wird
- Stelle sicher dass `dispose()` Controller disposed
- Reduziere Animation-Duration bei Performance-Problemen

## Performance-Tipps

1. **Provider cachen**: Gamification-Daten werden automatisch gecacht
2. **Lazy Loading**: Achievements werden nur bei Bedarf geladen
3. **Debouncing**: XP-Updates werden gebatched
4. **Image Caching**: Logos werden gecacht

## Zukünftige Features

- [ ] Push-Benachrichtigungen bei Level-Up
- [ ] Soziale Features (Freunde, Challenges)
- [ ] Mehr Achievements (100+)
- [ ] Saisonale Events
- [ ] Animierte Level-Up-Screen
- [ ] Teilen-Funktion für Achievements
- [ ] Catch-of-the-Day Feature
- [ ] Foto-Filter für Fänge
- [ ] AR-Features für Fisch-Erkennung
