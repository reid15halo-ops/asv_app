import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/catch.dart';
import 'package:asv_app/providers/catch_provider.dart';

/// Catch-Detail Screen zeigt alle Details eines Fangs
class CatchDetailScreen extends ConsumerWidget {
  final int catchId;

  const CatchDetailScreen({
    super.key,
    required this.catchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catchAsync = ref.watch(catchByIdProvider(catchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fang-Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Löschen',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Fang löschen?'),
                  content: const Text(
                    'Möchtest du diesen Fang wirklich löschen?',
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

              if (confirmed == true && context.mounted) {
                await ref.read(catchesProvider.notifier).deleteCatch(catchId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fang gelöscht')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: catchAsync.when(
        data: (catch_) {
          if (catch_ == null) {
            return const Center(
              child: Text('Fang nicht gefunden'),
            );
          }
          return _buildCatchDetails(context, catch_);
        },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatchDetails(BuildContext context, Catch catch_) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto (falls vorhanden)
          if (catch_.hasPhoto)
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(catch_.photoUrl!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fischart
                Text(
                  catch_.speciesNameOrDefault,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Gewässer
                Row(
                  children: [
                    Icon(
                      Icons.water,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      catch_.waterBodyNameOrDefault,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Messwerte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMeasurement(
                      context,
                      Icons.straighten,
                      'Länge',
                      catch_.lengthFormatted,
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildMeasurement(
                      context,
                      Icons.scale,
                      'Gewicht',
                      catch_.weightFormatted,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Datum & Uhrzeit
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  'Fangdatum',
                  catch_.capturedAtFormatted,
                ),
                const SizedBox(height: 12),

                // Fangzeit
                _buildDetailRow(
                  context,
                  Icons.access_time,
                  'Fangzeit',
                  '${catch_.capturedAt.hour.toString().padLeft(2, '0')}:${catch_.capturedAt.minute.toString().padLeft(2, '0')} Uhr',
                ),
                const SizedBox(height: 12),

                // Privacy Level
                _buildDetailRow(
                  context,
                  Icons.lock,
                  'Sichtbarkeit',
                  catch_.privacyLevel == 'club' ? 'Vereinsintern' : catch_.privacyLevel,
                ),
                const SizedBox(height: 24),

                // Metadaten
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metadaten',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fang-ID: ${catch_.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Erfasst am: ${catch_.createdAt.day}.${catch_.createdAt.month}.${catch_.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurement(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
