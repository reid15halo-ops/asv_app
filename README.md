# ASV Großostheim Vereinsapp

Flutter-basierte Vereinsapp für den ASV Großostheim mit Unterstützung für Mitgliederverwaltung, Events, Fangprotokoll und Gamification.

## 📱 Features

- **Mitgliederverwaltung** - Verschiedene Mitgliedergruppen (Jugend, Mitglieder, Vorstände)
- **Event-System** - Events erstellen, verwalten und daran teilnehmen
- **Fangprotokoll** - Fänge dokumentieren mit Fotos und Details
- **Ranking & Leaderboards** - Trophy Board und Gamification für Jugend
- **Benachrichtigungen** - In-App Notifications mit Echtzeit-Updates
- **Wetter-Integration** - Bisswahrscheinlichkeit basierend auf Wetterdaten
- **Admin-Panel** - Verwaltung von Ankündigungen, Export und Gruppen
- **Merch-Shop** - Vereins-Merchandise (Placeholder)

## 🏗️ Architektur

- **Frontend**: Flutter 3.4+
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Auth**: Supabase Auth
- **Storage**: Supabase Storage für Bilder

## 📚 Dokumentation

### Setup & Installation
- [Getting Started](#getting-started) - Projekt-Setup und Installation

### Feature-Dokumentation
- [Jugend Features](docs/JUGEND_FEATURES.md) - Gamification, Achievements, Leaderboards
- [Member Groups](docs/MEMBER_GROUPS_FEATURE.md) - Mitgliedergruppen-System
- [Notification System](docs/NOTIFICATION_SYSTEM.md) - In-App Benachrichtigungen

### Erweiterte Guides
- [Push Notifications Setup](docs/PUSH_NOTIFICATIONS_SETUP.md) - Firebase Cloud Messaging Integration
- [Scheduled Notifications](docs/SCHEDULED_NOTIFICATIONS_SETUP.md) - Zeitgesteuerte Notifications mit pg_cron

### Archiv
- [Legacy Tools](archive/) - Alte Migration-Scripts und Export-Tools

## 🚀 Getting Started

### Voraussetzungen

- Flutter SDK (>=3.4.0 <4.0.0)
- Dart SDK
- Supabase Account
- Android Studio / Xcode für native Builds

### Installation

1. **Repository klonen**
   ```bash
   git clone https://github.com/reid15halo-ops/asv_app.git
   cd asv_app
   ```

2. **Dependencies installieren**
   ```bash
   flutter pub get
   ```

3. **Environment konfigurieren**

   Erstelle `env.dart` mit deinen Supabase Credentials:
   ```dart
   class Env {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

4. **Supabase Migrationen ausführen**

   Führe alle SQL-Migrationen aus `supabase/migrations/` in deinem Supabase Projekt aus:
   - `add_notifications_table.sql`
   - `add_gamification_table.sql`
   - `add_member_group.sql`
   - `add_email_check_function.sql`
   - `add_notification_preferences.sql`
   - `add_notification_cleanup.sql`

5. **App starten**
   ```bash
   flutter run
   ```

### Android Release Build

1. **Keystore erstellen**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **key.properties erstellen**

   Erstelle `android/key.properties`:
   ```
   storePassword=<dein-password>
   keyPassword=<dein-password>
   keyAlias=upload
   storeFile=<pfad-zum-keystore>
   ```

3. **Release Build**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Spezifische Tests
```bash
# Notification Tests
flutter test test/features/notifications/

# E2E Notification Flow
flutter test integration_test/notification_flow_test.dart
```

## 📦 Projektstruktur

```
asv_app/
├── android/              # Android-spezifische Konfiguration
├── ios/                  # iOS-spezifische Konfiguration
├── lib/                  # Shared Libraries
│   ├── models/          # Datenmodelle
│   ├── providers/       # Riverpod Provider
│   └── repositories/    # Data Layer
├── features/            # Feature-Module
│   ├── auth/           # Authentifizierung
│   ├── dashboard/      # Haupt-Dashboard
│   ├── notifications/  # Benachrichtigungssystem
│   ├── weather/        # Wetter-Integration
│   ├── catches/        # Fangprotokoll
│   ├── ranking/        # Rankings & Leaderboards
│   ├── gamification/   # Gamification (Jugend)
│   └── admin/          # Admin-Panel
├── services/           # Services (Cache, Share, Storage)
├── widgets/            # Wiederverwendbare UI-Komponenten
├── theme/              # App-Theming
├── docs/               # Dokumentation
├── supabase/          # Supabase Migrationen & Functions
├── test/              # Unit Tests
├── integration_test/  # Integration/E2E Tests
└── archive/           # Archivierte alte Dateien

```

## 🔧 Konfiguration

### Android Application ID
- Package: `de.asvgrossostheim.app`
- Konfiguriert in `android/app/build.gradle.kts`

### Supabase Setup
- URL und Keys in `env.dart`
- RLS Policies aktiviert für alle Tabellen
- Realtime aktiviert für `notifications`

### Theme
- Light/Dark Mode Support
- Angepasste Themes für verschiedene Mitgliedergruppen
- Jugend-Theme mit Gradienten und Gamification-Elementen

## 🤝 Contributing

1. Fork das Repository
2. Erstelle einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committe deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## 📄 Lizenz

Dieses Projekt ist für den ASV Großostheim e.V.

## 📞 Support

Bei Fragen oder Problemen:
- Issue auf GitHub erstellen
- Dokumentation in `docs/` konsultieren
- Supabase Logs überprüfen

## 🎯 Roadmap

- [ ] Firebase Cloud Messaging Integration (Push Notifications)
- [ ] pg_cron Integration (Scheduled Notifications)
- [ ] iOS Release
- [ ] Merch-Shop Implementation
- [ ] Social Features (Kommentare, Likes)
- [ ] Erweiterte Analytics

---

**Version**: 0.1.0+1
**Flutter**: >= 3.4.0 <4.0.0
**Plattformen**: Android, iOS (in Entwicklung), Web (geplant)
