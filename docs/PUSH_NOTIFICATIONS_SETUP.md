# Push Notifications Setup Guide (Firebase Cloud Messaging)

## Übersicht

Dieser Guide beschreibt, wie Push Notifications mit Firebase Cloud Messaging (FCM) in die ASV Großostheim App integriert werden können.

**Status**: 🚧 Noch nicht implementiert - Diese Dokumentation dient als Anleitung für die zukünftige Implementierung

## Voraussetzungen

- Firebase-Projekt erstellt
- Flutter Firebase Packages installiert
- Supabase Backend mit FCM-Integration
- Android/iOS Konfiguration

## 1. Firebase-Projekt Setup

### 1.1 Firebase-Projekt erstellen

1. Besuche [Firebase Console](https://console.firebase.google.com/)
2. Erstelle ein neues Projekt oder verwende ein bestehendes
3. Füge Android und iOS Apps hinzu

### 1.2 Android Setup

1. **Registriere Android App in Firebase**
   - Package Name: `de.asvgrossostheim.app`
   - Download `google-services.json`
   - Platziere die Datei in `android/app/`

2. **Aktualisiere `android/build.gradle`**
   ```gradle
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
     }
   }
   ```

3. **Aktualisiere `android/app/build.gradle`**
   ```gradle
   apply plugin: 'com.google.gms.google-services'

   dependencies {
     implementation platform('com.google.firebase:firebase-bom:32.7.0')
     implementation 'com.google.firebase:firebase-messaging'
   }
   ```

4. **AndroidManifest.xml anpassen**
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.INTERNET"/>

   <application>
     <service
       android:name=".FirebaseMessagingService"
       android:exported="false">
       <intent-filter>
         <action android:name="com.google.firebase.MESSAGING_EVENT" />
       </intent-filter>
     </service>
   </application>
   ```

### 1.3 iOS Setup

1. **Registriere iOS App in Firebase**
   - Bundle ID: `de.asvgrossostheim.app`
   - Download `GoogleService-Info.plist`
   - Platziere die Datei in `ios/Runner/`

2. **APNs Certificate konfigurieren**
   - Erstelle APNs Certificate in Apple Developer Portal
   - Lade es in Firebase Console hoch

3. **Berechtigungen in `ios/Runner/Info.plist`**
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>remote-notification</string>
   </array>
   ```

## 2. Flutter Dependencies

### 2.1 Dependencies hinzufügen

Füge zu `pubspec.yaml` hinzu:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

### 2.2 Installation

```bash
flutter pub get
```

## 3. Firebase Initialisierung

### 3.1 Aktualisiere `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Generiert durch FlutterFire CLI

// Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background Message Handler registrieren
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Supabase initialisieren
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: ASVApp()));
}
```

## 4. FCM Service Implementation

### 4.1 Erstelle `services/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');

      // Get FCM Token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Token Refresh Handler
      _fcm.onTokenRefresh.listen(_saveFCMToken);

      // Initialize Local Notifications
      await _initializeLocalNotifications();

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Message Tap Handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
  }

  Future<void> _saveFCMToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Speichere Token in Supabase
    await Supabase.instance.client
        .from('user_fcm_tokens')
        .upsert({
          'user_id': userId,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    // Zeige Local Notification
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['action_url'],
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    print('Message tapped: ${message.data}');
    // Navigate to relevant screen based on action_url
  }
}
```

## 5. Supabase Backend Integration

### 5.1 FCM Tokens Tabelle

```sql
-- Migration: FCM Tokens Tabelle
CREATE TABLE user_fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  device_type TEXT, -- 'android' oder 'ios'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

CREATE INDEX idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);

-- RLS Policies
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own tokens"
  ON user_fcm_tokens
  FOR ALL
  USING (auth.uid() = user_id);
```

### 5.2 Edge Function für Push Notifications

Erstelle Supabase Edge Function `send-push-notification`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY')

serve(async (req) => {
  try {
    const { userIds, title, body, data } = await req.json()

    // Get FCM tokens for users
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: tokens } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .in('user_id', userIds)

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: 'No tokens found' }), {
        status: 404,
      })
    }

    // Send FCM messages
    const fcmTokens = tokens.map(t => t.fcm_token)

    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FIREBASE_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        registration_ids: fcmTokens,
        notification: { title, body },
        data: data || {},
        priority: 'high',
      }),
    })

    const result = await fcmResponse.json()

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    })
  }
})
```

