import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/providers/catch_provider.dart';

/// Catch-Liste Screen zeigt alle Fänge des Users
class CatchListScreen extends ConsumerStatefulWidget {
  const CatchListScreen({super.key});

  @override
  ConsumerState<CatchListScreen> createState() => _CatchListScreenState();
}

class _CatchListScreenState extends ConsumerState<CatchListScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final catchesAsync = ref.watch(catchesProvider);
    final statsAsync = ref.watch(catchStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Fänge'),
        actions: [
          // Jahr-Filter
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Jahr filtern',
            onSelected: (year) {
              setState(() => _selectedYear = year);
              if (year == null) {
                ref.read(catchesProvider.notifier).refresh();
              } else {
                ref.read(catchesProvider.notifier).loadByYear(year);
              }
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return [
                const PopupMenuItem<int?>(
                  value: null,
                  child: Text('Alle Jahre'),
                ),
                const PopupMenuDivider(),
                for (int year = currentYear; year >= currentYear - 5; year--)
                  PopupMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ),
              ];
            },
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: () {
              ref.read(catchesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistik-Header
          _buildStatsHeader(statsAsync),

          // Jahr-Filter Anzeige
          if (_selectedYear != null)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gefiltert nach: $_selectedYear',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedYear = null);
                      ref.read(catchesProvider.notifier).refresh();
                    },
                    child: const Text('Zurücksetzen'),
                  ),
                ],
              ),
            ),

          // Catches Liste
          Expanded(
            child: catchesAsync.when(
              data: (catches) => _buildCatchesList(catches),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                        ref.read(catchesProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/catch/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Deine Statistik',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.catching_pokemon,
                  '${stats['total_catches']}',
                  'Fänge',
                ),
                _buildStatItem(
                  context,
                  Icons.scale,
                  '${(stats['total_weight_g'] / 1000).toStringAsFixed(1)} kg',
                  'Gesamt',
                ),
                _buildStatItem(
                  context,
                  Icons.diversity_3,
                  '${stats['species_count']}',
                  'Arten',
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCatchesList(List<Catch> catches) {
    if (catches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Noch keine Fänge',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Erfasse deinen ersten Fang!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/catch/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('Fang erfassen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(catchesProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: catches.length,
        itemBuilder: (context, index) {
          final catch_ = catches[index];
          return _buildCatchTile(catch_);
        },
      ),
    );
  }

  Widget _buildCatchTile(Catch catch_) {
    return Dismissible(
      key: Key('catch_${catch_.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fang löschen?'),
            content: Text(
              'Möchtest du diesen Fang wirklich löschen?\n\n'
              '${catch_.speciesNameOrDefault} - ${catch_.capturedAtFormatted}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(catchesProvider.notifier).deleteCatch(catch_.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fang gelöscht')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            context.push('/catch/${catch_.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Foto oder Platzhalter
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    image: catch_.hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(catch_.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !catch_.hasPhoto
                      ? Icon(
                          Icons.photo_camera,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catch_.speciesNameOrDefault,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        catch_.waterBodyNameOrDefault,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            catch_.lengthFormatted,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            catch_.weightFormatted,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Datum
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catch_.capturedAtFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
