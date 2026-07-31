import 'package:flutter/material.dart';

enum InsightType {
  water,
  sleep,
  medication,
  mindfulness,
  general
}

class DailyInsight {
  final String title;
  final String message;
  final InsightType type;
  final IconData icon;
  final Color color;

  const DailyInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.color,
  });
}
