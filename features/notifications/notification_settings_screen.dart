import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungseinstellungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Auf Standard zurücksetzen'),
                  content: const Text('Möchten Sie alle Einstellungen auf die Standardwerte zurücksetzen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(notificationPreferencesProvider.notifier).resetToDefaults();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Einstellungen zurückgesetzt')),
                        );
                      },
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Auf Standard zurücksetzen',
          ),
        ],
      ),
      body: preferencesAsync.when(
        data: (preferences) => ListView(
          children: [
            const _SectionHeader(title: 'Event-Benachrichtigungen'),
            SwitchListTile(
              title: const Text('Neue Events'),
              subtitle: const Text('Benachrichtigung bei neuen Events'),
              value: preferences.enableEventNew,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleEventNew(),
            ),
            SwitchListTile(
              title: const Text('Event-Erinnerungen'),
              subtitle: const Text('Erinnerungen an bevorstehende Events'),
              value: preferences.enableEventReminder,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleEventReminder(),
            ),
            SwitchListTile(
              title: const Text('Event-Absagen'),
              subtitle: const Text('Benachrichtigung bei abgesagten Events'),
              value: preferences.enableEventCancelled,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleEventCancelled(),
            ),
            SwitchListTile(
              title: const Text('Event-Änderungen'),
              subtitle: const Text('Benachrichtigung bei geänderten Events'),
              value: preferences.enableEventUpdated,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleEventUpdated(),
            ),
            const Divider(),

            const _SectionHeader(title: 'Ankündigungen & System'),
            SwitchListTile(
              title: const Text('Ankündigungen'),
              subtitle: const Text('Wichtige Mitteilungen von Admins'),
              value: preferences.enableAnnouncement,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleAnnouncement(),
            ),
            SwitchListTile(
              title: const Text('System-Benachrichtigungen'),
              subtitle: const Text('System-Nachrichten und Updates'),
              value: preferences.enableSystem,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleSystem(),
            ),
            const Divider(),

            const _SectionHeader(title: 'Gamification (Jugend)'),
            SwitchListTile(
              title: const Text('Achievements'),
              subtitle: const Text('Neue Achievements und Erfolge'),
              value: preferences.enableAchievement,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleAchievement(),
            ),
            SwitchListTile(
              title: const Text('Level-Ups'),
              subtitle: const Text('Benachrichtigung bei Level-Aufstiegen'),
              value: preferences.enableLevelUp,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleLevelUp(),
            ),
            const Divider(),

            const _SectionHeader(title: 'Push Notifications'),
            SwitchListTile(
              title: const Text('Push-Benachrichtigungen'),
              subtitle: const Text('Benachrichtigungen auch wenn App geschlossen ist (erfordert FCM-Setup)'),
              value: preferences.enablePushNotifications,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).togglePushNotifications(),
            ),
            if (preferences.enablePushNotifications)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Hinweis: Push-Benachrichtigungen sind noch nicht vollständig implementiert.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            const Divider(),

            const _SectionHeader(title: 'Ruhezeiten'),
            SwitchListTile(
              title: const Text('Ruhezeiten aktivieren'),
              subtitle: const Text('Keine Benachrichtigungen in bestimmten Zeiträumen'),
              value: preferences.enableQuietHours,
              onChanged: (_) => ref.read(notificationPreferencesProvider.notifier).toggleQuietHours(),
            ),
            if (preferences.enableQuietHours) ...[
              ListTile(
                title: const Text('Start'),
                subtitle: Text(
                  preferences.quietHoursStart != null
                      ? preferences.quietHoursStart!.format(context)
                      : 'Nicht gesetzt',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: preferences.quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
                  );
                  if (time != null) {
                    ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                      time,
                      preferences.quietHoursEnd,
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Ende'),
                subtitle: Text(
                  preferences.quietHoursEnd != null
                      ? preferences.quietHoursEnd!.format(context)
                      : 'Nicht gesetzt',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: preferences.quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                      preferences.quietHoursStart,
                      time,
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Diese Einstellungen beeinflussen nur In-App-Benachrichtigungen. '
                'Push-Benachrichtigungen können zusätzlich in den Systemeinstellungen verwaltet werden.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden der Einstellungen'),
              const SizedBox(height: 8),
              Text(error.toString(), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(notificationPreferencesProvider.notifier).loadPreferences(),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
