import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/providers/member_provider.dart';
import 'package:asv_app/providers/member_group_provider.dart';

/// Profil/Account Screen - Zeigt Account-Details und Einstellungen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberNotifierProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Profil'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
            tooltip: 'Profil bearbeiten',
          ),
        ],
      ),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(memberNotifierProvider.notifier).refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (member) => _buildProfileContent(context, ref, member, user),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Member? member,
    User? user,
  ) {
    if (member == null) {
      return _buildNoMemberView(context, user);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header mit Avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: member.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            member.profileImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          member.initials,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Gruppe Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.memberGroup.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mitgliedergruppe Auswahl
          _buildGroupSelectionCard(context, ref, member),

          // Account Details
          _buildAccountDetailsCard(context, member, user),

          // Mitgliedschafts-Info
          if (member.joinedAt != null || member.age != null)
            _buildMembershipInfoCard(context, member),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Abmelden',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGroupSelectionCard(BuildContext context, WidgetRef ref, Member member) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Anzeigemodus wählen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Wähle aus, wie die App für dich angezeigt werden soll:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildGroupOption(
              context,
              ref,
              member,
              MemberGroup.jugend,
              Icons.sports_esports,
              'Jugend-Modus',
              'Moderne, lebendige Oberfläche mit Gamification',
              Colors.cyan,
            ),
            const SizedBox(height: 12),
            _buildGroupOption(
              context,
              ref,
              member,
              MemberGroup.aktive,
              Icons.sports_handball,
              'Aktive-Modus',
              'Standard-Ansicht für aktive Mitglieder',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildGroupOption(
              context,
              ref,
              member,
              MemberGroup.senioren,
              Icons.accessibility_new,
              'Senioren-Modus',
              'Übersichtliche Darstellung für Senioren',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupOption(
    BuildContext context,
    WidgetRef ref,
    Member member,
    MemberGroup group,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected = member.memberGroup == group;

    return InkWell(
      onTap: () => _handleGroupChange(context, ref, member, group),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailsCard(BuildContext context, Member member, User? user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Account-Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.person, 'Name', member.fullName),
            if (member.email != null)
              _buildDetailRow(Icons.email, 'E-Mail', member.email!),
            if (user?.email != null && member.email == null)
              _buildDetailRow(Icons.email, 'E-Mail', user!.email!),
            if (member.phone != null)
              _buildDetailRow(Icons.phone, 'Telefon', member.phone!),
            if (member.birthDate != null)
              _buildDetailRow(
                Icons.cake,
                'Geburtstag',
                '${member.birthDate!.day}.${member.birthDate!.month}.${member.birthDate!.year}'
                    '${member.age != null ? ' (${member.age} Jahre)' : ''}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipInfoCard(BuildContext context, Member member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mitgliedschaft',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (member.joinedAt != null)
              _buildDetailRow(
                Icons.event,
                'Mitglied seit',
                '${member.joinedAt!.day}.${member.joinedAt!.month}.${member.joinedAt!.year}'
                    '${member.membershipYears != null ? ' (${member.membershipYears} Jahre)' : ''}',
              ),
            _buildDetailRow(
              Icons.group_work,
              'Gruppe',
              member.memberGroup.displayName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMemberView(BuildContext context, User? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Noch kein Mitgliedsprofil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Erstelle dein Mitgliedsprofil, um alle Funktionen der App zu nutzen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (user != null)
              ElevatedButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.add),
                label: const Text('Profil erstellen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGroupChange(
    BuildContext context,
    WidgetRef ref,
    Member member,
    MemberGroup newGroup,
  ) async {
    if (member.memberGroup == newGroup) return;
    if (member.id == null) return;

    // Zeige Loading-Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(memberRepositoryProvider);
      await repository.updateMemberGroup(member.id!, newGroup);

      // Update Member Provider
      await ref.read(memberNotifierProvider.notifier).refresh();

      // Update Group Provider
      ref.read(memberGroupProvider.notifier).setGroup(newGroup);

      if (context.mounted) {
        Navigator.of(context).pop(); // Schließe Loading-Dialog

        // Zeige Erfolgs-Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anzeigemodus geändert zu: ${newGroup.displayName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigiere zurück zum Dashboard, damit die Änderung sichtbar wird
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Schließe Loading-Dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Ändern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }
}
