import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASV Dashboard'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Abmelden',
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Willkommen!'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push('/catch/new'),
            child: const Text('Fang erfassen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/ranking'),
            child: const Text('Ranking ansehen'),
          ),
        ]),
      ),
    );
  }
}
