import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/leaderboard_entry.dart';
import 'package:asv_app/providers/leaderboard_provider.dart';
import 'package:asv_app/theme/theme.dart';

/// Leaderboard-Screen zeigt Top 100 Spieler nach XP sortiert
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar mit Gradient
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: JugendGradients.purpleGradient,
                  ),
                  child: FlexibleSpaceBar(
                    title: const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: JugendGradients.purpleGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: leaderboardAsync.when(
                    data: (entries) => _buildLeaderboardContent(
                      context,
                      entries,
                      currentUser?.id,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Fehler beim Laden',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(leaderboardProvider.notifier).refresh();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(
    BuildContext context,
    List<LeaderboardEntry> entries,
    String? currentUserId,
  ) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Noch keine Spieler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sei der Erste der XP sammelt!',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Trenne Top 3 vom Rest
    final topThree = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(leaderboardProvider.notifier).refresh();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 3 Podium
          if (topThree.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Top 3',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            _buildPodium(context, topThree, currentUserId),
            const SizedBox(height: 24),
          ],

          // Rest der Liste
          if (rest.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Weitere Spieler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rest.length,
              itemBuilder: (context, index) {
                final entry = rest[index];
                final isCurrentUser = entry.isCurrentUser(currentUserId);
                return _buildLeaderboardTile(
                  context,
                  entry,
                  isCurrentUser,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Baut das Podium für Top 3
  Widget _buildPodium(
    BuildContext context,
    List<LeaderboardEntry> topThree,
    String? currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Platz (Silber)
          if (topThree.length >= 2)
            Expanded(
              child: _buildPodiumCard(
                context,
                topThree[1],
                2,
                Colors.grey.shade400,
                Icons.looks_two,
                topThree[1].isCurrentUser(currentUserId),
                height: 140,
              ),
            ),
          const SizedBox(width: 8),

          // 1. Platz (Gold)
          if (topThree.isNotEmpty)
            Expanded(
              child: _buildPodiumCard(
                context,
                topThree[0],
                1,
                Colors.amber,
                Icons.looks_one,
                topThree[0].isCurrentUser(currentUserId),
                height: 180,
              ),
            ),
          const SizedBox(width: 8),

          // 3. Platz (Bronze)
          if (topThree.length >= 3)
            Expanded(
              child: _buildPodiumCard(
                context,
                topThree[2],
                3,
                Colors.brown.shade300,
                Icons.looks_3,
                topThree[2].isCurrentUser(currentUserId),
                height: 120,
              ),
            ),
        ],
      ),
    );
  }

  /// Baut eine Podium-Karte für Top 3
  Widget _buildPodiumCard(
    BuildContext context,
    LeaderboardEntry entry,
    int rank,
    Color color,
    IconData icon,
    bool isCurrentUser,
    {double height = 150},
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isCurrentUser ? color.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: color, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            entry.displayNameOrDefault,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isCurrentUser ? color : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${entry.level}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.xpPoints} XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baut eine Leaderboard-Zeile für die restlichen Spieler
  Widget _buildLeaderboardTile(
    BuildContext context,
    LeaderboardEntry entry,
    bool isCurrentUser,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          entry.displayNameOrDefault,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.stars, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text('Level ${entry.level}'),
            const SizedBox(width: 12),
            Icon(Icons.catching_pokemon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text('${entry.totalCatches} Fänge'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.xpPoints}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text(
              'XP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
