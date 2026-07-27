import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/health_calculator.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Detaylı Analiz', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 Gün')),
                ButtonSegment(value: 30, label: Text('1 Ay')),
                ButtonSegment(value: 90, label: Text('3 Ay')),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedDays = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: colors.primary.withValues(alpha: 0.2),
                selectedForegroundColor: colors.primary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _WaterWaveChart(animation: _waveCtrl, days: _selectedDays),
                const SizedBox(height: 20),
                if (_selectedDays == 7)
                  _SleepBars(controller: controller, days: _selectedDays)
                else
                  _SleepLineChart(controller: controller, days: _selectedDays),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Su Grafiği ──────────────────────────────────────
class _WaterWaveChart extends StatelessWidget {
  const _WaterWaveChart({required this.animation, required this.days});

  final Animation<double> animation;
  final int days;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final data = HealthCalculator.getHistoricalWaterData(controller.profile, days: days);
    final target = HealthCalculator.dailyWaterTargetMl(controller.profile);
    
    // Bugün animasyonu için
    final todayMl = HealthCalculator.todayWaterMl(controller.profile);
    final todayPct = target > 0 ? (todayMl / target).clamp(0.0, 1.0) : 0.0;
    
    // Ortalama
    final totalMl = data.fold<int>(0, (sum, item) => sum + item.amountMl);
    final avgMl = data.isEmpty ? 0 : totalMl / data.length;

