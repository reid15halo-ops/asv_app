import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/providers/event_provider.dart';

/// Event-Detail Screen zeigt alle Details eines Events
class EventDetailScreen extends ConsumerStatefulWidget {
  final int eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isRegistering = false;

  Future<void> _registerForEvent(Event event) async {
    setState(() => _isRegistering = true);

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.registerForEvent(widget.eventId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erfolgreich angemeldet!')),
        );
        // Refresh providers
        ref.invalidate(eventByIdProvider(widget.eventId));
        ref.invalidate(isUserRegisteredProvider(widget.eventId));
        ref.invalidate(registeredCountProvider(widget.eventId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _cancelRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anmeldung stornieren?'),
        content: const Text('Möchtest du deine Anmeldung wirklich stornieren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Stornieren'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRegistering = true);

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.cancelRegistration(widget.eventId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anmeldung storniert')),
        );
        ref.invalidate(eventByIdProvider(widget.eventId));
        ref.invalidate(isUserRegisteredProvider(widget.eventId));
        ref.invalidate(registeredCountProvider(widget.eventId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventByIdProvider(widget.eventId));
    final isRegisteredAsync = ref.watch(isUserRegisteredProvider(widget.eventId));
    final registeredCountAsync = ref.watch(registeredCountProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event-Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Löschen',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Event löschen?'),
                  content: const Text('Möchtest du dieses Event wirklich löschen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Löschen'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(eventsProvider.notifier).deleteEvent(widget.eventId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event gelöscht')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event nicht gefunden'));
          }
          return _buildEventDetails(
            event,
            isRegisteredAsync,
            registeredCountAsync,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Fehler beim Laden',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetails(
    Event event,
    AsyncValue<bool> isRegisteredAsync,
    AsyncValue<int> registeredCountAsync,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Typ-Farbe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  event.eventType.getColor(context),
                  event.eventType.getColor(context).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      event.eventType.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.eventType.displayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Status Banner
          if (event.status == EventStatus.cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red,
              child: const Text(
                'ABGESAGT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beschreibung
                if (event.description != null) ...[
                  Text(
                    event.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],

                // Datum & Zeit
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  'Datum',
                  event.eventDateTimeFormatted,
                ),
                const SizedBox(height: 12),

                // Enddatum
                if (event.endDate != null)
                  _buildDetailRow(
                    context,
                    Icons.event_available,
                    'Endet am',
                    '${event.endDate!.day}.${event.endDate!.month}.${event.endDate!.year} '
                        '${event.endDate!.hour.toString().padLeft(2, '0')}:${event.endDate!.minute.toString().padLeft(2, '0')} Uhr',
                  ),
                if (event.endDate != null) const SizedBox(height: 12),

                // Location
                if (event.location != null)
                  _buildDetailRow(
                    context,
                    Icons.location_on,
                    'Ort',
                    event.location!,
                  ),
                if (event.location != null) const SizedBox(height: 24),

                // Registrierung Info
                if (event.registrationRequired) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Anmeldung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Teilnehmer-Count
                  registeredCountAsync.when(
                    data: (count) => _buildDetailRow(
                      context,
                      Icons.people,
                      'Angemeldete Teilnehmer',
                      event.maxParticipants != null
                          ? '$count / ${event.maxParticipants}'
                          : '$count',
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),

                  // Anmeldeschluss
                  if (event.registrationDeadline != null)
                    _buildDetailRow(
                      context,
                      Icons.access_time,
                      'Anmeldeschluss',
                      '${event.registrationDeadline!.day}.${event.registrationDeadline!.month}.${event.registrationDeadline!.year}',
                    ),
                  if (event.registrationDeadline != null) const SizedBox(height: 24),

                  // Registrierungs-Buttons
                  isRegisteredAsync.when(
                    data: (isRegistered) {
                      if (isRegistered) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Du bist angemeldet',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isRegistering ? null : _cancelRegistration,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Anmeldung stornieren'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        );
                      } else if (event.canRegister) {
                        return ElevatedButton.icon(
                          onPressed: _isRegistering ? null : () => _registerForEvent(event),
                          icon: _isRegistering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.app_registration),
                          label: const Text('Jetzt anmelden'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        );
                      } else {
                        // Kann nicht anmelden
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.isFull
                                      ? 'Event ist ausgebucht'
                                      : event.isRegistrationClosed
                                          ? 'Anmeldeschluss überschritten'
                                          : 'Anmeldung nicht möglich',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
