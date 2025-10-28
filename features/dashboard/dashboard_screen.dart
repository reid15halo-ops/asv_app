import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/providers/member_group_provider.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/models/event.dart';
import 'package:asv_app/features/dashboard/jugend_dashboard.dart';
import 'package:asv_app/widgets/instagram_widget.dart';
import 'package:asv_app/widgets/calendar_widget.dart';

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
          if (user != null)
            IconButton(
              tooltip: 'Profil',
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.account_circle),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gruppenspezifisches Logo
            Center(
              child: Image.asset(
                logo,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 120),
              ),
            ),
            const SizedBox(height: 16),
            // Begrüßung
            Center(
              child: Text(
                'Willkommen, $groupName!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            ElevatedButton(
              onPressed: () => context.push('/catch/new'),
              child: const Text('Fang erfassen'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/catches'),
              icon: const Icon(Icons.phishing),
              label: const Text('Meine Fänge'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push('/ranking'),
              child: const Text('Ranking ansehen'),
            ),
            const SizedBox(height: 24),
            // Kalender Widget
            CalendarWidget(
              filterGroup: memberGroup == MemberGroup.senioren
                  ? EventTargetGroup.senioren
                  : memberGroup == MemberGroup.aktive
                      ? EventTargetGroup.aktive
                      : null,
            ),
            const SizedBox(height: 16),
            // Instagram Widget
            const InstagramWidget(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
