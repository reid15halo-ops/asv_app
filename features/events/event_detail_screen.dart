import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/models/event_participant.dart';
import 'package:asv_app/repositories/event_repository.dart';
import 'package:asv_app/repositories/member_repository.dart';

/// Provider für Event Details
final eventByIdProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final repo = EventRepository(Supabase.instance.client);
  return await repo.getEventById(eventId);
});

/// Provider für Event Teilnehmer
final eventParticipantsProvider = FutureProvider.family<List<EventParticipant>, String>((ref, eventId) async {
  final repo = EventRepository(Supabase.instance.client);
  return await repo.getEventParticipants(eventId);
});

/// Provider für Registrierungsstatus
final isRegisteredProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  final repo = EventRepository(Supabase.instance.client);
  return await repo.isRegisteredForEvent(eventId, userId);
});

/// Event Detail Screen - Zeigt alle Details eines Events mit Teilnehmerverwaltung
class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventByIdProvider(widget.eventId));

    return Scaffold(
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Zurück'),
              ),
            ],
          ),
        ),
        data: (event) {
          if (event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64),
                  const SizedBox(height: 16),
                  const Text('Event nicht gefunden'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            );
          }

          return _buildDetailView(context, event);
        },
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Event event) {
    final isRegisteredAsync = ref.watch(isRegisteredProvider(widget.eventId));

    return CustomScrollView(
      slivers: [
        // App Bar mit Foto/Farbe
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            background: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildGradientHeader(event),
                  )
                : _buildGradientHeader(event),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Info Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event.type.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: event.type.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(event.type.icon, size: 16, color: event.type.color),
                          const SizedBox(width: 6),
                          Text(
                            event.type.displayName,
                            style: TextStyle(
                              color: event.type.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date/Time
                    _buildInfoRow(
                      Icons.event,
                      'Datum',
                      event.formattedDate,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Location
                    if (event.location != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'Ort',
                        event.location!,
                        Colors.red,
                      ),
                    if (event.location != null) const SizedBox(height: 12),

                    // Target Groups
                    _buildInfoRow(
                      Icons.people,
                      'Zielgruppe',
                      event.targetGroupsString,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),

                    // Participants
                    _buildInfoRow(
                      Icons.person_add,
                      'Teilnehmer',
                      event.maxParticipants != null
                          ? '${event.currentParticipants} / ${event.maxParticipants}'
                          : '${event.currentParticipants}',
                      Colors.green,
                    ),

                    // Fully Booked Badge
                    if (event.isFullyBooked) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Event ist ausgebucht',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Description
              if (event.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beschreibung',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

              if (event.description.isNotEmpty) const Divider(height: 1),

              // Registration Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: isRegisteredAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                  data: (isRegistered) {
                    if (event.isPast) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 12),
                            Text(
                              'Event ist bereits vorbei',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    if (isRegistered) {
                      return ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _handleUnregister(event),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel),
                        label: const Text('Abmelden'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: _isLoading || event.isFullyBooked
                            ? null
                            : () => _handleRegister(event),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(event.isFullyBooked ? 'Ausgebucht' : 'Anmelden'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      );
                    }
                  },
                ),
              ),

              // Participants List
              _buildParticipantsList(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientHeader(Event event) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.type.color,
            event.type.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          event.type.icon,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList() {
    final participantsAsync = ref.watch(eventParticipantsProvider(widget.eventId));

    return participantsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
      data: (participants) {
        if (participants.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Noch keine Anmeldungen',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teilnehmer (${participants.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...participants.map((participant) => _buildParticipantTile(participant)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantTile(EventParticipant participant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              participant.initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (participant.memberEmail != null)
                  Text(
                    participant.memberEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(participant.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(participant.status),
              ),
            ),
            child: Text(
              participant.status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(participant.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.confirmed:
        return Colors.green;
      case ParticipantStatus.registered:
        return Colors.blue;
      case ParticipantStatus.attended:
        return Colors.purple;
      case ParticipantStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _handleRegister(Event event) async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Nicht angemeldet');
      }

      // Get member ID
      final memberRepo = MemberRepository(Supabase.instance.client);
      final member = await memberRepo.getCurrentMember(userId);
      final memberId = member?.id;

      final repo = EventRepository(Supabase.instance.client);
      final success = await repo.registerForEvent(widget.eventId, userId, memberId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erfolgreich angemeldet!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh data
        ref.invalidate(isRegisteredProvider(widget.eventId));
        ref.invalidate(eventParticipantsProvider(widget.eventId));
        ref.invalidate(eventByIdProvider(widget.eventId));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anmeldung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUnregister(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden?'),
        content: Text('Möchtest du dich wirklich von "${event.title}" abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Nicht angemeldet');
      }

      final repo = EventRepository(Supabase.instance.client);
      final success = await repo.unregisterFromEvent(widget.eventId, userId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erfolgreich abgemeldet'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh data
        ref.invalidate(isRegisteredProvider(widget.eventId));
        ref.invalidate(eventParticipantsProvider(widget.eventId));
        ref.invalidate(eventByIdProvider(widget.eventId));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abmeldung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
