import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/leaderboard_entry.dart';
import 'package:asv_app/repositories/leaderboard_repository.dart';

/// Provider für Leaderboard-Daten
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, LeaderboardPeriod>(
  (ref, period) async {
    final repo = LeaderboardRepository(Supabase.instance.client);
    return await repo.getLeaderboard(period: period);
  },
);

/// Provider für aktuelle User-Position
final currentUserPositionProvider = FutureProvider.family<LeaderboardEntry?, LeaderboardPeriod>(
  (ref, period) async {
    final repo = LeaderboardRepository(Supabase.instance.client);
    return await repo.getCurrentUserPosition(period: period);
  },
);

/// Leaderboard-Screen mit Rangliste basierend auf Fang-Scores
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.allTime;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_selectedPeriod));
    final currentUserPosAsync = ref.watch(currentUserPositionProvider(_selectedPeriod));

    return Column(
      children: [
        // Period Filter
        _buildPeriodFilter(),

        // Leaderboard Content
        Expanded(
          child: leaderboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Fehler: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(leaderboardProvider(_selectedPeriod)),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
            data: (leaderboard) {
              if (leaderboard.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, size: 80, color: Colors.grey),
                        SizedBox(height: 24),
                        Text(
                          'Noch keine Fänge in diesem Zeitraum',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(leaderboardProvider(_selectedPeriod));
                  ref.invalidate(currentUserPositionProvider(_selectedPeriod));
                },
                child: CustomScrollView(
                  slivers: [
                    // Top 3 Podium
                    if (leaderboard.length >= 3)
                      SliverToBoxAdapter(
                        child: _buildPodium(leaderboard.take(3).toList()),
                      ),

                    // Current User Position (if not in top 3)
                    SliverToBoxAdapter(
                      child: currentUserPosAsync.when(
                        data: (userPos) {
                          if (userPos != null && userPos.rank > 3) {
                            return _buildCurrentUserCard(userPos);
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    // Rankings Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          leaderboard.length > 3 ? 'Weitere Platzierungen' : 'Rangliste',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),

                    // Rest of Rankings
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final startIndex = leaderboard.length >= 3 ? 3 : 0;
                          final entry = leaderboard[startIndex + index];
                          return _buildLeaderboardTile(entry);
                        },
                        childCount: leaderboard.length >= 3 ? leaderboard.length - 3 : leaderboard.length,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: LeaderboardPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(period.shortName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPeriod = period);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // Ordne für Podest: 2. - 1. - 3.
    final second = top3.length > 1 ? top3[1] : null;
    final first = top3[0];
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Platz
          if (second != null)
            _buildPodiumPlace(
              second,
              2,
              Colors.grey.shade400,
              120,
            ),
          const SizedBox(width: 16),
          // 1. Platz
          _buildPodiumPlace(
            first,
            1,
            Colors.amber,
            150,
          ),
          const SizedBox(width: 16),
          // 3. Platz
          if (third != null)
            _buildPodiumPlace(
              third,
              3,
              Colors.brown.shade400,
              100,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntry entry,
    int place,
    Color color,
    double height,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: place == 1 ? 40 : 32,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              entry.initials,
              style: TextStyle(
                fontSize: place == 1 ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 100,
          child: Text(
            entry.memberName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: place == 1 ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            '${entry.totalScore} Pkt',
            style: TextStyle(
              fontSize: place == 1 ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Podest
        Container(
          width: 100,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.6),
                color.withOpacity(0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                place == 1 ? Icons.emoji_events : Icons.military_tech,
                size: place == 1 ? 40 : 32,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                '#$place',
                style: TextStyle(
                  fontSize: place == 1 ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Deine Position',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  entry.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${entry.totalCatches} Fänge',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${entry.totalScore} Punkte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                ),
              ),
            ),
            // Avatar
            CircleAvatar(
              backgroundColor: isCurrentUser
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surfaceVariant,
              child: Text(
                entry.initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.memberName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${entry.totalCatches} Fänge • Ø ${entry.averageScore.toStringAsFixed(1)} Pkt',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalScore}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            const Text(
              'Punkte',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