## 6. Integration mit Notification System

### 6.1 Aktualisiere `notification_repository.dart`

Füge FCM-Aufruf hinzu wenn Notification erstellt wird:

```dart
Future<void> createNotificationWithPush(
  String userId,
  NotificationType type,
  String title,
  String message,
) async {
  // Erstelle In-App Notification
  await createNotification(userId, type, title, message);

  // Prüfe ob User Push Notifications aktiviert hat
  final prefs = await _getNotificationPreferences(userId);
  if (prefs.enablePushNotifications) {
    // Trigger Edge Function für Push
    await _client.functions.invoke('send-push-notification', body: {
      'userIds': [userId],
      'title': title,
      'body': message,
    });
  }
}
```

## 7. Testing

### 7.1 Manueller Test

1. **FCM Token überprüfen**
   ```dart
   String? token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. **Test-Notification senden**
   - Verwende Firebase Console > Cloud Messaging
   - Oder curl:
   ```bash
   curl -X POST https://fcm.googleapis.com/fcm/send \
     -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "DEVICE_FCM_TOKEN",
       "notification": {
         "title": "Test",
         "body": "Test Message"
       }
     }'
   ```

## 8. Best Practices

### 8.1 Notification Channels (Android)

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'asv_high_importance',
  'ASV Notifications',
  description: 'Wichtige Benachrichtigungen vom ASV',
  importance: Importance.high,
);

await _localNotifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

### 8.2 Notification Categories

Definiere verschiedene Channels für verschiedene Notification-Typen:
- Events (hohe Priorität)
- Ankündigungen (mittlere Priorität)
- Achievements (niedrige Priorität)

### 8.3 Data Messages vs Notification Messages

- **Notification Messages**: Werden vom System angezeigt
- **Data Messages**: Mehr Kontrolle, custom handling

Verwende Data Messages für bessere Kontrolle:

```dart
{
  "data": {
    "type": "event_new",
    "title": "Neues Event",
    "body": "Volleyballturnier am Samstag",
    "action_url": "/events/123"
  }
}
```

## 9. Troubleshooting

### Problem: Token wird nicht generiert

- Prüfe `google-services.json` / `GoogleService-Info.plist`
- Prüfe Firebase Console Konfiguration
- Prüfe Berechtigungen in AndroidManifest / Info.plist

### Problem: Notifications kommen nicht an

- Prüfe Firebase Server Key
- Prüfe Token in Datenbank
- Prüfe Edge Function Logs
- Teste mit Firebase Console Test-Message

### Problem: Notifications nur im Foreground

- Implementiere Background Handler korrekt
- Prüfe iOS Background Modes

## 10. Security

### 10.1 Server Key schützen

- **NIEMALS** Server Key in Client-Code
- Verwende Edge Functions
- Speichere Key in Supabase Secrets

### 10.2 Token Validierung

- Validiere Tokens regelmäßig
- Lösche ungültige Tokens
- Rate Limiting für Push-Sending

## 11. Monitoring

### 11.1 Firebase Analytics

Tracke:
- Notification Delivery Rate
- Notification Open Rate
- Token Refresh Rate

### 11.2 Supabase Logs

Überwache:
- Edge Function Errors
- Token Storage Errors
- Push Sending Failures

## Zusammenfassung

Nach Implementierung dieses Guides wird die App vollständige Push Notification Unterstützung haben:

✅ FCM Integration für Android und iOS
✅ Token Management in Supabase
✅ Edge Function für Push Sending
✅ Integration mit bestehendem Notification System
✅ User Preferences für Push Notifications
✅ Foreground und Background Handling

## Nächste Schritte

1. Firebase-Projekt erstellen
2. `firebase_core` und `firebase_messaging` Packages installieren
3. FlutterFire CLI für Konfiguration verwenden
4. FCM Service implementieren
5. Supabase Edge Function deployen
6. Testen auf echten Geräten
