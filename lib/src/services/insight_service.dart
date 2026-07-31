import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../state/aura_controller.dart';
import 'health_calculator.dart';
import 'translation_service.dart';

class InsightService {
  static List<DailyInsight> generateInsights(AuraController controller, String langCode) {
    final List<DailyInsight> insights = [];
    final profile = controller.profile;
    final now = DateTime.now();

    // 1. Water Insight
    final targetWater = HealthCalculator.dailyWaterTargetMl(profile);
    final todayWater = profile.waterLogs
        .where((log) => _isSameDay(log.timestamp, now))
        .fold(0, (sum, log) => sum + log.amountMl);
    
    final yesterdayWater = profile.waterLogs
        .where((log) => _isSameDay(log.timestamp, now.subtract(const Duration(days: 1))))
        .fold(0, (sum, log) => sum + log.amountMl);

    if (todayWater >= targetWater * 1.5) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_champ', langCode),
        message: TranslationService.get('insight_water_msg_champ', langCode),
        type: InsightType.water,
        icon: Icons.emoji_events,
        color: Colors.amber,
      ));
    } else if (todayWater >= targetWater) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_goal', langCode),
        message: TranslationService.get('insight_water_msg_goal', langCode),
        type: InsightType.water,
        icon: Icons.water_drop,
        color: Colors.blueAccent,
      ));
    } else if (todayWater >= targetWater * 0.5) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_half', langCode),
        message: TranslationService.get('insight_water_msg_half', langCode),
        type: InsightType.water,
        icon: Icons.opacity,
        color: Colors.lightBlue,
      ));
    } else if (todayWater > 0 && todayWater < targetWater * 0.5 && now.hour >= 14) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_drink', langCode),
        message: TranslationService.get('insight_water_msg_drink', langCode),
        type: InsightType.water,
        icon: Icons.local_drink,
        color: Colors.cyan,
      ));
    } else if (todayWater == 0 && now.hour >= 8) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_none', langCode),
        message: TranslationService.get('insight_water_msg_none', langCode),
        type: InsightType.water,
        icon: Icons.water_drop_outlined,
        color: Colors.blueGrey,
      ));
    } else if (yesterdayWater > 0 && todayWater < yesterdayWater && now.hour >= 12) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_water_title_behind', langCode),
        message: TranslationService.get('insight_water_msg_behind', langCode),
        type: InsightType.water,
        icon: Icons.water,
        color: Colors.lightBlueAccent,
      ));
    }

    // 2. Sleep Insight
    final todaySleepLogs = profile.sleepLogs.where((log) => _isSameDay(log.date, now) || _isSameDay(log.date, now.subtract(const Duration(days: 1)))).toList();
    if (todaySleepLogs.isNotEmpty) {
      todaySleepLogs.sort((a, b) => a.date.compareTo(b.date));
      final lastSleep = todaySleepLogs.last;
      final yesterdaySleepLogs = profile.sleepLogs.where((log) => _isSameDay(log.date, now.subtract(const Duration(days: 2))) || _isSameDay(log.date, now.subtract(const Duration(days: 1)))).toList();
      yesterdaySleepLogs.sort((a, b) => a.date.compareTo(b.date));
      final prevSleep = yesterdaySleepLogs.isNotEmpty && yesterdaySleepLogs.last.date != lastSleep.date ? yesterdaySleepLogs.last : null;

      if (prevSleep != null && lastSleep.hours > prevSleep.hours && lastSleep.hours >= 7) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_sleep_title_improved', langCode),
          message: TranslationService.get('insight_sleep_msg_improved', langCode),
          type: InsightType.sleep,
          icon: Icons.trending_up,
          color: Colors.teal,
        ));
      } else if (prevSleep != null && lastSleep.hours < prevSleep.hours) {
        if (lastSleep.hours < 8) {
          insights.add(DailyInsight(
            title: TranslationService.get('insight_sleep_title_worse_under_8', langCode),
            message: TranslationService.get('insight_sleep_msg_worse_under_8', langCode),
            type: InsightType.sleep,
            icon: Icons.battery_alert,
            color: Colors.deepOrange,
          ));
        } else {
          insights.add(DailyInsight(
            title: TranslationService.get('insight_sleep_title_less', langCode),
            message: TranslationService.get('insight_sleep_msg_less', langCode),
            type: InsightType.sleep,
            icon: Icons.trending_down,
            color: Colors.orangeAccent,
          ));
        }
      } else if (lastSleep.hours >= 8) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_sleep_title_perfect', langCode),
          message: TranslationService.get('insight_sleep_msg_perfect', langCode),
          type: InsightType.sleep,
          icon: Icons.nights_stay,
          color: Colors.indigoAccent,
        ));
      } else if (lastSleep.hours >= 6) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_sleep_title_good', langCode),
          message: TranslationService.get('insight_sleep_msg_good', langCode),
          type: InsightType.sleep,
          icon: Icons.bedtime,
          color: Colors.indigo,
        ));
      } else {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_sleep_title_bad', langCode),
          message: TranslationService.get('insight_sleep_msg_bad', langCode),
          type: InsightType.sleep,
          icon: Icons.battery_alert,
          color: Colors.deepPurple,
        ));
      }
    } else if (now.hour >= 9) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_sleep_title_none', langCode),
        message: TranslationService.get('insight_sleep_msg_none', langCode),
        type: InsightType.sleep,
        icon: Icons.snooze,
        color: Colors.blueGrey,
      ));
    }

    // 3. Medication Insight
    final todayWeekday = now.weekday;
    final todaysMeds = controller.medications.where((m) => m.enabled && m.daysOfWeek.contains(todayWeekday)).toList();
    
    if (todaysMeds.isNotEmpty) {
      final allTaken = todaysMeds.every((m) => m.isTakenToday);
      if (allTaken) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_med_title_done', langCode),
          message: TranslationService.get('insight_med_msg_done', langCode),
          type: InsightType.general, // No med specific type yet
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ));
      } else {
        // check if any missed
        bool missed = false;
        for (var m in todaysMeds) {
          if (!m.isTakenToday) {
            final parts = m.timeLabel.split(':');
            if (parts.length == 2) {
              final h = int.tryParse(parts[0]) ?? 0;
              final min = int.tryParse(parts[1]) ?? 0;
              final medTime = DateTime(now.year, now.month, now.day, h, min);
              if (now.isAfter(medTime.add(const Duration(minutes: 30)))) {
                missed = true;
                break;
              }
            }
          }
        }
        if (missed) {
          insights.add(DailyInsight(
            title: TranslationService.get('insight_med_title_missed', langCode),
            message: TranslationService.get('insight_med_msg_missed', langCode),
            type: InsightType.general,
            icon: Icons.medication_liquid,
            color: Colors.orange,
          ));
        }
      }
    }

    // 4. Mindfulness Insight
    final todayBreath = profile.breathLogs.where((log) => _isSameDay(log.timestamp, now)).isNotEmpty;
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

    // 5. Mood Insight
    final todayMoods = profile.moodLogs.where((log) => _isSameDay(log.timestamp, now)).toList();
    if (todayMoods.isNotEmpty) {
      todayMoods.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lastMood = todayMoods.last;
      if (lastMood.moodLevel == 5) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_mood_title_great', langCode),
          message: TranslationService.get('insight_mood_msg_great', langCode),
          type: InsightType.general,
          icon: Icons.sentiment_very_satisfied,
          color: Colors.amber,
        ));
      } else if (lastMood.moodLevel <= 2) {
        insights.add(DailyInsight(
          title: TranslationService.get('insight_mood_title_bad', langCode),
          message: TranslationService.get('insight_mood_msg_bad', langCode),
          type: InsightType.general,
          icon: Icons.sentiment_dissatisfied,
          color: Colors.blueGrey,
        ));
      }
    } else if (now.hour >= 11) {
      insights.add(DailyInsight(
        title: TranslationService.get('insight_mood_title_none', langCode),
        message: TranslationService.get('insight_mood_msg_none', langCode),
        type: InsightType.general,
        icon: Icons.mood,
        color: Colors.purpleAccent,
      ));
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
