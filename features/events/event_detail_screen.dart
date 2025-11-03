import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/providers/event_provider.dart';

/// Event-Details mit Anmelde-Funktion
class EventDetailScreen extends ConsumerWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final isRegisteredAsync = ref.watch(isUserRegisteredProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event-Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/events/$eventId/edit'),
            tooltip: 'Bearbeiten',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Löschen',
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event nicht gefunden'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image (optional)
                if (event.metadata?['image_url'] != null)
                  Image.network(
                    event.metadata!['image_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      // Date & Time
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Datum',
                        value: event.formattedDate,
                      ),
                      const SizedBox(height: 12),

                      // Location
                      if (event.location != null) ...[
                        _InfoRow(
                          icon: Icons.location_on,
                          label: 'Ort',
                          value: event.location!,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Organizer
                      if (event.organizer != null) ...[
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Organisator',
                          value: event.organizer!,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Participants
                      _InfoRow(
                        icon: Icons.people,
                        label: 'Teilnehmer',
                        value: event.maxParticipants != null
                            ? '${event.participantCount ?? 0} / ${event.maxParticipants}'
                            : '${event.participantCount ?? 0}',
                      ),
                      const SizedBox(height: 12),

                      // Status
                      _InfoRow(
                        icon: Icons.info,
                        label: 'Status',
                        value: event.status.label,
                      ),
                      const SizedBox(height: 12),

                      // WordPress Sync Info
                      if (event.syncSource == SyncSource.wordpress) ...[
                        _InfoRow(
                          icon: Icons.sync,
                          label: 'Quelle',
                          value: 'WordPress',
                        ),
                        if (event.wordpressUrl != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _launchUrl(event.wordpressUrl!),
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Auf Webseite ansehen'),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],

                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      if (event.description != null) ...[
                        Text(
                          'Beschreibung',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(event.description!),
                        const SizedBox(height: 24),
                      ],

                      // Contact Info
                      if (event.contactEmail != null || event.contactPhone != null) ...[
                        Text(
                          'Kontakt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (event.contactEmail != null) ...[
                          TextButton.icon(
                            onPressed: () => _launchUrl('mailto:${event.contactEmail}'),
                            icon: const Icon(Icons.email),
                            label: Text(event.contactEmail!),
                          ),
                        ],
                        if (event.contactPhone != null) ...[
                          TextButton.icon(
                            onPressed: () => _launchUrl('tel:${event.contactPhone}'),
                            icon: const Icon(Icons.phone),
                            label: Text(event.contactPhone!),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],

                      // Participants List
                      Text(
                        'Teilnehmer',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _ParticipantsList(eventId: eventId),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isRegisteredAsync.when(
        data: (isRegistered) {
          final eventData = eventAsync.value;
          if (eventData == null) return const SizedBox.shrink();

          // Wenn Event vorbei ist, keine Aktion anzeigen
          if (eventData.isPast) return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isRegistered
                  ? ElevatedButton.icon(
                      onPressed: () => _unregister(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Abmelden'),
                    )
                  : ElevatedButton.icon(
                      onPressed: eventData.isFull
                          ? null
                          : () => _register(context, ref),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: Text(eventData.isFull ? 'Ausgebucht' : 'Anmelden'),
                    ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(eventActionsProvider).registerForEvent(eventId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erfolgreich angemeldet')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _unregister(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(eventActionsProvider).unregisterFromEvent(eventId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erfolgreich abgemeldet')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event löschen?'),
        content: const Text('Möchtest du dieses Event wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(eventActionsProvider).deleteEvent(eventId);
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event gelöscht')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Info-Zeile mit Icon
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Teilnehmer-Liste
class _ParticipantsList extends ConsumerWidget {
  final int eventId;

  const _ParticipantsList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(eventParticipantsProvider(eventId));

    return participantsAsync.when(
      data: (participants) {
        if (participants.isEmpty) {
          return const Text('Noch keine Teilnehmer');
        }

        return Column(
          children: participants.map((p) {
            return ListTile(
              leading: CircleAvatar(
                child: Text(p.userId.substring(0, 1).toUpperCase()),
              ),
              title: Text('User ${p.userId.substring(0, 8)}...'),
              subtitle: Text('Angemeldet am ${p.registeredAt.day}.${p.registeredAt.month}.${p.registeredAt.year}'),
              trailing: Icon(p.status.icon, color: p.status.color),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Fehler: $error'),
    );
  }
}
