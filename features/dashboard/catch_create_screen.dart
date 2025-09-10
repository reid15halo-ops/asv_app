import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatchCreateScreen extends StatefulWidget {
  const CatchCreateScreen({super.key});
  @override State<CatchCreateScreen> createState() => _CatchCreateScreenState();
}

class _CatchCreateScreenState extends State<CatchCreateScreen> {
  final _length = TextEditingController();
  final _weight = TextEditingController();
  final _photoUrl = TextEditingController();
  String? _speciesId;
  String? _waterId;
  bool _busy = false;
  String? _err;

  final _supa = Supabase.instance.client;

  Future<List<Map<String,dynamic>>> _load(String table, String nameField) async {
    final data = await _supa.from(table).select('id,$nameField').order(nameField);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      final userId = _supa.auth.currentUser!.id;
      final m = await _supa.from('member').select('id').eq('user_id', userId).maybeSingle();
      if (m == null) { setState(() => _err = 'Kein Member-Eintrag für diesen Nutzer.'); return; }
      await _supa.from('catch').insert({
        'member_id': m['id'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fang erfassen')),
      body: FutureBuilder(
        future: Future.wait([
          _load('species','name_de'),
          _load('water_body','name'),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final species = (snap.data![0] as List<Map<String,dynamic>>);
          final waters  = (snap.data![1] as List<Map<String,dynamic>>);
          _speciesId ??= species.isNotEmpty ? species.first['id'] as String : null;
          _waterId   ??= waters.isNotEmpty ? waters.first['id'] as String : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: _speciesId,
                items: species.map((s)=>DropdownMenuItem(value: s['id'] as String, child: Text(s['name_de'] as String))).toList(),
                onChanged: (v)=>setState(()=>_speciesId=v),
                decoration: const InputDecoration(labelText: 'Art'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _length, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Länge (cm)')),
              const SizedBox(height: 12),
              TextField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gewicht (g)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _waterId,
                items: waters.map((w)=>DropdownMenuItem(value: w['id'] as String, child: Text(w['name'] as String))).toList(),
                onChanged: (v)=>setState(()=>_waterId=v),
                decoration: const InputDecoration(labelText: 'Gewässer'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _photoUrl, decoration: const InputDecoration(labelText: 'Foto-URL (optional)')),
              const SizedBox(height: 12),
              if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const CircularProgressIndicator() : const Text('Speichern'),
              ),
            ]),
          );
        },
      ),
    );
  }
}
