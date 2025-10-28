import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:asv_app/providers/event_provider.dart';

/// Admin-Screen für Event CSV Import/Export
class EventsImportExportScreen extends ConsumerStatefulWidget {
  const EventsImportExportScreen({super.key});

  @override
  ConsumerState<EventsImportExportScreen> createState() => _EventsImportExportScreenState();
}

class _EventsImportExportScreenState extends ConsumerState<EventsImportExportScreen> {
  bool _isLoading = false;
  String? _message;
  bool _replaceExisting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Import/Export'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Admin-Funktion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Diese Funktionen sind nur für Administratoren verfügbar. '
                      'Sie können Events als CSV exportieren oder aus einer CSV-Datei importieren.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export Section
            Text(
              'Export',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exportiere Events als CSV-Datei',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportUpcomingEvents,
                      icon: const Icon(Icons.download),
                      label: const Text('Kommende Events exportieren'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _exportAllEvents,
                      icon: const Icon(Icons.download),
                      label: const Text('Alle Events exportieren'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ICS Export Section
            Text(
              'Kalender Export (ICS)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'ICS Format - Universal kompatibel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Exportiert Events im iCalendar Format (.ics) - kompatibel mit Google Calendar, Outlook, Apple Calendar, etc.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportUpcomingEventsIcs,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Kommende Events (ICS)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _exportAllEventsIcs,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Alle Events (ICS)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: _isLoading ? null : _downloadIcsTemplate,
                      icon: const Icon(Icons.file_download),
                      label: const Text('ICS-Vorlage herunterladen'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Import Section
            Text(
              'Import (CSV)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Importiere Events aus CSV-Datei',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CSV-Format: Titel, Beschreibung, Start-Datum, End-Datum, Ort, Typ, Zielgruppen (mit ; trennen), etc.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Replace Existing Checkbox
                    CheckboxListTile(
                      title: const Text('Existierende Events aktualisieren'),
                      subtitle: const Text(
                        'Wenn aktiviert, werden Events mit gleicher ID aktualisiert',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _replaceExisting,
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _replaceExisting = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _importEvents,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('CSV-Datei auswählen & importieren'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: _isLoading ? null : _downloadTemplate,
                      icon: const Icon(Icons.file_download),
                      label: const Text('CSV-Vorlage herunterladen'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Message Display
            if (_message != null)
              Card(
                color: _message!.contains('Fehler') || _message!.contains('ERROR')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _message!.contains('Fehler') || _message!.contains('ERROR')
                                ? Icons.error
                                : Icons.check_circle,
                            color: _message!.contains('Fehler') || _message!.contains('ERROR')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _message!.contains('Fehler') || _message!.contains('ERROR')
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _message = null),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUpcomingEvents() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.exportUpcomingEventsAndShare();

      if (mounted) {
        setState(() {
          _message = '✅ Kommende Events erfolgreich exportiert!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler beim Export: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAllEvents() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.exportAllEventsAndShare();

      if (mounted) {
        setState(() {
          _message = '✅ Alle Events erfolgreich exportiert!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler beim Export: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importEvents() async {
    try {
      // Datei-Picker öffnen
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // Abgebrochen
      }

      setState(() {
        _isLoading = true;
        _message = null;
      });

      final file = File(result.files.first.path!);
      final csvContent = await file.readAsString();

      final repository = ref.read(eventRepositoryProvider);
      final importResult = await repository.importEventsFromCsv(
        csvContent,
        replaceExisting: _replaceExisting,
      );

      if (mounted) {
        if (importResult['success']) {
          final imported = importResult['imported'];
          final total = importResult['total'];
          final errors = importResult['errors'] as List;

          String message = '✅ Import erfolgreich!\n\n';
          message += '$imported von $total Events importiert.\n';

          if (errors.isNotEmpty) {
            message += '\n⚠️ ${errors.length} Fehler:\n';
            message += errors.take(5).join('\n');
            if (errors.length > 5) {
              message += '\n... und ${errors.length - 5} weitere';
            }
          }

          setState(() => _message = message);

          // Refresh Event-Liste
          ref.invalidate(upcomingEventsProvider);
        } else {
          final errors = importResult['errors'] as List;
          setState(() {
            _message = 'ERROR beim Import:\n${errors.join('\n')}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler beim Import: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.shareCsvTemplate();

      if (mounted) {
        setState(() {
          _message = '✅ CSV-Vorlage zum Download bereit!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===== ICS Export Funktionen =====

  Future<void> _exportUpcomingEventsIcs() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.exportUpcomingEventsAsIcs();

      if (mounted) {
        setState(() {
          _message = '✅ Kommende Events als ICS-Kalender exportiert!\n'
              'Die Datei kann jetzt in Google Calendar, Outlook, Apple Calendar, etc. importiert werden.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler beim ICS-Export: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAllEventsIcs() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.exportAllEventsAsIcs();

      if (mounted) {
        setState(() {
          _message = '✅ Alle Events als ICS-Kalender exportiert!\n'
              'Die Datei kann jetzt in Google Calendar, Outlook, Apple Calendar, etc. importiert werden.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler beim ICS-Export: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadIcsTemplate() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.shareIcsTemplate();

      if (mounted) {
        setState(() {
          _message = '✅ ICS-Vorlage zum Download bereit!\n'
              'Öffne die Datei mit einem Kalender-Programm deiner Wahl.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Fehler: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
