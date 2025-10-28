import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asv_app/models/weather_data.dart';
import 'package:asv_app/services/weather_service.dart';

/// Provider für Wetterdaten
final weatherProvider = FutureProvider<WeatherData?>((ref) async {
  final service = WeatherService();
  return await service.getCurrentWeather();
});

/// Provider für Beißzeit-Vorhersage
final biteTimeForecastProvider = FutureProvider<BiteTimeForecast?>((ref) async {
  final weatherAsync = await ref.watch(weatherProvider.future);
  if (weatherAsync == null) return null;

  final service = WeatherService();
  return service.calculateBiteTimes(weatherAsync, DateTime.now());
});

/// Weather & Bite Time Screen
class WeatherBiteScreen extends ConsumerWidget {
  const WeatherBiteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final forecastAsync = ref.watch(biteTimeForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wetter & Beißzeiten'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(weatherProvider);
              ref.invalidate(biteTimeForecastProvider);
            },
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(biteTimeForecastProvider);
        },
        child: weatherAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Wetterdaten nicht verfügbar'),
                const SizedBox(height: 8),
                Text(
                  'Demo-Modus aktiv',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          data: (weather) {
            if (weather == null) {
              return const Center(child: Text('Keine Wetterdaten verfügbar'));
            }

            return forecastAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Fehler bei Vorhersage')),
              data: (forecast) {
                if (forecast == null) {
                  return const Center(child: Text('Keine Vorhersage verfügbar'));
                }

                return _buildContent(context, weather, forecast);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherData weather, BiteTimeForecast forecast) {
    final service = WeatherService();
    final recommendation = service.getRecommendation(weather, forecast);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wetter-Karte
          _buildWeatherCard(context, weather),
          const SizedBox(height: 16),

          // Beißzeit-Score-Karte
          _buildScoreCard(context, weather, forecast),
          const SizedBox(height: 16),

          // Empfehlung
          _buildRecommendationCard(context, recommendation),
          const SizedBox(height: 16),

          // Mondphase
          _buildMoonPhaseCard(context, forecast.moonPhase),
          const SizedBox(height: 24),

          // Beißzeiten-Timeline
          Text(
            'Beißzeiten Heute',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...forecast.slots.map((slot) => _buildBiteTimeSlot(context, slot)),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherData weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Großostheim',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weather.temperatureFormatted,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      weather.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Icon(
                  _getWeatherIcon(weather.icon),
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  context,
                  Icons.water_drop,
                  'Feuchtigkeit',
                  weather.humidityFormatted,
                ),
                _buildWeatherDetail(
                  context,
                  Icons.air,
                  'Wind',
                  weather.windSpeedFormatted,
                ),
                _buildWeatherDetail(
                  context,
                  Icons.speed,
                  'Luftdruck',
                  weather.pressureFormatted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    WeatherData weather,
    BiteTimeForecast forecast,
  ) {
    return Card(
      color: _getScoreColor(forecast.overallScore).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getScoreColor(forecast.overallScore),
              ),
              child: Center(
                child: Text(
                  '${forecast.overallScore}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beißzeiten-Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    forecast.qualityText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(forecast.overallScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: forecast.overallScore / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: _getScoreColor(forecast.overallScore),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String recommendation) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                recommendation,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseCard(BuildContext context, MoonPhase moonPhase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              _getMoonIcon(moonPhase),
              size: 48,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mondphase',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moonPhase.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Angel-Score: ${moonPhase.fishingScore}/100',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiteTimeSlot(BuildContext context, BiteTimeSlot slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Quality Indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getQualityColor(slot.quality),
              ),
              child: Center(
                child: Text(
                  '${slot.score}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.timeRange,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _getQualityIcon(slot.quality),
              color: _getQualityColor(slot.quality),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02')) return Icons.wb_cloudy;
    if (iconCode.startsWith('03')) return Icons.cloud;
    if (iconCode.startsWith('04')) return Icons.cloud_queue;
    if (iconCode.startsWith('09')) return Icons.grain;
    if (iconCode.startsWith('10')) return Icons.beach_access;
    if (iconCode.startsWith('11')) return Icons.flash_on;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    if (iconCode.startsWith('50')) return Icons.blur_on;
    return Icons.wb_sunny;
  }

  IconData _getMoonIcon(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return Icons.brightness_1;
      case MoonPhase.waxingCrescent:
      case MoonPhase.waxingGibbous:
        return Icons.brightness_2;
      case MoonPhase.firstQuarter:
        return Icons.brightness_3;
      case MoonPhase.fullMoon:
        return Icons.brightness_1_outlined;
      case MoonPhase.waningGibbous:
      case MoonPhase.waningCrescent:
        return Icons.brightness_4;
      case MoonPhase.lastQuarter:
        return Icons.brightness_5;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getQualityColor(BiteQuality quality) {
    switch (quality) {
      case BiteQuality.excellent:
        return Colors.green;
      case BiteQuality.good:
        return Colors.lightGreen;
      case BiteQuality.fair:
        return Colors.orange;
      case BiteQuality.poor:
        return Colors.red;
    }
  }

  IconData _getQualityIcon(BiteQuality quality) {
    switch (quality) {
      case BiteQuality.excellent:
        return Icons.star;
      case BiteQuality.good:
        return Icons.thumb_up;
      case BiteQuality.fair:
        return Icons.remove_circle_outline;
      case BiteQuality.poor:
        return Icons.thumb_down;
    }
  }
}
