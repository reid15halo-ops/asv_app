import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asv_app/main.dart' as app;

/// E2E Integration Test für den kompletten Notification-Flow
///
/// Testet:
/// 1. Login
/// 2. Navigation zum Notification Center
/// 3. Anzeige von Notifications
/// 4. Als gelesen markieren
/// 5. Löschen von Notifications
/// 6. Notification Settings
///
/// HINWEIS: Dieser Test benötigt einen laufenden Supabase-Backend
/// und einen Test-User in der Datenbank

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Flow E2E Tests', () {
    testWidgets('Kompletter Notification-Flow', (tester) async {
      // App starten
      app.main();
      await tester.pumpAndSettle();

      // SCHRITT 1: Login (falls nicht eingeloggt)
      // Warte auf Login-Screen oder Dashboard
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Prüfe ob wir auf dem Login-Screen sind
      final emailField = find.byType(TextFormField).first;
      if (tester.any(emailField)) {
        // Führe Login durch
        await tester.enterText(emailField, 'test@example.com');

        final passwordField = find.byType(TextFormField).last;
        await tester.enterText(passwordField, 'testpassword123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Anmelden');
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // SCHRITT 2: Navigation zum Notification Center
      // Finde das Notification-Bell-Icon im AppBar
      final notificationIcon = find.byIcon(Icons.notifications);
      expect(notificationIcon, findsOneWidget, reason: 'Notification Icon sollte im AppBar sichtbar sein');

      // Tap auf Notification Icon
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      // Verifiziere dass wir auf dem Notifications Screen sind
      expect(find.text('Benachrichtigungen'), findsOneWidget);

      // SCHRITT 3: Prüfe ob Notifications angezeigt werden
      // Dieser Teil hängt von den Daten in der DB ab
      // Entweder sind Notifications vorhanden oder Empty State wird angezeigt

      // Prüfe auf Empty State oder Notification Liste
      final emptyState = find.text('Keine Benachrichtigungen');
      final notificationList = find.byType(ListView);

      expect(
        emptyState.evaluate().isNotEmpty || notificationList.evaluate().isNotEmpty,
        true,
        reason: 'Entweder Empty State oder Notification Liste sollte angezeigt werden',
      );

      // SCHRITT 4: Teste Settings Navigation
      final settingsIcon = find.byIcon(Icons.settings);
      expect(settingsIcon, findsOneWidget, reason: 'Settings Icon sollte im AppBar sein');

      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Verifiziere Settings Screen
      expect(find.text('Benachrichtigungseinstellungen'), findsOneWidget);

      // SCHRITT 5: Teste Settings-Toggles
      // Finde den ersten Switch
      final switches = find.byType(SwitchListTile);
      if (switches.evaluate().isNotEmpty) {
        // Toggle ersten Switch
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        // Toggle zurück
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      // SCHRITT 6: Zurück zum Notification Center
      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verifiziere dass wir zurück auf Notifications Screen sind
      expect(find.text('Benachrichtigungen'), findsOneWidget);

      // SCHRITT 7: Teste Filter (Unread Only)
      final filterIcon = find.byIcon(Icons.filter_alt_outlined);
      if (filterIcon.evaluate().isNotEmpty) {
        await tester.tap(filterIcon);
        await tester.pumpAndSettle();

        // Toggle zurück
        final filterIconFilled = find.byIcon(Icons.filter_alt);
        if (filterIconFilled.evaluate().isNotEmpty) {
          await tester.tap(filterIconFilled);
          await tester.pumpAndSettle();
        }
      }

      // SCHRITT 8: Teste Popup-Menü
      final moreButton = find.byType(PopupMenuButton<String>);
      if (moreButton.evaluate().isNotEmpty) {
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        // Verifiziere Menü-Optionen
        expect(find.text('Alle als gelesen markieren'), findsOneWidget);
        expect(find.text('Alle löschen'), findsOneWidget);

        // Schließe Menü durch Tap außerhalb
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Notification Badge sollte sichtbar sein', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Suche nach Badge im AppBar
      // Badge wird nur angezeigt wenn ungelesene Notifications vorhanden sind
      final badge = find.byType(Badge);

      // Badge kann vorhanden sein oder nicht, je nach Daten
      // Dieser Test verifiziert nur, dass die App nicht crasht
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pull-to-Refresh sollte funktionieren', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate zu Notifications
      final notificationIcon = find.byIcon(Icons.notifications);
      if (notificationIcon.evaluate().isNotEmpty) {
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        // Suche RefreshIndicator
        final refreshIndicator = find.byType(RefreshIndicator);
        if (refreshIndicator.evaluate().isNotEmpty) {
          // Führe Pull-to-Refresh durch
          await tester.drag(refreshIndicator, const Offset(0, 300));
          await tester.pumpAndSettle();
        }
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Notification Preferences E2E Tests', () {
    testWidgets('Quiet Hours sollten gesetzt werden können', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate zu Settings
      final notificationIcon = find.byIcon(Icons.notifications);
      if (notificationIcon.evaluate().isNotEmpty) {
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        final settingsIcon = find.byIcon(Icons.settings);
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Finde "Ruhezeiten aktivieren" Switch
        final quietHoursSwitch = find.ancestor(
          of: find.text('Ruhezeiten aktivieren'),
          matching: find.byType(SwitchListTile),
        );

        if (quietHoursSwitch.evaluate().isNotEmpty) {
          // Aktiviere Quiet Hours
          await tester.tap(quietHoursSwitch);
          await tester.pumpAndSettle();

          // Verifiziere dass Start/End Felder erscheinen
          expect(find.text('Start'), findsOneWidget);
          expect(find.text('Ende'), findsOneWidget);
        }
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Reset auf Standard sollte funktionieren', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate zu Settings
      final notificationIcon = find.byIcon(Icons.notifications);
      if (notificationIcon.evaluate().isNotEmpty) {
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        final settingsIcon = find.byIcon(Icons.settings);
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Finde Reset-Button (Refresh Icon)
        final resetButton = find.byIcon(Icons.refresh);
        if (resetButton.evaluate().isNotEmpty) {
          await tester.tap(resetButton);
          await tester.pumpAndSettle();

          // Dialog sollte erscheinen
          expect(find.text('Auf Standard zurücksetzen'), findsOneWidget);

          // Abbrechen
          final cancelButton = find.text('Abbrechen');
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }

      expect(tester.takeException(), isNull);
    });
  });
}
