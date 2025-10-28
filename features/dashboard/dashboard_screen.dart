import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/providers/member_group_provider.dart';
import 'package:asv_app/providers/notification_provider.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/features/dashboard/jugend_dashboard.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Lade die Benutzergruppe beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberGroupProvider.notifier).loadMemberGroup();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final memberGroup = ref.watch(memberGroupProvider);

    // Zeige spezielle Jugend-UI wenn Benutzer zur Jugend gehört
    if (memberGroup == MemberGroup.jugend) {
      return const JugendDashboard();
    }

    // Standard-Dashboard für Aktive und Senioren
    // Bestimme Logo und Farben basierend auf Gruppe
    final logo = memberGroup?.logoAsset ?? 'assets/logos/asv_logo.png';
    final groupName = memberGroup?.displayName ?? 'Mitglied';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASV Dashboard'),
        actions: [
          if (user != null) ...[
            // Notification Bell mit Badge
            _NotificationBadge(),
            IconButton(
              tooltip: 'Abmelden',
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                ref.read(memberGroupProvider.notifier).reset();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Gruppenspezifisches Logo
          Image.asset(
            logo,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 120),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Willkommen, $groupName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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

/// Notification Badge Widget für AppBar
class _NotificationBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verwende Future Provider (funktioniert ohne Realtime)
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        return IconButton(
          tooltip: 'Benachrichtigungen',
          onPressed: () => context.push('/notifications'),
          icon: Badge(
            label: Text('$count'),
            isLabelVisible: count > 0,
            child: const Icon(Icons.notifications),
          ),
        );
      },
      loading: () => IconButton(
        tooltip: 'Benachrichtigungen',
        onPressed: () => context.push('/notifications'),
        icon: const Icon(Icons.notifications),
      ),
      error: (_, __) => IconButton(
        tooltip: 'Benachrichtigungen',
        onPressed: () => context.push('/notifications'),
        icon: const Icon(Icons.notifications),
      ),
    );
  }
}
