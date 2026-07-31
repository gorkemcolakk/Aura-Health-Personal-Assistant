import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../state/aura_controller.dart';
import 'translation_service.dart';

class InsightService {
  static List<DailyInsight> generateInsights(AuraController controller, String langCode) {
    final List<DailyInsight> insights = [];
    final profile = controller.profile;
    final now = DateTime.now();

    // 1. Water Insight
    if (profile.waterLogs.isNotEmpty) {
      final todayWater = profile.waterLogs
          .where((log) => _isSameDay(log.date, now))
          .fold(0, (sum, log) => sum + log.amountMl);
      
      final yesterdayWater = profile.waterLogs
          .where((log) => _isSameDay(log.date, now.subtract(const Duration(days: 1))))
          .fold(0, (sum, log) => sum + log.amountMl);

      if (todayWater >= profile.dailyWaterGoalMl) {
        insights.add(
          DailyInsight(
            title: TranslationService.get('insight_water_title_goal', langCode),
            message: TranslationService.get('insight_water_msg_goal', langCode),
            type: InsightType.water,
            icon: Icons.water_drop,
            color: Colors.blueAccent,
          )
        );
      } else if (yesterdayWater > 0 && todayWater < yesterdayWater && now.hour > 12) {
        insights.add(
          DailyInsight(
            title: TranslationService.get('insight_water_title_behind', langCode),
            message: TranslationService.get('insight_water_msg_behind', langCode),
            type: InsightType.water,
            icon: Icons.local_drink,
            color: Colors.lightBlue,
          )
        );
      } else if (todayWater == 0 && now.hour > 8) {
        insights.add(
          DailyInsight(
            title: TranslationService.get('insight_water_title_start', langCode),
            message: TranslationService.get('insight_water_msg_start', langCode),
            type: InsightType.water,
            icon: Icons.water_drop_outlined,
            color: Colors.cyan,
          )
        );
      }
    }

    // 2. Sleep Insight
    if (profile.sleepLogs.isNotEmpty) {
      final lastSleep = profile.sleepLogs.last;
      if (_isSameDay(lastSleep.date, now) || _isSameDay(lastSleep.date, now.subtract(const Duration(days: 1)))) {
        if (lastSleep.durationHours >= 7.5) {
          insights.add(
            DailyInsight(
              title: TranslationService.get('insight_sleep_title_good', langCode),
              message: TranslationService.get('insight_sleep_msg_good', langCode),
              type: InsightType.sleep,
              icon: Icons.nights_stay,
              color: Colors.indigo,
            )
          );
        } else if (lastSleep.durationHours < 6) {
          insights.add(
            DailyInsight(
              title: TranslationService.get('insight_sleep_title_bad', langCode),
              message: TranslationService.get('insight_sleep_msg_bad', langCode),
              type: InsightType.sleep,
              icon: Icons.bedtime,
              color: Colors.deepPurple,
            )
          );
        }
      }
    }

    // 3. Mindfulness Insight
    final todayBreath = profile.breathLogs.where((log) => _isSameDay(log.date, now)).isNotEmpty;
    if (!todayBreath && now.hour > 10) {
      insights.add(
        DailyInsight(
          title: TranslationService.get('insight_mind_title_reminder', langCode),
          message: TranslationService.get('insight_mind_msg_reminder', langCode),
          type: InsightType.mindfulness,
          icon: Icons.self_improvement,
          color: Colors.teal,
        )
      );
    } else if (todayBreath) {
      insights.add(
        DailyInsight(
          title: TranslationService.get('insight_mind_title_done', langCode),
          message: TranslationService.get('insight_mind_msg_done', langCode),
          type: InsightType.mindfulness,
          icon: Icons.spa,
          color: Colors.green,
        )
      );
    }

    // 4. General Encouragement (if list is empty)
    if (insights.isEmpty) {
      insights.add(
        DailyInsight(
          title: TranslationService.get('insight_general_title', langCode),
          message: TranslationService.get('insight_general_msg', langCode),
          type: InsightType.general,
          icon: Icons.favorite,
          color: Colors.pinkAccent,
        )
      );
    }

    // Sort or shuffle, or just return top 3
    return insights.take(3).toList();
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
