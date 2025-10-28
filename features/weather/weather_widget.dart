import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/weather_data.dart';
import 'package:asv_app/services/weather_service.dart';

/// Kompaktes Weather Widget für Dashboard
class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WeatherData?>(
      future: WeatherService().getCurrentWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildErrorCard(context);
        }

        return _buildWeatherCard(context, snapshot.data!);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/weather'),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Wetter lädt...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/weather'),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.grey.shade400),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wetter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tippen für Details',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherData weather) {
    return FutureBuilder<BiteTimeForecast?>(
      future: WeatherService().calculateBiteTimes(weather, DateTime.now()),
      builder: (context, forecastSnapshot) {
        final forecast = forecastSnapshot.data;

        return Card(
          child: InkWell(
            onTap: () => context.push('/weather'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getWeatherIcon(weather.icon),
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weather.temperatureFormatted,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                weather.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (forecast != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(forecast.overallScore).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getScoreColor(forecast.overallScore),
                            ),
                          ),
                          child: Text(
                            '${forecast.overallScore}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(forecast.overallScore),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat(
                        context,
                        Icons.water_drop,
                        weather.humidityFormatted,
                      ),
                      _buildWeatherStat(
                        context,
                        Icons.air,
                        weather.windSpeedFormatted,
                      ),
                      _buildWeatherStat(
                        context,
                        Icons.speed,
                        weather.pressureFormatted,
                      ),
                    ],
                  ),
                  if (forecast != null && forecast.bestSlot != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Beste Zeit: ${forecast.bestSlot!.name} (${forecast.bestSlot!.timeRange})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherStat(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
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

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }
}
