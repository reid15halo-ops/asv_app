import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Screen zum Erstellen von Ankündigungen
class AdminAnnouncementScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends ConsumerState<AdminAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _actionLabelController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _actionUrlController.dispose();
    _actionLabelController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = NotificationRepository(Supabase.instance.client);

      final count = await repository.createAnnouncementForAll(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        actionUrl: _actionUrlController.text.trim().isEmpty
            ? null
            : _actionUrlController.text.trim(),
        actionLabel: _actionLabelController.text.trim().isEmpty
            ? null
            : _actionLabelController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ankündigung an $count User gesendet!'),
            backgroundColor: Colors.green,
          ),
        );

        // Formular zurücksetzen
        _titleController.clear();
        _messageController.clear();
        _actionUrlController.clear();
        _actionLabelController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ankündigung erstellen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.campaign,
                        size: 48,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin-Ankündigung',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Diese Ankündigung wird als Benachrichtigung an alle User gesendet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titel
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  hintText: 'z.B. Neue Vereinsregeln',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Titel eingeben';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Nachricht
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Nachricht',
                  hintText: 'Beschreibe die Ankündigung...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Nachricht eingeben';
                  }
                  return null;
                },
                maxLines: 5,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Optionale Felder
              ExpansionTile(
                title: const Text('Erweiterte Optionen (optional)'),
                leading: const Icon(Icons.settings),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _actionLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Button-Text (optional)',
                            hintText: 'z.B. Mehr erfahren',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _actionUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Link-URL (optional)',
                            hintText: 'z.B. /events/123',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Vorschau
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.preview, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Vorschau',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.campaign, color: Colors.white),
                        ),
                        title: Text(
                          _titleController.text.isEmpty
                              ? 'Titel'
                              : _titleController.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _messageController.text.isEmpty
                              ? 'Nachricht'
                              : _messageController.text,
                        ),
                        trailing: _actionLabelController.text.isNotEmpty
                            ? const Icon(Icons.arrow_forward_ios, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Senden Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendAnnouncement,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Wird gesendet...' : 'An alle User senden'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Abbrechen Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('Abbrechen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
