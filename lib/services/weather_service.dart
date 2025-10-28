import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asv_app/models/weather_data.dart';

/// Weather Service für Wetterdaten und Beißzeit-Vorhersagen
class WeatherService {
  // OpenWeatherMap API Key (sollte in Produktionsumgebung aus Umgebungsvariablen geladen werden)
  static const _apiKey = 'DEMO_KEY'; // Placeholder - User muss eigenen Key eintragen
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Standardkoordinaten: Großostheim, Deutschland
  static const double _defaultLat = 49.9231;
  static const double _defaultLon = 9.0739;

  /// Holt aktuelle Wetterdaten
  Future<WeatherData?> getCurrentWeather({
    double lat = _defaultLat,
    double lon = _defaultLon,
  }) async {
    try {
      // Wenn kein API Key gesetzt, verwende Demo-Daten
      if (_apiKey == 'DEMO_KEY') {
        return _generateDemoWeatherData();
      }

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromOpenWeatherJson(json);
      } else {
        // Fallback zu Demo-Daten bei Fehler
        return _generateDemoWeatherData();
      }
    } catch (e) {
      // Fallback zu Demo-Daten bei Fehler
      return _generateDemoWeatherData();
    }
  }

  /// Generiert Demo-Wetterdaten für Development/Testing
  WeatherData _generateDemoWeatherData() {
    final now = DateTime.now();
    final sunrise = DateTime(now.year, now.month, now.day, 6, 30);
    final sunset = DateTime(now.year, now.month, now.day, 19, 45);

    return WeatherData(
      temperature: 18.5,
      feelsLike: 17.2,
      humidity: 65,
      pressure: 1015.0,
      windSpeed: 3.5,
      cloudiness: 45,
      description: 'Teilweise bewölkt',
      icon: '02d',
      sunrise: sunrise,
      sunset: sunset,
      timestamp: now,
    );
  }

  /// Berechnet Beißzeit-Vorhersage für einen Tag
  BiteTimeForecast calculateBiteTimes(WeatherData weather, DateTime date) {
    final moonPhase = MoonPhase.calculate(date);
    final slots = <BiteTimeSlot>[];

    // Früh-Morgen (kurz vor Sonnenaufgang)
    final dawnStart = weather.sunrise.subtract(const Duration(hours: 1));
    final dawnEnd = weather.sunrise.add(const Duration(hours: 1));
    slots.add(_createBiteSlot(
      'Morgendämmerung',
      'Beste Zeit: Aktivität steigt mit dem Licht',
      dawnStart,
      dawnEnd,
      weather,
      moonPhase,
      isDawn: true,
    ));

    // Vormittag
    slots.add(_createBiteSlot(
      'Vormittag',
      'Gute Zeit nach Sonnenaufgang',
      weather.sunrise.add(const Duration(hours: 1)),
      DateTime(date.year, date.month, date.day, 11, 0),
      weather,
      moonPhase,
    ));

    // Mittag
    slots.add(_createBiteSlot(
      'Mittag',
      'Meist ruhigere Phase',
      DateTime(date.year, date.month, date.day, 11, 0),
      DateTime(date.year, date.month, date.day, 15, 0),
      weather,
      moonPhase,
      isMidDay: true,
    ));

    // Nachmittag
    slots.add(_createBiteSlot(
      'Nachmittag',
      'Aktivität nimmt wieder zu',
      DateTime(date.year, date.month, date.day, 15, 0),
      weather.sunset.subtract(const Duration(hours: 1)),
      weather,
      moonPhase,
    ));

    // Abenddämmerung (beste Zeit!)
    final duskStart = weather.sunset.subtract(const Duration(hours: 1));
    final duskEnd = weather.sunset.add(const Duration(hours: 1));
    slots.add(_createBiteSlot(
      'Abenddämmerung',
      'Beste Zeit: Höchste Aktivität',
      duskStart,
      duskEnd,
      weather,
      moonPhase,
      isDusk: true,
    ));

    // Nacht
    slots.add(_createBiteSlot(
      'Nacht',
      'Abhängig von Mondphase',
      weather.sunset.add(const Duration(hours: 1)),
      DateTime(date.year, date.month, date.day, 23, 59),
      weather,
      moonPhase,
      isNight: true,
    ));

    // Berechne Gesamt-Score
    final avgScore = slots.map((s) => s.score).reduce((a, b) => a + b) ~/ slots.length;
    final weatherBonus = weather.fishingScore ~/ 5; // Max +20
    final moonBonus = moonPhase.fishingScore ~/ 5; // Max +18
    final overallScore = (avgScore + weatherBonus + moonBonus).clamp(0, 100);

    return BiteTimeForecast(
      date: date,
      slots: slots,
      moonPhase: moonPhase,
      overallScore: overallScore,
    );
  }

  /// Erstellt einen Beißzeit-Slot mit Bewertung
  BiteTimeSlot _createBiteSlot(
    String name,
    String description,
    DateTime start,
    DateTime end,
    WeatherData weather,
    MoonPhase moonPhase, {
    bool isDawn = false,
    bool isDusk = false,
    bool isMidDay = false,
    bool isNight = false,
  }) {
    int score = 50; // Basis-Score

    // Zeit-basierte Boni
    if (isDawn) {
      score += 25; // Morgendämmerung ist sehr gut
    } else if (isDusk) {
      score += 30; // Abenddämmerung ist am besten!
    } else if (isMidDay) {
      score -= 20; // Mittag ist meist schlecht
    } else if (isNight) {
      score += moonPhase.fishingScore ~/ 5; // Abhängig von Mondphase
    }

    // Wetter-Bonus
    score += weather.fishingScore ~/ 5; // Max +20

    // Mondphasen-Bonus (außer zur Mittagszeit)
    if (!isMidDay) {
      score += moonPhase.fishingScore ~/ 10; // Max +9
    }

    // Luftdruck-Bonus (stabil ist gut)
    if (weather.pressure >= 1013 && weather.pressure <= 1023) {
      score += 5;
    }

    // Wind-Bonus (leichter Wind ist gut)
    if (weather.windSpeed >= 2 && weather.windSpeed <= 5) {
      score += 5;
    }

    // Bewölkungs-Bonus (nicht zu sonnig, nicht zu bedeckt)
    if (weather.cloudiness >= 30 && weather.cloudiness <= 70) {
      score += 5;
    }

    score = score.clamp(0, 100);

    // Bestimme Qualität basierend auf Score
    BiteQuality quality;
    if (score >= 75) {
      quality = BiteQuality.excellent;
    } else if (score >= 55) {
      quality = BiteQuality.good;
    } else if (score >= 35) {
      quality = BiteQuality.fair;
    } else {
      quality = BiteQuality.poor;
    }

    return BiteTimeSlot(
      name: name,
      description: description,
      startTime: TimeOfDay(hour: start.hour, minute: start.minute),
      endTime: TimeOfDay(hour: end.hour, minute: end.minute),
      score: score,
      quality: quality,
    );
  }

  /// Gibt Beißzeit-Vorhersage für die nächsten Tage zurück
  Future<List<BiteTimeForecast>> getWeekForecast({
    double lat = _defaultLat,
    double lon = _defaultLon,
    int days = 3,
  }) async {
    final forecasts = <BiteTimeForecast>[];
    final weather = await getCurrentWeather(lat: lat, lon: lon);

    if (weather == null) return forecasts;

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));
      forecasts.add(calculateBiteTimes(weather, date));
    }

    return forecasts;
  }

  /// Gibt Empfehlung basierend auf aktuellen Bedingungen
  String getRecommendation(WeatherData weather, BiteTimeForecast forecast) {
    final weatherScore = weather.fishingScore;
    final forecastScore = forecast.overallScore;
    final avgScore = (weatherScore + forecastScore) ~/ 2;

    if (avgScore >= 80) {
      return 'Ausgezeichnete Bedingungen! Perfekte Zeit zum Angeln. ${_getBestTimeRecommendation(forecast)}';
    } else if (avgScore >= 65) {
      return 'Sehr gute Bedingungen. ${_getBestTimeRecommendation(forecast)}';
    } else if (avgScore >= 50) {
      return 'Gute Bedingungen. Mit etwas Geduld sollte es klappen. ${_getBestTimeRecommendation(forecast)}';
    } else if (avgScore >= 35) {
      return 'Mäßige Bedingungen. Erwarte moderate Aktivität. ${_getBestTimeRecommendation(forecast)}';
    } else {
      return 'Schwierige Bedingungen. Probiere es zu den empfohlenen Zeiten: ${_getBestTimeRecommendation(forecast)}';
    }
  }

  String _getBestTimeRecommendation(BiteTimeForecast forecast) {
    final bestSlot = forecast.bestSlot;
    if (bestSlot == null) return '';
    return 'Beste Zeit: ${bestSlot.name} (${bestSlot.timeRange})';
  }
}