    final colors = Theme.of(context).colorScheme;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: colors.primary),
              const SizedBox(width: 8),
              Text(controller.tr('chart_water_title'), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${controller.tr('chart_target')} ${(target / 1000).toStringAsFixed(2)} L',
                style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ortalama: ${(avgMl / 1000).toStringAsFixed(2)} L/gün',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),

          if (days == 7)
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WavePainter(progress: todayPct, phase: animation.value * 2 * pi, color: colors.primary),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(todayMl / 1000).toStringAsFixed(2)} L', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w900)),
                            Text(controller.tr('day_today'), style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          if (days == 7) const SizedBox(height: 20),

          // Çizgi grafik
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final day = data[s.spotIndex];
                        return LineTooltipItem(
                          '${DateFormat('dd MMM').format(day.date)}\n${(s.y / 1000).toStringAsFixed(2)} L',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) return const SizedBox.shrink();
                        
                        if (days == 30 && index % 6 != 0 && index != data.length - 1) return const SizedBox.shrink();
                        if (days == 90 && index % 15 != 0 && index != data.length - 1) return const SizedBox.shrink();

                        final dayData = data[index];
                        final label = days == 7 ? controller.tr(dayData.dayName) : DateFormat('dd MMM').format(dayData.date);
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: dayData.isToday ? colors.primary : colors.onSurfaceVariant)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amountMl.toDouble())).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: days == 7,
                      getDotPainter: (spot, percent, barData, index) {
                        final dayData = data[index];
                        return FlDotCirclePainter(
                          radius: 4,
                          color: dayData.isToday ? colors.primary : colors.primary.withValues(alpha: 0.5),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.primary.withValues(alpha: 0.2), colors.primary.withValues(alpha: 0.02)],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: max((target * 1.5).ceilToDouble(), data.fold<double>(0, (m, d) => max(m, d.amountMl.toDouble())) * 1.2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('${controller.tr('chart_target')} ${(target / 1000).toStringAsFixed(2)} L', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Uyku Çizgi Grafiği (30/90 gün için) ────────────────────
class _SleepLineChart extends StatelessWidget {
  const _SleepLineChart({required this.controller, required this.days});
  final dynamic controller;
  final int days;

  @override
  Widget build(BuildContext context) {
    final data = HealthCalculator.getHistoricalSleepData(controller.profile, days: days);
    final target = HealthCalculator.recommendedSleepHours(controller.profile);
    final colors = Theme.of(context).colorScheme;

    final totalHours = data.fold<double>(0, (sum, item) => sum + item.hours);
    final avgHours = data.isEmpty ? 0 : totalHours / data.length;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, color: colors.secondary),
              const SizedBox(width: 8),
              Text(controller.tr('chart_sleep_title'), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${controller.tr('chart_target')} ${target.toStringAsFixed(1)} saat', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ortalama: ${avgHours.toStringAsFixed(1)} saat/gün',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final day = data[s.spotIndex];
                        return LineTooltipItem(
                          '${DateFormat('dd MMM').format(day.date)}\n${s.y.toStringAsFixed(1)} saat',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) return const SizedBox.shrink();
                        
                        if (days == 30 && index % 6 != 0 && index != data.length - 1) return const SizedBox.shrink();
                        if (days == 90 && index % 15 != 0 && index != data.length - 1) return const SizedBox.shrink();

                        final dayData = data[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat('dd MMM').format(dayData.date), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.hours)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colors.secondary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.secondary.withValues(alpha: 0.2), colors.secondary.withValues(alpha: 0.02)],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: max((target * 1.5).ceilToDouble(), data.fold<double>(0, (m, d) => max(m, d.hours)) * 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Uyku Yatay Çubuklar (7 gün için) ────────────────────────
class _SleepBars extends StatelessWidget {
  const _SleepBars({required this.controller, required this.days});

  final dynamic controller;
  final int days;

  Color _feelingColor(String feeling, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (feeling.contains('Enerjik')) return const Color(0xFFFFB300); // Altın
    if (feeling.contains('Yorgun')) return const Color(0xFFE76F51); // Mercan
    if (feeling.contains('Normal')) return colors.primary; // Yeşil
    return colors.surfaceContainerHighest; // Gri (veri yok)
  }

  @override
  Widget build(BuildContext context) {
    final data = HealthCalculator.getHistoricalSleepData(controller.profile, days: days);
    final target = HealthCalculator.recommendedSleepHours(controller.profile);
    final colors = Theme.of(context).colorScheme;
    
    final totalHours = data.fold<double>(0, (sum, item) => sum + item.hours);
    final avgHours = data.isEmpty ? 0 : totalHours / data.length;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, color: colors.secondary),
              const SizedBox(width: 8),
              Text(controller.tr('chart_sleep_title'), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${controller.tr('chart_target')} ${target.toStringAsFixed(1)} saat', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ortalama: ${avgHours.toStringAsFixed(1)} saat/gün',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...data.map((day) {
            final pct = day.hours > 0 ? (day.hours / target).clamp(0.0, 1.0) : 0.0;
            final reached = day.hours >= target;
            final barColor = _feelingColor(day.feeling, context);
            final hasData = day.hours > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(controller.tr(day.dayName), style: TextStyle(fontSize: 13, fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600, color: day.isToday ? colors.primary : colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            height: 24,
                            color: colors.surfaceContainerHighest,
                          ),
                        ),
                        if (hasData)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(height: 24, color: barColor),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 2,
                          child: Align(
                            alignment: Alignment(1.0.clamp(0.0, 1.0) * 2 - 1, 0),
                            child: Container(width: 2, height: 20, color: colors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (reached) const Text('✅ ', style: TextStyle(fontSize: 14)),
                        Text(
                          hasData ? '${day.hours.toStringAsFixed(1)}s' : '-',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hasData ? colors.onSurface : colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendDot(context, const Color(0xFFFFB300), controller.tr('chart_sleep_feeling_energetic')),
              _legendDot(context, colors.primary, controller.tr('chart_sleep_feeling_normal')),
              _legendDot(context, const Color(0xFFE76F51), controller.tr('chart_sleep_feeling_tired')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Wave Painter ───────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;

  _WavePainter({required this.progress, required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.07));
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final waterY = c.dy + r - 2 * r * progress;
    final clipPath = Path()
      ..moveTo(c.dx - r - 10, size.height)
      ..lineTo(c.dx - r - 10, waterY);

    const amp = 5.0;
    const freq = 0.045;
    for (double x = c.dx - r - 10; x <= c.dx + r + 10; x++) {
      clipPath.lineTo(x, waterY + amp * sin(freq * x + phase));
    }
    clipPath
      ..lineTo(c.dx + r + 10, size.height)
      ..close();

    canvas.save();
    canvas.clipPath(clipPath);

    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.45)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final p2 = Path()..moveTo(c.dx - r - 10, waterY + 6);
    for (double x = c.dx - r - 10; x <= c.dx + r + 10; x++) {
      p2.lineTo(x, waterY + 6 + 4 * sin(freq * x + phase + pi / 3));
    }
    p2.lineTo(c.dx + r + 10, waterY + 6);
    p2.close();
    canvas.drawPath(p2, Paint()..color = color.withValues(alpha: 0.2));

    canvas.restore();

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      progress != old.progress || phase != old.phase;
}
