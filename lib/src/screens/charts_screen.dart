import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/health_calculator.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Haftalık Grafikler'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _buildWaterChart(context, controller),
          const SizedBox(height: 20),
          _buildSleepChart(context, controller),
        ],
      ),
    );
  }

  Widget _buildWaterChart(BuildContext context, dynamic controller) {
    final weeklyData = HealthCalculator.getWeeklyWaterData(controller.profile);
    final target = HealthCalculator.dailyWaterTargetMl(controller.profile);

    double maxY = target.toDouble() * 1.5;
    for (final day in weeklyData) {
      if (day.ml > maxY) maxY = day.ml.toDouble();
    }
    maxY = maxY * 1.15;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Haftalık Su Tüketimi', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final dayData = entry.value;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: dayData.ml.toDouble(),
                        color: dayData.isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        final dayData = weeklyData[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: dayData.isToday ? FontWeight.bold : FontWeight.normal,
                              color: dayData.isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: target.toDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == target.toDouble()
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: value == target.toDouble() ? 2 : 1,
                    dashArray: value == target.toDouble() ? [6, 4] : null,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Günlük Hedef (${(target / 1000).toStringAsFixed(0)} ml)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepChart(BuildContext context, dynamic controller) {
    final weeklyData = HealthCalculator.getWeeklySleepData(controller.profile);
    const double target = 7.0;

    double maxY = 10.0;
    for (final day in weeklyData) {
      if (day.hours > maxY) maxY = day.hours;
    }
    maxY = maxY * 1.15;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text('Haftalık Uyku Düzeni', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final dayData = entry.value;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: dayData.hours,
                        color: dayData.isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        final dayData = weeklyData[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: dayData.isToday ? FontWeight.bold : FontWeight.normal,
                              color: dayData.isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: target,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == target
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: value == target ? 2 : 1,
                    dashArray: value == target ? [6, 4] : null,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Hedef: 7 saat',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
