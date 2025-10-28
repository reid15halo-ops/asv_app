import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/providers/event_provider.dart';

/// Event-Listen-Screen mit Filter
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  EventType? _selectedType;
  EventTargetGroup? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termine & Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          if (_selectedType != null || _selectedGroup != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedType != null)
                    Chip(
                      label: Text(_selectedType!.displayName),
                      avatar: Icon(_selectedType!.icon, size: 16),
                      onDeleted: () => setState(() => _selectedType = null),
                    ),
                  if (_selectedGroup != null)
                    Chip(
                      label: Text(_selectedGroup!.displayName),
                      onDeleted: () => setState(() => _selectedGroup = null),
                    ),
                ],
              ),
            ),

          // Event-Liste
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                // Anwenden der Filter
                var filteredEvents = events;
                if (_selectedType != null) {
                  filteredEvents = filteredEvents.where((e) => e.type == _selectedType).toList();
                }
                if (_selectedGroup != null) {
                  filteredEvents = filteredEvents.where((e) => e.isRelevantFor(_selectedGroup!)).toList();
                }

                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: Text('Keine Events gefunden'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _EventCard(event: event);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Fehler beim Laden')),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event-Typ:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EventType.values.map((type) {
                return FilterChip(
                  label: Text(type.displayName),
                  avatar: Icon(type.icon, size: 16),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? type : null);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Zielgruppe:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EventTargetGroup.values.map((group) {
                return FilterChip(
                  label: Text(group.displayName),
                  selected: _selectedGroup == group,
                  onSelected: (selected) {
                    setState(() => _selectedGroup = selected ? group : null);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedGroup = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Zurücksetzen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: event.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(event.type.icon, color: event.type.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.location!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
