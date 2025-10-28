import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/providers/member_group_provider.dart';

/// Admin-Screen zum Testen der verschiedenen Benutzergruppen-Layouts
/// Nur für Entwicklung und Testing!
class MemberGroupAdminScreen extends ConsumerWidget {
  const MemberGroupAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGroup = ref.watch(memberGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzergruppen Tester'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Aktuelle Gruppe',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentGroup?.displayName ?? 'Nicht gesetzt',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentGroup != null)
                      Image.asset(
                        currentGroup.logoAsset,
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 100),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gruppe wechseln (für Testing)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(memberGroupProvider.notifier).setMemberGroup(MemberGroup.jugend);
              },
              icon: const Icon(Icons.child_care),
              label: const Text('Jugend'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(memberGroupProvider.notifier).setMemberGroup(MemberGroup.aktive);
              },
              icon: const Icon(Icons.person),
              label: const Text('Aktive'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(memberGroupProvider.notifier).setMemberGroup(MemberGroup.senioren);
              },
              icon: const Icon(Icons.elderly),
              label: const Text('Senioren'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Farbvorschau',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _ColorBox('Primary', Theme.of(context).colorScheme.primary),
                  _ColorBox('Secondary', Theme.of(context).colorScheme.secondary),
                  _ColorBox('Tertiary', Theme.of(context).colorScheme.tertiary),
                  _ColorBox('Error', Theme.of(context).colorScheme.error),
                  _ColorBox('Surface', Theme.of(context).colorScheme.surface),
                  _ColorBox('Background', Theme.of(context).colorScheme.background),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorBox(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
