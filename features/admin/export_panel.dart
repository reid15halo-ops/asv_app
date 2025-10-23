import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../env.dart';

class ExportPanel extends StatefulWidget {
  const ExportPanel({super.key});
  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  bool _busy = false;
  String? _msg;
  final _supa = Supabase.instance.client;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    final user = _supa.auth.currentUser;
    if (user != null) {
      final claims = (user.userMetadata ?? {}) as Map<String, dynamic>;
      _isAdmin = claims['is_admin'] == true;
    }
  }

  @override
  void dispose() { _yearCtrl.dispose(); super.dispose(); }

  Future<void> _trigger({String? memberId}) async {
    setState(() { _busy = true; _msg = null; });
    try {
      final session = _supa.auth.currentSession;
      final token = session?.accessToken;
      final year = int.tryParse(_yearCtrl.text) ?? DateTime.now().year;
  final urlStr = Env.exportEdgeUrl;
  if (urlStr.isEmpty) throw 'EXPORT_EDGE_URL not configured in app.env.dart';
  final url = Uri.parse(urlStr);
  final headers = <String,String>{'Content-Type':'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';
  final body = memberId == null ? {'year': year} : {'year': year, 'member_id': memberId};
  final res = await http.post(url, headers: headers, body: jsonEncode(body));
  if (res.statusCode == 200) setState(() => _msg = 'Export gestartet für $year');
  else setState(() => _msg = 'Export fehlgeschlagen: ${res.statusCode} ${res.body}');
    } catch (e) {
      setState(() => _msg = 'Fehler: $e');
    } finally { if (mounted) setState(() => _busy = false);}    
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: const Text('Admin Export')), body: const Center(child: Text('Zugriff verweigert')));
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Export')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jahr')),
          const SizedBox(height: 12),
          // For now a simple trigger for whole year
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : () => _trigger(), child: _busy ? const CircularProgressIndicator() : const Text('Export starten'))),
          const SizedBox(height: 12),
          if (_msg != null) Text(_msg!),
        ]),
      ),
    );
  }
}
