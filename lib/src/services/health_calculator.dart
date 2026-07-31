import '../models/health_profile.dart';

class HealthCalculator {
  const HealthCalculator._();

  static double bmi(HealthProfile profile) {
    final meters = profile.heightCm / 100;
    if (meters <= 0) {
      return 0;
    }
    return profile.weightKg / (meters * meters);
  }

  static String bmiLabel(double value, {String lang = 'tr'}) {
    if (value <= 0) {
      return lang == 'en' ? 'Missing data' : 'Eksik veri';
    }
    if (value < 18.5) {
      return lang == 'en' ? 'Underweight' : 'Düşük';
    }
    if (value < 25) {
      return lang == 'en' ? 'Balanced' : 'Dengeli';
    }
    if (value < 30) {
      return lang == 'en' ? 'Overweight' : 'Yüksek';
    }
    return lang == 'en' ? 'Obese' : 'Çok yüksek';
  }

  static int dailyWaterTargetMl(HealthProfile profile, {double? currentTemp}) {
    final base = profile.weightKg * 35;
    final ageAdjustment = profile.age >= 55 ? -150 : 0;
    
    int tempAdjustment = 0;
    if (currentTemp != null) {
      if (currentTemp >= 30) {
        tempAdjustment = 500;
      } else if (currentTemp >= 25) {
        tempAdjustment = 250;
      }
    }
    
    return (base + profile.activity.waterBoostMl + ageAdjustment + tempAdjustment)
        .clamp(1400, 4800)
        .round();
  }

  static double recommendedSleepHours(HealthProfile profile) {
    double base = 8;
    if (profile.age < 18) base = 9;
    if (profile.age > 64) base = 7;
    if (profile.activity == ActivityLevel.active) base += 0.5;
    if (profile.activity == ActivityLevel.athletic) base += 1;
    return base;
  }

  static int todayWaterMl(HealthProfile profile) {
    final today = DateTime.now();
    return profile.waterLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .fold<int>(0, (sum, log) => sum + log.amountMl);
  }

  static double waterProgress(HealthProfile profile, {double? currentTemp}) {
    final target = dailyWaterTargetMl(profile, currentTemp: currentTemp);
    if (target <= 0) return 0;
    return (todayWaterMl(profile) / target).clamp(0, 1);
  }

  static List<DailyWater> getWeeklyWaterData(HealthProfile profile) {
    return getHistoricalWaterData(profile, days: 7);
  }

  static List<DailyWater> getHistoricalWaterData(HealthProfile profile, {int days = 7}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowStart = todayStart.subtract(Duration(days: days - 1));
    
    final Map<int, int> amounts = {for (var i = 0; i < days; i++) i: 0};
    
    for (final log in profile.waterLogs) {
      final logDay = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final difference = logDay.difference(windowStart).inDays;
      if (difference >= 0 && difference < days) {
        amounts[difference] = (amounts[difference] ?? 0) + log.amountMl;
      }
    }

    final dayKeys = ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'];
    final result = <DailyWater>[];
    
    for (var i = 0; i < days; i++) {
      final date = windowStart.add(Duration(days: i));
      final isToday = date.isAtSameMomentAs(todayStart);
      final key = dayKeys[date.weekday - 1];
      result.add(DailyWater(key, amounts[i]!, date, isToday: isToday));
    }
    
    return result;
  }

  static List<DailySleep> getWeeklySleepData(HealthProfile profile) {
    return getHistoricalSleepData(profile, days: 7);
  }

  static List<DailySleep> getHistoricalSleepData(HealthProfile profile, {int days = 7}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowStart = todayStart.subtract(Duration(days: days - 1));
    
    final Map<int, double> hours = {for (var i = 0; i < days; i++) i: 0.0};
    final Map<int, String> feelings = {for (var i = 0; i < days; i++) i: ''};

    for (final log in profile.sleepLogs) {
      final logDay = DateTime(log.date.year, log.date.month, log.date.day);
      final difference = logDay.difference(windowStart).inDays;
      if (difference >= 0 && difference < days) {
        hours[difference] = (hours[difference] ?? 0.0) + log.hours;
        feelings[difference] = log.feeling;
      }
    }

    final dayKeys = ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'];
    final result = <DailySleep>[];
    
    for (var i = 0; i < days; i++) {
      final date = windowStart.add(Duration(days: i));
      final isToday = date.isAtSameMomentAs(todayStart);
      final key = dayKeys[date.weekday - 1];
      result.add(DailySleep(key, hours[i]!, date, isToday: isToday, feeling: feelings[i]!));
    }
    
    return result;
  }
}

class DailyWater {
  final String dayName;
  final int amountMl;
  final bool isToday;
  final DateTime date;

  const DailyWater(this.dayName, this.amountMl, this.date, {this.isToday = false});
}

class DailySleep {
  final String dayName;
  final double hours;
  final bool isToday;
  final String feeling;
  final DateTime date;

  const DailySleep(this.dayName, this.hours, this.date, {this.isToday = false, this.feeling = ''});
}
