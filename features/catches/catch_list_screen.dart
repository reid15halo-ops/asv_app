import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/providers/catch_provider.dart';

/// Catch List Screen - Zeigt alle Fänge mit Filter- und Sortierfunktionen
class CatchListScreen extends ConsumerStatefulWidget {
  const CatchListScreen({super.key});

  @override
  ConsumerState<CatchListScreen> createState() => _CatchListScreenState();
}

class _CatchListScreenState extends ConsumerState<CatchListScreen> {
  String _viewMode = 'all'; // 'all' oder 'mine'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catchNotifierProvider.notifier).loadCatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catchesAsync = ref.watch(catchNotifierProvider);
    final notifier = ref.read(catchNotifierProvider.notifier);
    final hasFilters = notifier.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fänge'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // View Mode Toggle
          PopupMenuButton<String>(
            icon: Icon(_viewMode == 'mine' ? Icons.person : Icons.people),
            onSelected: (value) {
              setState(() => _viewMode = value);
              if (value == 'mine') {
                notifier.loadMyCatches();
              } else {
                notifier.clearFilters();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: 12),
                    Text(_viewMode == 'all' ? '✓ Alle Fänge' : 'Alle Fänge'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mine',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 12),
                    Text(_viewMode == 'mine' ? '✓ Meine Fänge' : 'Meine Fänge'),
                  ],
                ),
              ),
            ],
          ),
          // Filter Button
          IconButton(
            icon: Icon(
              hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasFilters ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtern',
          ),
          // Sort Button
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sortieren',
          ),
        ],
      ),
      body: catchesAsync.when(
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
                onPressed: () => notifier.refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (catches) {
          if (catches.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async => await notifier.refresh(),
            child: Column(
              children: [
                // Filter Chips
                if (hasFilters) _buildActiveFiltersChips(context, notifier),

                // Catch List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: catches.length,
                    itemBuilder: (context, index) {
                      final catch_ = catches[index];
                      return _buildCatchCard(context, catch_);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/catch/new'),
        icon: const Icon(Icons.add),
        label: const Text('Fang erfassen'),
      ),
    );
  }

  Widget _buildCatchCard(BuildContext context, Catch catch_) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (catch_.id != null) {
            context.push('/catch/${catch_.id}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header
            if (catch_.hasPhoto)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  catch_.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.phishing, size: 48, color: Colors.white),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Species Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          catch_.speciesName ?? 'Unbekannte Art',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${catch_.score}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Member Name & Date
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        catch_.memberName ?? 'Unbekannt',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        catch_.dateFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      // Length
                      _buildStatChip(
                        context,
                        Icons.straighten,
                        catch_.lengthFormatted,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      // Weight
                      _buildStatChip(
                        context,
                        Icons.scale,
                        catch_.weightFormatted,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      // Water Body
                      if (catch_.waterBodyName != null)
                        Expanded(
                          child: _buildStatChip(
                            context,
                            Icons.water,
                            catch_.waterBodyName!,
                            Colors.cyan,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phishing,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              _viewMode == 'mine' ? 'Noch keine Fänge erfasst' : 'Keine Fänge gefunden',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _viewMode == 'mine'
                  ? 'Erfasse deinen ersten Fang und verfolge deine Erfolge!'
                  : 'Versuche andere Filter oder erfasse neue Fänge.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/catch/new'),
              icon: const Icon(Icons.add),
              label: const Text('Fang erfassen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context, CatchNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 20),
          const SizedBox(width: 8),
          const Text('Filter:'),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (notifier.filterSpeciesId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Art'),
                        onDeleted: () => notifier.setSpeciesFilter(null),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  if (notifier.filterWaterBodyId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Gewässer'),
                        onDeleted: () => notifier.setWaterBodyFilter(null),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  if (notifier.filterStartDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Zeitraum'),
                        onDeleted: () => notifier.setDateRangeFilter(null, null),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  TextButton(
                    onPressed: () => notifier.clearFilters(),
                    child: const Text('Alle entfernen'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fänge filtern'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter-Optionen:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('Nach Fischart'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeciesFilter(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.water),
                title: const Text('Nach Gewässer'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showWaterBodyFilter(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Nach Zeitraum'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeFilter(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(catchNotifierProvider.notifier).clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Filter zurücksetzen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    final notifier = ref.read(catchNotifierProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sortieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'captured_at_desc',
              groupValue: '${notifier.sortBy}_${notifier.ascending ? "asc" : "desc"}',
              title: const Text('Neueste zuerst'),
              onChanged: (value) {
                notifier.setSorting('captured_at', ascending: false);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'captured_at_asc',
              groupValue: '${notifier.sortBy}_${notifier.ascending ? "asc" : "desc"}',
              title: const Text('Älteste zuerst'),
              onChanged: (value) {
                notifier.setSorting('captured_at', ascending: true);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'weight_g_desc',
              groupValue: '${notifier.sortBy}_${notifier.ascending ? "asc" : "desc"}',
              title: const Text('Schwerste zuerst'),
              onChanged: (value) {
                notifier.setSorting('weight_g', ascending: false);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'length_cm_desc',
              groupValue: '${notifier.sortBy}_${notifier.ascending ? "asc" : "desc"}',
              title: const Text('Längste zuerst'),
              onChanged: (value) {
                notifier.setSorting('length_cm', ascending: false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showDateRangeFilter(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      ref.read(catchNotifierProvider.notifier).setDateRangeFilter(
        picked.start,
        picked.end,
      );
    }
  }

  void _showSpeciesFilter(BuildContext context) async {
    try {
      // Load species from database
      final supa = Supabase.instance.client;
      final data = await supa
          .from('species')
          .select('id, name_de')
          .order('name_de');

      final species = (data as List).cast<Map<String, dynamic>>();

      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fischart wählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: species.length,
              itemBuilder: (context, index) {
                final spec = species[index];
                return ListTile(
                  title: Text(spec['name_de'] as String),
                  trailing: ref.read(catchNotifierProvider.notifier).filterSpeciesId == spec['id']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, spec['id'] as String),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      );

      if (selected != null) {
        ref.read(catchNotifierProvider.notifier).setSpeciesFilter(selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Arten: $e')),
        );
      }
    }
  }

  void _showWaterBodyFilter(BuildContext context) async {
    try {
      // Load water bodies from database
      final supa = Supabase.instance.client;
      final data = await supa
          .from('water_body')
          .select('id, name')
          .order('name');

      final waterBodies = (data as List).cast<Map<String, dynamic>>();

      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gewässer wählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: waterBodies.length,
              itemBuilder: (context, index) {
                final water = waterBodies[index];
                return ListTile(
                  title: Text(water['name'] as String),
                  trailing: ref.read(catchNotifierProvider.notifier).filterWaterBodyId == water['id']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, water['id'] as String),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      );

      if (selected != null) {
        ref.read(catchNotifierProvider.notifier).setWaterBodyFilter(selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Gewässer: $e')),
        );
      }
    }
  }
}
