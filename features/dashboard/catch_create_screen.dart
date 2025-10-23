import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cache_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:asv_app/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:asv_app/repositories/catch_repository.dart';

class CatchCreateScreen extends StatefulWidget {
  const CatchCreateScreen({super.key});
  @override State<CatchCreateScreen> createState() => _CatchCreateScreenState();
}

class _CatchCreateScreenState extends State<CatchCreateScreen> {
  final _length = TextEditingController();
  final _weight = TextEditingController();
  final _photoUrl = TextEditingController();
  final _lengthFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _photoFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final FocusNode _speciesFocus = FocusNode();
  final FocusNode _waterFocus = FocusNode();
  String? _speciesId;
  String? _waterId;
  bool _busy = false;
  String? _err;
  double? _uploadProgress;
  File? _pickedImageFile;

  final _supa = Supabase.instance.client;
  CacheService? _cache;
  List<Map<String, dynamic>>? _speciesCache;
  List<Map<String, dynamic>>? _watersCache;
  late final StorageService _storageService;
  late final CatchRepository _catchRepo;

  @override
  void initState() {
    super.initState();
    // Aggressiv: set initial numeric inputs to 0 so users see a value immediately
    _length.text = '0';
    _weight.text = '0';
    // initialize services and prefetch cached lists
    _storageService = StorageService(_supa);
    _catchRepo = CatchRepository(_supa);
    _initCacheAndPrefetch();
  }

  Future<void> _initCacheAndPrefetch() async {
    _cache = await CacheService.create();
    try {
      final s = await _loadCached('species', 'name_de');
      _speciesCache = s;
      final w = await _loadCached('water_body', 'name');
      _watersCache = w;
      // set controller text if selection exists
      if (_speciesId != null) {
        final found = _speciesCache?.firstWhere((e) => e['id'] == _speciesId, orElse: () => {});
        if (found != null && found.isNotEmpty) _speciesController.text = found['name_de'] as String;
      }
      if (_waterId != null) {
        final found = _watersCache?.firstWhere((e) => e['id'] == _waterId, orElse: () => {});
        if (found != null && found.isNotEmpty) _waterController.text = found['name'] as String;
      }
      setState(() {});
    } catch (_) {}
  }

  Future<List<Map<String,dynamic>>> _loadCached(String table, String nameField, {int ttlSeconds = 3600}) async {
    final key = 'cache_$table';
    final cached = _cache?.getJson(key, ttlSeconds: ttlSeconds);
    if (cached is List) {
      try {
        return (cached as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    final fresh = await _load(table, nameField);
    await _cache?.setJson(key, fresh);
    return fresh;
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _clearCacheFor(String table) async {
    await _cache?.remove('cache_$table');
    // also clear local copy
    if (table == 'species') _speciesCache = null;
    if (table == 'water_body') _watersCache = null;
    setState(() {});
  }

  Future<void> _refreshNow(String table, String nameField) async {
    if (_cache == null) _cache = await CacheService.create();
    try {
      final fresh = await _load(table, nameField);
      await _cache?.setJson('cache_$table', fresh);
      if (table == 'species') _speciesCache = fresh;
      if (table == 'water_body') _watersCache = fresh;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste aktualisiert')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aktualisierung fehlgeschlagen: $e')));
    }
  }

  Future<List<Map<String,dynamic>>> _load(String table, String nameField) async {
    final data = await _supa.from(table).select('id,$nameField').order(nameField);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      final userId = _supa.auth.currentUser!.id;
      final memberId = await _catchRepo.findMemberIdForUser(userId);
      if (memberId == null) { setState(() => _err = 'Kein Member-Eintrag für diesen Nutzer.'); return; }
      await _catchRepo.insertCatch({
        'member_id': memberId,
        'species_id': _speciesId,
        'length_cm': int.tryParse(_length.text),
        'weight_g': int.tryParse(_weight.text),
        'water_body_id': _waterId,
        'photo_url': _photoUrl.text.isEmpty ? null : _photoUrl.text,
        'privacy_level': 'club',
        'captured_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fang gespeichert.')));
        Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUpload(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: src, maxWidth: 2048, maxHeight: 2048, imageQuality: 85);
      if (picked == null) return;
      setState(() { _pickedImageFile = File(picked.path); _uploadProgress = 0.0; _markDirty(); });

      // generate a path: e.g. catches/<userId>/<timestamp>_<basename>
      final userId = _supa.auth.currentUser?.id ?? 'anon';
      final name = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final path = 'catches/$userId/${DateTime.now().toUtc().millisecondsSinceEpoch}_$name';

      final url = await _storageService.uploadFile(_pickedImageFile!, path, onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      }, preferSignedUrl: true);

