import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/providers/event_provider.dart';

/// Event erstellen oder bearbeiten
class EventFormScreen extends ConsumerStatefulWidget {
  final int? eventId; // null = neu erstellen

  const EventFormScreen({super.key, this.eventId});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _maxParticipantsController;

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;
  EventStatus _status = EventStatus.published;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _organizerController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _maxParticipantsController = TextEditingController();

    // Wenn Event bearbeitet wird, Daten laden
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvent());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    if (widget.eventId == null) return;

    final eventAsync = ref.read(eventProvider(widget.eventId!));
    eventAsync.whenData((event) {
      if (event == null) return;

      setState(() {
        _titleController.text = event.title;
        _descriptionController.text = event.description ?? '';
        _locationController.text = event.location ?? '';
        _organizerController.text = event.organizer ?? '';
        _contactEmailController.text = event.contactEmail ?? '';
        _contactPhoneController.text = event.contactPhone ?? '';
        _maxParticipantsController.text = event.maxParticipants?.toString() ?? '';
        _startDate = event.startDate;
        _startTime = TimeOfDay.fromDateTime(event.startDate);
        _endDate = event.endDate;
        _endTime = event.endDate != null ? TimeOfDay.fromDateTime(event.endDate!) : null;
        _allDay = event.allDay;
        _status = event.status;
        _isPublic = event.isPublic;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Event bearbeiten' : 'Neues Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titel
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Titel eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Beschreibung
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Ort
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ort',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Ganztägig Toggle
            SwitchListTile(
              title: const Text('Ganztägiges Event'),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
            ),
            const SizedBox(height: 16),

            // Startdatum
            ListTile(
              title: const Text('Startdatum *'),
              subtitle: Text(_formatDate(_startDate)),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, isStart: true),
            ),

            // Startzeit (nur wenn nicht ganztägig)
            if (!_allDay) ...[
              ListTile(
                title: const Text('Startzeit'),
                subtitle: Text(_startTime.format(context)),
                leading: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, isStart: true),
              ),
            ],
            const SizedBox(height: 8),

            // Enddatum (optional)
            ListTile(
              title: const Text('Enddatum (optional)'),
              subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Nicht festgelegt'),
              leading: const Icon(Icons.calendar_today),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _endDate = null;
                        _endTime = null;
                      }),
                    )
                  : null,
              onTap: () => _selectDate(context, isStart: false),
            ),

            // Endzeit (nur wenn nicht ganztägig und Enddatum gesetzt)
            if (!_allDay && _endDate != null) ...[
              ListTile(
                title: const Text('Endzeit'),
                subtitle: Text(_endTime?.format(context) ?? 'Nicht festgelegt'),
                leading: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, isStart: false),
              ),
            ],
            const SizedBox(height: 16),

            // Organisator
            TextFormField(
              controller: _organizerController,
              decoration: const InputDecoration(
                labelText: 'Organisator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Kontakt-Email
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'Kontakt-E-Mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Ungültige E-Mail-Adresse';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kontakt-Telefon
            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Kontakt-Telefon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Max. Teilnehmer
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Max. Teilnehmer (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
                hintText: 'Keine Begrenzung',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Bitte eine positive Zahl eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<EventStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: EventStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),

            // Öffentlich
            SwitchListTile(
              title: const Text('Öffentlich sichtbar'),
              subtitle: const Text('Andere Mitglieder können dieses Event sehen'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 24),

            // Speichern-Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Aktualisieren' : 'Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
    final initialTime = isStart ? _startTime : (_endTime ?? _startTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay? time) {
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = _allDay ? _startDate : _combineDateTime(_startDate, _startTime);
      final endDateTime = _endDate != null
          ? (_allDay ? _endDate : _combineDateTime(_endDate!, _endTime))
          : null;

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'start_date': startDateTime.toIso8601String(),
        'end_date': endDateTime?.toIso8601String(),
        'all_day': _allDay,
        'organizer': _organizerController.text.trim().isEmpty ? null : _organizerController.text.trim(),
        'contact_email': _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        'contact_phone': _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
        'max_participants': _maxParticipantsController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text.trim()),
        'status': _status.value,
        'is_public': _isPublic,
      };

      if (widget.eventId != null) {
        // Event aktualisieren
        await ref.read(eventActionsProvider).updateEvent(widget.eventId!, eventData);
      } else {
        // Neues Event erstellen
        await ref.read(eventActionsProvider).createEvent(eventData);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.eventId != null ? 'Event aktualisiert' : 'Event erstellt'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
