import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/providers/catch_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:asv_app/services/storage_service.dart';

/// Catch Edit Screen - Bearbeiten eines vorhandenen Fangs
class CatchEditScreen extends ConsumerStatefulWidget {
  final String catchId;

  const CatchEditScreen({
    super.key,
    required this.catchId,
  });

  @override
  ConsumerState<CatchEditScreen> createState() => _CatchEditScreenState();
}

class _CatchEditScreenState extends ConsumerState<CatchEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _weightController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  double? _uploadProgress;
  File? _pickedImageFile;
  String? _error;

  Catch? _originalCatch;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(Supabase.instance.client);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatch();
    });
  }

  Future<void> _loadCatch() async {
    final catch_ = await ref.read(catchByIdProvider(widget.catchId).future);
    if (catch_ != null && mounted) {
      setState(() {
        _originalCatch = catch_;
        _lengthController.text = catch_.lengthCm?.toString() ?? '0';
        _weightController.text = catch_.weightG?.toString() ?? '0';
        _photoUrlController.text = catch_.photoUrl ?? '';
      });
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _weightController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_originalCatch == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fang bearbeiten'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fang bearbeiten'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bearbeite die Details deines Fangs: ${_originalCatch!.speciesName ?? "Unbekannt"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Species (Read-Only)
              TextFormField(
                initialValue: _originalCatch!.speciesName ?? 'Unbekannt',
                decoration: const InputDecoration(
                  labelText: 'Fischart',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Water Body (Read-Only)
              TextFormField(
                initialValue: _originalCatch!.waterBodyName ?? 'Unbekannt',
                decoration: const InputDecoration(
                  labelText: 'Gewässer',
                  prefixIcon: Icon(Icons.water),
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Length
              TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Länge (cm)',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                  hintText: 'z.B. 45',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final num = int.tryParse(value);
                  if (num == null) return 'Bitte eine gültige Zahl eingeben';
                  if (num < 0) return 'Länge muss positiv sein';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Gewicht (g)',
                  prefixIcon: Icon(Icons.scale),
                  border: OutlineInputBorder(),
                  hintText: 'z.B. 2500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final num = int.tryParse(value);
                  if (num == null) return 'Bitte eine gültige Zahl eingeben';
                  if (num < 0) return 'Gewicht muss positiv sein';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Photo Section
              Text(
                'Foto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Current Photo Preview
              if (_photoUrlController.text.isNotEmpty || _pickedImageFile != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImageFile != null
                      ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                      : Image.network(
                          _photoUrlController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                ),

              // Photo Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _pickedImageFile = null;
                              _photoUrlController.clear();
                            });
                          },
                    icon: const Icon(Icons.delete),
                    tooltip: 'Foto entfernen',
                  ),
                ],
              ),

              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Wird hochgeladen... ${(_uploadProgress ?? 0) * 100}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSave,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Änderungen speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('Abbrechen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _pickedImageFile = File(picked.path);
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      final name = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final path = 'catches/$userId/${DateTime.now().millisecondsSinceEpoch}_$name';

      final url = await _storageService.uploadFile(
        _pickedImageFile!,
        path,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
        preferSignedUrl: true,
      );

      if (url != null && mounted) {
        setState(() {
          _photoUrlController.text = url;
          _isUploading = false;
          _uploadProgress = null;
        });
      } else {
        throw Exception('Upload fehlgeschlagen');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Hochladen: $e';
          _isUploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalCatch == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedCatch = _originalCatch!.copyWith(
        lengthCm: int.tryParse(_lengthController.text),
        weightG: int.tryParse(_weightController.text),
        photoUrl: _photoUrlController.text.isEmpty ? null : _photoUrlController.text,
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(catchNotifierProvider.notifier)
          .updateCatch(updatedCatch);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fang erfolgreich aktualisiert!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Go back to detail
        } else {
          throw Exception('Aktualisierung fehlgeschlagen');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Speichern: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
