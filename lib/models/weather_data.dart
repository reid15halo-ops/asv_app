import 'dart:math';

/// Wetter-Datenmodell
class WeatherData {
  final double temperature; // Celsius
  final double feelsLike; // Gefühlte Temperatur
  final int humidity; // Luftfeuchtigkeit in %
  final double pressure; // Luftdruck in hPa
  final double windSpeed; // Windgeschwindigkeit in m/s
  final int cloudiness; // Bewölkung in %
  final String description; // Wetterbeschreibung
  final String icon; // Wetter-Icon Code
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.cloudiness,
    required this.description,
    required this.icon,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
  });

  /// Prüft ob Bedingungen gut zum Angeln sind
  bool get isFishingWeatherGood {
    // Ideale Bedingungen:
    // - Leichter Wind (2-8 m/s)
    // - Nicht zu heiß (8-25°C)
    // - Mittlere Bewölkung (30-70%)
    // - Stabiler Luftdruck (1010-1030 hPa)

    final hasGoodWind = windSpeed >= 2 && windSpeed <= 8;
    final hasGoodTemp = temperature >= 8 && temperature <= 25;
    final hasGoodClouds = cloudiness >= 30 && cloudiness <= 70;
    final hasStablePressure = pressure >= 1010 && pressure <= 1030;

    return hasGoodWind && hasGoodTemp && hasGoodClouds && hasStablePressure;
  }

  /// Gibt Wetter-Score zurück (0-100)
  int get fishingScore {
    int score = 50; // Basis-Score

    // Temperatur-Score (-20 bis +20)
    if (temperature >= 15 && temperature <= 22) {
      score += 20;
    } else if (temperature >= 8 && temperature <= 25) {
      score += 10;
    } else if (temperature < 5 || temperature > 30) {
      score -= 20;
    }

    // Wind-Score (-10 bis +20)
    if (windSpeed >= 2 && windSpeed <= 5) {
      score += 20;
    } else if (windSpeed > 5 && windSpeed <= 8) {
      score += 10;
    } else if (windSpeed > 10) {
      score -= 10;
    }

    // Bewölkungs-Score (-10 bis +15)
    if (cloudiness >= 40 && cloudiness <= 60) {
      score += 15;
    } else if (cloudiness >= 20 && cloudiness <= 80) {
      score += 5;
    } else if (cloudiness < 10 || cloudiness > 90) {
      score -= 10;
    }

    // Luftdruck-Score (-15 bis +15)
    if (pressure >= 1013 && pressure <= 1023) {
      score += 15;
    } else if (pressure >= 1010 && pressure <= 1030) {
      score += 5;
    } else if (pressure < 1000 || pressure > 1035) {
      score -= 15;
    }

    return score.clamp(0, 100);
  }

  /// Gibt Wetter-Qualität als Text zurück
  String get fishingQuality {
    final score = fishingScore;
    if (score >= 80) return 'Ausgezeichnet';
    if (score >= 65) return 'Sehr gut';
    if (score >= 50) return 'Gut';
    if (score >= 35) return 'Mäßig';
    return 'Schlecht';
  }

  /// Formatierte Temperatur
  String get temperatureFormatted => '${temperature.round()}°C';

  /// Formatierte Windgeschwindigkeit
  String get windSpeedFormatted {
    final kmh = (windSpeed * 3.6).round();
    return '$kmh km/h';
  }

  /// Formatierte Luftfeuchtigkeit
  String get humidityFormatted => '$humidity%';

  /// Formatierte Bewölkung
  String get cloudinessFormatted => '$cloudiness%';

  /// Formatierter Luftdruck
  String get pressureFormatted => '${pressure.round()} hPa';

  /// Von JSON (OpenWeatherMap API Format)
  factory WeatherData.fromOpenWeatherJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final clouds = json['clouds'] as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble() - 273.15, // Kelvin to Celsius
      feelsLike: (main['feels_like'] as num).toDouble() - 273.15,
      humidity: main['humidity'] as int,
      pressure: (main['pressure'] as num).toDouble(),
      windSpeed: (wind['speed'] as num).toDouble(),
      cloudiness: clouds['all'] as int,
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      sunrise: DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000),
      timestamp: DateTime.now(),
    );
  }

  /// Zu JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feels_like': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'wind_speed': windSpeed,
      'cloudiness': cloudiness,
      'description': description,
      'icon': icon,
      'sunrise': sunrise.toIso8601String(),
      'sunset': sunset.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Beißzeit-Vorhersage