      if (url != null) {
        setState(() { _photoUrl.text = url; _uploadProgress = null; });
      } else {
        setState(() { _uploadProgress = null; _err = 'Upload lieferte keine URL'; });
      }
    } catch (e) {
      setState(() { _err = 'Upload fehlgeschlagen: $e'; _uploadProgress = null; });
    }
  }

  Future<void> _pickFromCamera() async => await _pickAndUpload(ImageSource.camera);
  Future<void> _pickFromGallery() async => await _pickAndUpload(ImageSource.gallery);
  void _clearPhoto() { setState(() { _pickedImageFile = null; _photoUrl.text = ''; _uploadProgress = null; _markDirty(); }); }

  @override
  void dispose() {
    _length.dispose();
    _weight.dispose();
    _photoUrl.dispose();
    _lengthFocus.dispose();
    _weightFocus.dispose();
    _photoFocus.dispose();
    _speciesController.dispose();
    _waterController.dispose();
    _speciesFocus.dispose();
    _waterFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isDirty) return true;
        final res = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
          title: const Text('Änderungen verwerfen?'),
          content: const Text('Es gibt ungespeicherte Änderungen. Beim Zurückgehen gehen diese verloren.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Abbrechen')),
            TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Verwerfen')),
          ],
        ));
        return res == true;
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Fang erfassen'), actions: [
        PopupMenuButton<String>(onSelected: (v) async {
          if (v == 'export') {
            final yearStr = await showDialog<String>(context: context, builder: (c) {
              final tc = TextEditingController(text: DateTime.now().year.toString());
              return AlertDialog(
                title: const Text('Export Jahr wählen'),
                content: TextField(controller: tc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jahr')),
                actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Abbrechen')), TextButton(onPressed: () => Navigator.of(c).pop(tc.text), child: const Text('Export'))],
              );
            });
            if (yearStr == null) return;
            final y = int.tryParse(yearStr) ?? DateTime.now().year;
            setState(() => _busy = true);
            try {
              final userId = _supa.auth.currentUser?.id;
              if (userId == null) throw 'Nicht eingeloggt';
              final url = await _catchRepo.exportUserYearCsv(userId, y);
              if (url == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Daten für dieses Jahr')));
              else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export bereit: $url')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export fehlgeschlagen: $e')));
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          }
        }, itemBuilder: (c) => [const PopupMenuItem(value: 'export', child: Text('Exportieren (CSV)'))])
      ]),
      body: FutureBuilder(
        future: Future.wait([
          _loadCached('species','name_de'),
          _loadCached('water_body','name'),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final species = (snap.data![0] as List<Map<String,dynamic>>);
          final waters  = (snap.data![1] as List<Map<String,dynamic>>);
          _speciesId ??= species.isNotEmpty ? species.first['id'] as String : null;
          _waterId   ??= waters.isNotEmpty ? waters.first['id'] as String : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // Typeahead for species with refresh
                Row(children: [
                  Expanded(child: TypeAheadFormField<Map<String,dynamic>>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _speciesController,
                      focusNode: _speciesFocus,
                      decoration: const InputDecoration(labelText: 'Art *'),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _markDirty(),
                    ),
                    suggestionsCallback: (pattern) {
                      final q = pattern.toLowerCase();
                      final list = _speciesCache ?? species;
                      return list.where((s) => (s['name_de'] as String).toLowerCase().contains(q));
                    },
                    itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion['name_de'] as String)),
                    onSuggestionSelected: (suggestion) { setState(() { _speciesId = suggestion['id'] as String; _speciesController.text = suggestion['name_de'] as String; _markDirty(); }); },
                    validator: (v) => (v == null || v.isEmpty) ? 'Bitte eine Art wählen' : null,
                    onSaved: (_) {},
                  )),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => _refreshNow('species', 'name_de'), icon: const Icon(Icons.refresh)),
                ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _length,
                focusNode: _lengthFocus,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Länge (cm)', hintText: '0 (optional)'),
                onChanged: (_) => _markDirty(),
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_weightFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Bitte eine ganze Zahl eingeben';
                  if (n < 0) return 'Wert muss >= 0 sein';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                focusNode: _weightFocus,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Gewicht (g)', hintText: '0 (optional)'),
                onChanged: (_) => _markDirty(),
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_photoFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Bitte eine ganze Zahl eingeben';
                  if (n < 0) return 'Wert muss >= 0 sein';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Typeahead for water bodies with refresh
              Row(children: [
                Expanded(child: TypeAheadFormField<Map<String,dynamic>>(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _waterController,
                    focusNode: _waterFocus,
                    decoration: const InputDecoration(labelText: 'Gewässer *'),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _markDirty(),
                  ),
                  suggestionsCallback: (pattern) {
                    final q = pattern.toLowerCase();
                    final list = _watersCache ?? waters;
                    return list.where((w) => (w['name'] as String).toLowerCase().contains(q));
                  },
                  itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion['name'] as String)),
                  onSuggestionSelected: (suggestion) { setState(() { _waterId = suggestion['id'] as String; _waterController.text = suggestion['name'] as String; _markDirty(); }); },
                  validator: (v) => (v == null || v.isEmpty) ? 'Bitte ein Gewässer wählen' : null,
                  onSaved: (_) {},
                )),
                const SizedBox(width: 8),
                IconButton(onPressed: () => _refreshNow('water_body', 'name'), icon: const Icon(Icons.refresh)),
              ]),
              const SizedBox(height: 12),
              // Photo picker / upload section
              Row(children: [
                Expanded(child: TextFormField(controller: _photoUrl, focusNode: _photoFocus, decoration: const InputDecoration(labelText: 'Foto-URL (optional)'), enabled: false)),
                IconButton(onPressed: _busy ? null : _pickFromCamera, icon: const Icon(Icons.camera_alt)),
                IconButton(onPressed: _busy ? null : _pickFromGallery, icon: const Icon(Icons.photo_library)),
                IconButton(onPressed: _busy ? null : _clearPhoto, icon: const Icon(Icons.clear)),
              ]),
              const SizedBox(height: 8),
              if (_pickedImageFile != null) SizedBox(height: 200, child: Image.file(_pickedImageFile!, fit: BoxFit.cover)),
              if (_uploadProgress != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(value: _uploadProgress)),
              const SizedBox(height: 12),
              if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: (_busy || !(_formKey.currentState?.validate() == true)) ? null : _submit,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Speichern'),
                ),
              ),
            ]),
            ),
          );
        },
      ),
    );
  }
}
