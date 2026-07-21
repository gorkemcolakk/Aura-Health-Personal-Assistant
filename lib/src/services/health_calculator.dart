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

  static double waterProgress(HealthProfile profile) {
    final target = dailyWaterTargetMl(profile);
    if (target <= 0) {
      return 0;
    }
    return (profile.waterConsumedMl / target).clamp(0, 1);
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
}

class DailyWater {
  final String dayName;
  final int amountMl;
  final bool isToday;

  const DailyWater(this.dayName, this.amountMl, {this.isToday = false});
}
