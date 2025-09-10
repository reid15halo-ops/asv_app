import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrophyBoardScreen extends StatefulWidget {
  const TrophyBoardScreen({super.key});
  @override State<TrophyBoardScreen> createState() => _TrophyBoardScreenState();
}

class _TrophyBoardScreenState extends State<TrophyBoardScreen> {
  final _supa = Supabase.instance.client;
  late Future<List<Map<String,dynamic>>> _future;

  Future<List<Map<String,dynamic>>> _load() async {
    final year = DateTime.now().year;
    final res = await _supa.rpc('trophy_top_overall', params: {
      'p_year': year,
      'p_metric': 'length', // oder 'weight'
      'p_limit': 100,
    });
    final list = (res as List).cast<Map<String, dynamic>>();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Fehler: ${snap.error}'));
        }
        final items = snap.data as List<Map<String, dynamic>>;
        if (items.isEmpty) {
          return const Center(child: Text('Noch keine freigegebenen Fänge mit Foto in diesem Jahr.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final r = items[i];
            final photo = r['photo_url'] as String?;
            final species = (r['species_name'] ?? 'Unbekannt').toString();
            final member  = (r['member_name'] ?? 'Mitglied').toString();
            final len = r['length_cm'];
            final wgt = r['weight_g'];
            final water = (r['water_body_name'] ?? '').toString();
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo == null
                    ? const SizedBox(width: 56, height: 56)
                    : Image.network(photo, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width:56,height:56)),
              ),
              title: Text('$species – ${len ?? '-'} cm / ${wgt ?? '-'} g'),
              subtitle: Text('$member • $water'),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
  }
}