class BiteTimeForecast {
  final DateTime date;
  final List<BiteTimeSlot> slots;
  final MoonPhase moonPhase;
  final int overallScore;

  BiteTimeForecast({
    required this.date,
    required this.slots,
    required this.moonPhase,
    required this.overallScore,
  });

  /// Beste Beißzeit des Tages
  BiteTimeSlot? get bestSlot {
    if (slots.isEmpty) return null;
    return slots.reduce((a, b) => a.score > b.score ? a : b);
  }

  /// Gibt Qualität als Text zurück
  String get qualityText {
    if (overallScore >= 80) return 'Ausgezeichnet';
    if (overallScore >= 65) return 'Sehr gut';
    if (overallScore >= 50) return 'Gut';
    if (overallScore >= 35) return 'Mäßig';
    return 'Schlecht';
  }
}

/// Beißzeit-Slot (Zeitfenster)
class BiteTimeSlot {
  final String name;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int score;
  final BiteQuality quality;

  BiteTimeSlot({
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.quality,
  });

  /// Formatierte Zeitangabe
  String get timeRange {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Beißzeit-Qualität
enum BiteQuality {
  excellent('Ausgezeichnet', 4),
  good('Gut', 3),
  fair('Mäßig', 2),
  poor('Schlecht', 1);

  const BiteQuality(this.displayName, this.value);
  final String displayName;
  final int value;
}

/// Mondphase
enum MoonPhase {
  newMoon('Neumond', 0.0),
  waxingCrescent('Zunehmender Sichelmond', 0.125),
  firstQuarter('Erstes Viertel', 0.25),
  waxingGibbous('Zunehmender Mond', 0.375),
  fullMoon('Vollmond', 0.5),
  waningGibbous('Abnehmender Mond', 0.625),
  lastQuarter('Letztes Viertel', 0.75),
  waningCrescent('Abnehmender Sichelmond', 0.875);

  const MoonPhase(this.displayName, this.phase);
  final String displayName;
  final double phase;

  /// Berechnet Mondphase für ein Datum
  static MoonPhase calculate(DateTime date) {
    // Vereinfachte Mondphasen-Berechnung
    // Basis: Neumond am 6. Januar 2000
    const newMoon2000 = 947187600; // Unix timestamp
    const lunarCycle = 29.53059; // Tage

    final daysSinceNewMoon = (date.millisecondsSinceEpoch / 1000 - newMoon2000) / 86400;
    final phase = (daysSinceNewMoon % lunarCycle) / lunarCycle;

    if (phase < 0.0625) return MoonPhase.newMoon;
    if (phase < 0.1875) return MoonPhase.waxingCrescent;
    if (phase < 0.3125) return MoonPhase.firstQuarter;
    if (phase < 0.4375) return MoonPhase.waxingGibbous;
    if (phase < 0.5625) return MoonPhase.fullMoon;
    if (phase < 0.6875) return MoonPhase.waningGibbous;
    if (phase < 0.8125) return MoonPhase.lastQuarter;
    if (phase < 0.9375) return MoonPhase.waningCrescent;
    return MoonPhase.newMoon;
  }

  /// Gibt Mondphasen-Score zurück (0-100)
  int get fishingScore {
    // Vollmond und Neumond sind am besten
    if (this == MoonPhase.fullMoon || this == MoonPhase.newMoon) {
      return 90;
    }
    // Erstes/Letztes Viertel sind gut
    if (this == MoonPhase.firstQuarter || this == MoonPhase.lastQuarter) {
      return 70;
    }
    // Zunehmend ist besser als abnehmend
    if (this == MoonPhase.waxingCrescent || this == MoonPhase.waxingGibbous) {
      return 60;
    }
    return 50;
  }
}

/// TimeOfDay Helper
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
}
