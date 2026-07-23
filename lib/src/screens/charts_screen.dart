import 'dart:math';

import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('📊 Haftalık Grafikler'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _WaterWaveChart(controller: controller, animation: _waveCtrl),
          const SizedBox(height: 20),
          _SleepBars(controller: controller),
        ],
      ),
    );
  }
}

// ─── Su Dalga Grafiği ──────────────────────────────────────
class _WaterWaveChart extends StatelessWidget {
  const _WaterWaveChart({required this.controller, required this.animation});

  final dynamic controller;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final weeklyData = HealthCalculator.getWeeklyWaterData(controller.profile);
    final target = HealthCalculator.dailyWaterTargetMl(controller.profile);
    final todayMl = HealthCalculator.todayWaterMl(controller.profile);
    final todayPct = target > 0 ? (todayMl / target).clamp(0.0, 1.0) : 0.0;
    final colors = Theme.of(context).colorScheme;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: colors.primary),
              const SizedBox(width: 8),
              Text('Haftalık Su Tüketimi', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                'Hedef ${(target / 1000).toStringAsFixed(2)} L',
                style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bugün — animasyonlu dalga
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _WavePainter(
                      progress: todayPct,
                      phase: animation.value * 2 * pi,
                      color: colors.primary,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(todayMl / 1000).toStringAsFixed(2)} L',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Bugün',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Haftalık mini sütunlar
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.map((day) {
              final pct = target > 0 ? (day.amountMl / target).clamp(0.0, 1.0) : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Text(
                        '${(day.amountMl / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: max(70 * pct, 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: day.isToday
                                ? [colors.primary, colors.primary.withValues(alpha: 0.6)]
                                : [colors.primary.withValues(alpha: 0.35), colors.primary.withValues(alpha: 0.15)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
                          color: day.isToday ? colors.primary : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Uyku Yatay Çubuklar ────────────────────────────────────
class _SleepBars extends StatelessWidget {
  const _SleepBars({required this.controller});

  final dynamic controller;

  Color _feelingColor(String feeling, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (feeling.contains('Enerjik')) return const Color(0xFFFFB300); // Altın
    if (feeling.contains('Yorgun')) return const Color(0xFFE76F51); // Mercan
    if (feeling.contains('Normal')) return colors.primary; // Yeşil
    return colors.surfaceContainerHighest; // Gri (veri yok)
  }

  @override
  Widget build(BuildContext context) {
    final weeklyData = HealthCalculator.getWeeklySleepData(controller.profile);
    final target = HealthCalculator.recommendedSleepHours(controller.profile);
    final colors = Theme.of(context).colorScheme;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, color: colors.secondary),
              const SizedBox(width: 8),
              Text('Haftalık Uyku Düzeni', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('Hedef ${target.toStringAsFixed(0)} saat', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ...weeklyData.map((day) {
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
                    child: Text(day.dayName, style: TextStyle(fontSize: 13, fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600, color: day.isToday ? colors.primary : colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        // Arka plan
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            height: 24,
                            color: colors.surfaceContainerHighest,
                          ),
                        ),
                        // Doluluk
                        if (hasData)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(height: 24, color: barColor),
                            ),
                          ),
                        // Hedef çizgisi
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
          // Lejant
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(context, const Color(0xFFFFB300), 'Enerjik'),
              const SizedBox(width: 16),
              _legendDot(context, colors.primary, 'Normal'),
              const SizedBox(width: 16),
              _legendDot(context, const Color(0xFFE76F51), 'Yorgun'),
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

    // Arka plan
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.07));

    // Halka
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Su seviyesi
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

    // İkinci dalga
    final p2 = Path()..moveTo(c.dx - r - 10, waterY + 6);
    for (double x = c.dx - r - 10; x <= c.dx + r + 10; x++) {
      p2.lineTo(x, waterY + 6 + 4 * sin(freq * x + phase + pi / 3));
    }
    p2.lineTo(c.dx + r + 10, waterY + 6);
    p2.close();
    canvas.drawPath(p2, Paint()..color = color.withValues(alpha: 0.2));

    canvas.restore();

    // Progress ark
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
