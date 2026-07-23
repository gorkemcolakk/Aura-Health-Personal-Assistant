import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/health_profile.dart';
import '../models/water_log.dart';
import '../services/health_calculator.dart';
import '../state/aura_controller.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';
import '../widgets/emergency_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final profile = controller.profile;
    final bmi = HealthCalculator.bmi(profile);
    final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
    final waterProgress = HealthCalculator.waterProgress(profile);
    final nextMedication =
        controller.medications
            .where((item) => item.enabled)
            .cast<dynamic>()
            .toList()
          ..sort((a, b) => a.timeLabel.compareTo(b.timeLabel));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _Header(
                initials: profile.initials,
                name: profile.name,
                subtitle: '${profile.activity.label} gün • ${profile.age} yaş',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList.list(
              children: [
                _HeroStatus(
                  firstName: profile.name.trim().split(' ').first,
                  bmi: bmi,
                  bmiLabel: HealthCalculator.bmiLabel(bmi),
                  waterTarget: waterTarget,
                  waterProgress: waterProgress,
                  consumed: HealthCalculator.todayWaterMl(profile),
                ),
                const SizedBox(height: 16),
                _EmergencyRow(profile: profile),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.straighten,
                        label: 'Boy',
                        value: '${profile.heightCm.toStringAsFixed(0)} cm',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.scale,
                        label: 'Kilo',
                        value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop_outlined),
                          const SizedBox(width: 10),
                          Text(
                            'Su takibi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Sıfırla',
                            onPressed: controller.resetWater,
                            icon: const Icon(Icons.restart_alt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _WaterButton(
                            label: '+250 ml',
                            onTap: () => controller.addWater(250),
                          ),
                          _WaterButton(
                            label: '+500 ml',
                            onTap: () => controller.addWater(500),
                          ),
                          _WaterButton(
                            label: '+750 ml',
                            onTap: () => controller.addWater(750),
                          ),
                          _WaterButton(
                            label: '+ Özel',
                            icon: Icons.tune,
                            onTap: () => _showCustomWaterDialog(context, controller),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (controller.profile.waterLogs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _WaterTimelineCard(controller: controller),
                ],
                const SizedBox(height: 16),
                _SleepCard(controller: controller),
                const SizedBox(height: 16),
                _WeeklySleepChart(controller: controller),
                const SizedBox(height: 16),
                if (nextMedication.isEmpty)
                  AuraCard(
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8D6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: Color(0xFFE76F51),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bugün planlı ilaç yok',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text('İlaç sekmesinden günlük alarm ekleyebilirsin.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (int i = 0; i < nextMedication.length; i++) ...[
                    AuraCard(
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8D6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Color(0xFFE76F51),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Checkbox(
                            value: nextMedication[i].isTakenToday,
                            onChanged: (val) {
                              if (val != null) {
                                controller.toggleMedicationTaken(nextMedication[i], val);
                              }
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${nextMedication[i].name} • ${nextMedication[i].timeLabel}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: nextMedication[i].isTakenToday ? TextDecoration.lineThrough : null,
                                    color: nextMedication[i].isTakenToday ? Colors.grey : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${nextMedication[i].dosage} • ${nextMedication[i].mealTiming}',
                                  style: TextStyle(
                                    color: nextMedication[i].isTakenToday ? Colors.grey : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < nextMedication.length - 1)
                      const SizedBox(height: 16),
                  ],
                const SizedBox(height: 16),
                _WeeklyWaterChart(controller: controller),
                const SizedBox(height: 16),
                AuraCard(
                  color: const Color(0xFF172026),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFC857),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aura içgörüsü',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hedefin: ${profile.healthGoal}. Su, VKİ ve ilaç düzenini birlikte izleyen asistan hazır.',
                          style: const TextStyle(color: Color(0xFFEAF2EF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.initials,
    required this.name,
    required this.subtitle,
  });

  final String initials;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aura Health',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({
    required this.firstName,
    required this.bmi,
    required this.bmiLabel,
    required this.waterTarget,
    required this.waterProgress,
    required this.consumed,
  });

  final String firstName;
  final double bmi;
  final String bmiLabel;
  final int waterTarget;
  final double waterProgress;
  final int consumed;

  String _getPossessiveSuffix(String name) {
    if (name.isEmpty) return 'in';
    
    final vowels = 'aeıioöuü';
    String lastVowel = 'e';
    for (int i = name.length - 1; i >= 0; i--) {
      if (vowels.contains(name[i].toLowerCase())) {
        lastVowel = name[i].toLowerCase();
        break;
      }
    }
    
    final lastChar = name.toLowerCase()[name.length - 1];
    final endsWithVowel = vowels.contains(lastChar);
    
    if (lastVowel == 'a' || lastVowel == 'ı') {
      return endsWithVowel ? 'nın' : 'ın';
    } else if (lastVowel == 'e' || lastVowel == 'i') {
      return endsWithVowel ? 'nin' : 'in';
    } else if (lastVowel == 'o' || lastVowel == 'u') {
      return endsWithVowel ? 'nun' : 'un';
    } else if (lastVowel == 'ö' || lastVowel == 'ü') {
      return endsWithVowel ? 'nün' : 'ün';
    }
    return 'in';
  }

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isEmpty
                ? 'Sağlık Paneli'
                : "$firstName'${_getPossessiveSuffix(firstName)} Sağlık Paneli",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Ring(
                  progress: waterProgress,
                  center: '${(consumed / 1000).toStringAsFixed(2)} L',
                  label: 'Su',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text('VKİ • $bmiLabel'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: waterProgress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: 8),
                    Text('Hedef ${(waterTarget / 1000).toStringAsFixed(2)} L'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.center,
    required this.label,
  });

  final double progress;
  final String center;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 13,
            backgroundColor: const Color(0xFFE7EFED),
            color: Theme.of(context).colorScheme.primary,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(center, style: Theme.of(context).textTheme.titleLarge),
                Text(label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 14),
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.label,
    required this.onTap,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

void _showCustomWaterDialog(BuildContext context, AuraController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _CustomWaterSheet(controller: controller);
    },
  );
}

class _CustomWaterSheet extends StatefulWidget {
  const _CustomWaterSheet({required this.controller});

  final AuraController controller;

  @override
  State<_CustomWaterSheet> createState() => _CustomWaterSheetState();
}

class _CustomWaterSheetState extends State<_CustomWaterSheet> {
  double _amount = 250;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, media.viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Color(0xFF1E88E5), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Özel Su Ekle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A8C83).withValues(alpha: .06 + (_amount / 1000) * 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A8C83).withValues(alpha: .25),
                      width: 3,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_amount.round()}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: const Color(0xFF1A8C83),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'ml',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1A8C83),
              inactiveTrackColor: const Color(0xFF1A8C83).withValues(alpha: 0.16),
              thumbColor: const Color(0xFF1A8C83),
              overlayColor: const Color(0xFF1A8C83).withValues(alpha: 0.12),
              valueIndicatorColor: const Color(0xFF1A8C83),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: _amount,
              min: 100,
              max: 1000,
              divisions: 18,
              label: '${_amount.round()} ml',
              onChanged: (val) {
                setState(() {
                  _amount = val;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [150, 330, 400, 600].map((preset) {
              final isSelected = _amount.round() == preset;
              return InkWell(
                onTap: () {
                  setState(() {
                    _amount = preset.toDouble();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A8C83)
                        : colors.surfaceContainerHighest.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1A8C83) : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '$preset ml',
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A8C83),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              widget.controller.addWater(_amount.round());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_amount.round()} ml su eklendi.'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Su Ekle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterTimelineCard extends StatelessWidget {
  const _WaterTimelineCard({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final allLogs = controller.profile.waterLogs;
    if (allLogs.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sadece bugünün kayıtları
    final logs = allLogs
        .where((l) =>
            l.timestamp.year == today.year &&
            l.timestamp.month == today.month &&
            l.timestamp.day == today.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (logs.isEmpty) return const SizedBox.shrink();

    final todayTotal = logs.fold<int>(0, (sum, l) => sum + l.amountMl);
    final colors = Theme.of(context).colorScheme;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 10),
              Text('Bugünkü su geçmişi', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${(todayTotal / 1000).toStringAsFixed(2)} L', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.map((log) {
            final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF1E88E5).withValues(alpha: .15), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E88E5), width: 2.5))),
                  const SizedBox(width: 12),
                  Text(timeStr, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(width: 10),
                  Text('${log.amountMl} ml', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      controller.deleteWaterLog(log);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${log.amountMl} ml kayıt silindi.'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                    },
                    child: Icon(Icons.delete_outline, color: colors.error.withValues(alpha: .75), size: 16),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeeklyWaterChart extends StatelessWidget {
  const _WeeklyWaterChart({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final weeklyData = HealthCalculator.getWeeklyWaterData(controller.profile);
    final target = HealthCalculator.dailyWaterTargetMl(controller.profile).toDouble();

    // Find the max value to set the Y-axis correctly
    double maxY = target;
    for (final day in weeklyData) {
      if (day.amountMl > maxY) maxY = day.amountMl.toDouble();
    }
    // Add some padding to the top
    maxY = maxY + (maxY * 0.15);

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Haftalık Su Tüketimi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.round().toString(),
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklyData.length) {
                          return const SizedBox.shrink();
                        }
                        final dayData = weeklyData[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dayData.dayName,
                            style: TextStyle(
                              color: dayData.isToday ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                              fontWeight: dayData.isToday ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: target > 0 ? target : 2000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isReached = day.amountMl >= target;

                  return BarChartGroupData(
                    x: index,
                    showingTooltipIndicators: day.amountMl > 0 ? [0] : [],
                    barRods: [
                      BarChartRodData(
                        toY: day.amountMl.toDouble(),
                        color: isReached ? Theme.of(context).colorScheme.primary : const Color(0xFF78C0A8),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 2,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Günlük Hedef (${target.toInt()} ml)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final sleepLogs = controller.profile.sleepLogs;
    final lastSleep = sleepLogs.isNotEmpty ? sleepLogs.last : null;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_outlined),
              const SizedBox(width: 10),
              Text(
                'Uyku Takibi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lastSleep != null) ...[
            Row(
              children: [
                Text(
                  'Son uyku: ${lastSleep.hours} saat',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  lastSleep.feeling,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSleepDialog(context, controller),
              icon: const Icon(Icons.add),
              label: const Text('+ Uyku Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}

void _showSleepDialog(BuildContext context, AuraController controller) {
  double hours = 7.5;
  String selectedFeeling = '😐 Normal';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Bugün nasıl uyudun?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (hours > 0.5) {
                          setState(() => hours -= 0.5);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${hours.toStringAsFixed(1)} saat',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        if (hours < 24.0) {
                          setState(() => hours += 0.5);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Uyanma Hissi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeelingButton(
                      emoji: '😴',
                      label: 'Yorgun',
                      isSelected: selectedFeeling == '😴 Yorgun',
                      onTap: () => setState(() => selectedFeeling = '😴 Yorgun'),
                    ),
                    _FeelingButton(
                      emoji: '😐',
                      label: 'Normal',
                      isSelected: selectedFeeling == '😐 Normal',
                      onTap: () => setState(() => selectedFeeling = '😐 Normal'),
                    ),
                    _FeelingButton(
                      emoji: '🤩',
                      label: 'Enerjik',
                      isSelected: selectedFeeling == '🤩 Enerjik',
                      onTap: () => setState(() => selectedFeeling = '🤩 Enerjik'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  controller.addSleep(hours, selectedFeeling);
                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _FeelingButton extends StatelessWidget {
  const _FeelingButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A8C83).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF1A8C83) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  const _EmergencyRow({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasData = profile.bloodType.isNotEmpty || profile.allergies.isNotEmpty;

    return AuraCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EmergencyCard(profile: profile)),
          );
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasData ? const Color(0xFFD32F2F) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emergency,
                color: hasData ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasData ? 'Acil Durum Kartı' : 'Acil durum bilgisi ekle',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _WeeklySleepChart extends StatelessWidget {
  const _WeeklySleepChart({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final weeklyData = HealthCalculator.getWeeklySleepData(controller.profile);
    const double target = 7.0; // Daily sleep target in hours

    double maxY = 10.0; // Default max 10 hours
    for (final day in weeklyData) {
      if (day.hours > maxY) maxY = day.hours;
    }
    maxY = maxY + (maxY * 0.15);

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Haftalık Uyku Düzeni',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(1),
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklyData.length) {
                          return const SizedBox.shrink();
                        }
                        final dayData = weeklyData[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dayData.dayName,
                            style: TextStyle(
                              color: dayData.isToday ? Theme.of(context).colorScheme.secondary : Colors.grey.shade600,
                              fontWeight: dayData.isToday ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: target,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isReached = day.hours >= target;

                  return BarChartGroupData(
                    x: index,
                    showingTooltipIndicators: day.hours > 0 ? [0] : [],
                    barRods: [
                      BarChartRodData(
                        toY: day.hours,
                        color: isReached ? Theme.of(context).colorScheme.secondary : Colors.indigo.shade300,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 2,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Hedef: ${target.toInt()} saat',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
