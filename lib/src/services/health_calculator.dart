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

  static String bmiLabel(double value) {
    if (value <= 0) {
      return 'Eksik veri';
    }
    if (value < 18.5) {
      return 'Düşük';
    }
    if (value < 25) {
      return 'Dengeli';
    }
    if (value < 30) {
      return 'Yüksek';
    }
    return 'Çok yüksek';
  }

  static int dailyWaterTargetMl(HealthProfile profile) {
    final base = profile.weightKg * 35;
    final ageAdjustment = profile.age >= 55 ? -150 : 0;
    return (base + profile.activity.waterBoostMl + ageAdjustment)
        .clamp(1400, 4800)
        .round();
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

  static double waterProgress(HealthProfile profile) {
    final target = dailyWaterTargetMl(profile);
    if (target <= 0) return 0;
    return (todayWaterMl(profile) / target).clamp(0, 1);
  }

  static List<DailyWater> getWeeklyWaterData(HealthProfile profile) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final mondayStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    
    final Map<int, int> amounts = {for (var i = 0; i < 7; i++) i: 0};
    
    for (final log in profile.waterLogs) {
      final logDay = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final differenceFromMonday = logDay.difference(mondayStart).inDays;
      if (differenceFromMonday >= 0 && differenceFromMonday < 7) {
        amounts[differenceFromMonday] = (amounts[differenceFromMonday] ?? 0) + log.amountMl;
      }
    }

    final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final result = <DailyWater>[];
    
    for (var i = 0; i < 7; i++) {
      final date = mondayStart.add(Duration(days: i));
      final isToday = date.isAtSameMomentAs(todayStart);
      result.add(DailyWater(weekdays[i], amounts[i]!, isToday: isToday));
    }
    
    return result;
  }

  static List<DailySleep> getWeeklySleepData(HealthProfile profile) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final mondayStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    
    final Map<int, double> hours = {for (var i = 0; i < 7; i++) i: 0.0};
    final Map<int, String> feelings = {for (var i = 0; i < 7; i++) i: ''};

    for (final log in profile.sleepLogs) {
      final logDay = DateTime(log.date.year, log.date.month, log.date.day);
      final differenceFromMonday = logDay.difference(mondayStart).inDays;
      if (differenceFromMonday >= 0 && differenceFromMonday < 7) {
        hours[differenceFromMonday] = (hours[differenceFromMonday] ?? 0.0) + log.hours;
        feelings[differenceFromMonday] = log.feeling;
    }

    final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final result = <DailySleep>[];
    
    for (var i = 0; i < 7; i++) {
      final date = mondayStart.add(Duration(days: i));
      final isToday = date.isAtSameMomentAs(todayStart);
      result.add(DailySleep(weekdays[i], hours[i]!, isToday: isToday, feeling: feelings[i]!));
    }
    
    return result;
  }
}

class DailyWater {
  final String dayName;
  final int amountMl;
  final bool isToday;

  const DailyWater(this.dayName, this.amountMl, {this.isToday = false});
}

class DailySleep {
  final String dayName;
  final double hours;
  final bool isToday;
  final String feeling;

  const DailySleep(this.dayName, this.hours, {this.isToday = false, this.feeling = ''});
}
