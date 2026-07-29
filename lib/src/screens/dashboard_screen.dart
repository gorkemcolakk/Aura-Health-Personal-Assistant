import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/health_profile.dart';
import '../services/health_calculator.dart';
import '../state/aura_controller.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';
import '../widgets/emergency_card.dart';
import 'charts_screen.dart';
import 'mood_entry_sheet.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
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
    final profile = controller.profile;
    final bmi = HealthCalculator.bmi(profile);
    final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
    final waterProgress = HealthCalculator.waterProgress(profile);
    final todayWeekday = DateTime.now().weekday;
    final nextMedication =
        controller.medications
            .where((item) => item.enabled && item.daysOfWeek.contains(todayWeekday))
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
                subtitle: '${profile.age} ${controller.tr('prof_age_suffix')} • ${profile.gender}',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList.list(
              children: [
                // Duygu Durumu Kartı
                _MoodCard(controller: controller),
                const SizedBox(height: 24),

                // 4. Fiziksel Durum
                _sectionTitle(controller.languageCode == 'tr' ? 'Fiziksel Durum' : 'Physical Status', Theme.of(context)),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.straighten,
                        label: controller.tr('dash_height'),
                        value: '${profile.heightCm.toStringAsFixed(0)} cm',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.scale,
                        label: controller.tr('dash_weight'),
                        value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'VKİ',
                        value: bmi.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 1. Acil Durum Kartı
                _EmergencyRow(profile: profile),
                const SizedBox(height: 24),
                
                // 2. Günlük Takip
                _sectionTitle('Günlük Takip', Theme.of(context)),
                _HeroStatus(
                  waterTarget: waterTarget,
                  waterProgress: waterProgress,
                  consumed: HealthCalculator.todayWaterMl(profile),
                  animation: _waveCtrl,
                ),
                if (controller.profile.waterLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _WaterTimelineCard(controller: controller),
                ],
                const SizedBox(height: 12),
                _SleepCard(controller: controller),
                const SizedBox(height: 24),

                // 3. Bugünkü İlaçlarım
                _sectionTitle(controller.languageCode == 'tr' ? 'Bugünkü İlaçlarım' : 'Today\'s Medications', Theme.of(context)),
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
                                controller.tr('dash_no_meds'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(controller.tr('dash_no_meds_sub')),
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
                              color: nextMedication[i].isTakenToday ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFFFFE8D6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              nextMedication[i].isTakenToday ? Icons.check : Icons.medication,
                              color: nextMedication[i].isTakenToday ? Colors.grey : const Color(0xFFE76F51),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                  '${_periodName(nextMedication[i].period, controller.languageCode)} • ${nextMedication[i].mealTiming == 'Aç' ? controller.tr('med_meal_before') : nextMedication[i].mealTiming == 'Tok' ? controller.tr('med_meal_after') : nextMedication[i].mealTiming == 'Yemekle Beraber' ? (controller.languageCode == 'tr' ? 'Yemekle Beraber' : 'With Meal') : controller.tr('med_meal_any')}',
                                  style: TextStyle(
                                    color: nextMedication[i].isTakenToday ? Colors.grey : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final med = nextMedication[i];
                              if (!med.isTakenToday && med.stock != null && med.stock! <= 0) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(controller.languageCode == 'tr' ? 'İlacınız bitti. Lütfen stok güncelleyin.' : 'Medication is out of stock. Please update stock.')),
                                );
                                return;
                              }
                              controller.toggleMedicationTaken(med, !med.isTakenToday);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nextMedication[i].isTakenToday ? Colors.grey.withValues(alpha: 0.2) : Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: nextMedication[i].isTakenToday ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimaryContainer,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              nextMedication[i].isTakenToday 
                                ? (controller.languageCode == 'tr' ? 'Geri Al' : 'Undo') 
                                : (controller.languageCode == 'tr' ? 'İçtim' : 'Take'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < nextMedication.length - 1)
                      const SizedBox(height: 12),
                  ],
                const SizedBox(height: 24),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _periodName(String? period, String lang) {
    if (period == null) return '';
    if (lang == 'tr') return period;
    switch (period) {
      case 'Sabah': return 'Morning';
      case 'Öğle': return 'Noon';
      case 'Akşam': return 'Evening';
      case 'Gece': return 'Night';
      default: return period;
    }
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
    final controller = AuraScope.of(context);
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
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: controller.tr('settings_title'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({
    required this.waterTarget,
    required this.waterProgress,
    required this.consumed,
    required this.animation,
  });

  final int waterTarget;
  final double waterProgress;
  final int consumed;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    return AuraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Su Tüketimi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _WaveCircle(
                  progress: waterProgress,
                  center: '${(consumed / 1000).toStringAsFixed(2)} ${controller.languageCode == 'tr' ? 'Litre' : 'Liters'}',
                  label: controller.tr('dash_water'),
                  animation: animation,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '%${(waterProgress * 100).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.tr('dash_target')} ${(waterTarget / 1000).toStringAsFixed(2)} ${controller.languageCode == 'tr' ? 'Litre' : 'Liters'}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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

void showCustomWaterDialog(BuildContext context, AuraController controller) {
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
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final dateLabel = _isToday(_selectedDate)
        ? widget.controller.tr('day_today')
        : _isYesterday(_selectedDate)
            ? widget.controller.tr('day_yesterday')
            : '${_selectedDate.day}/${_selectedDate.month}';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, media.viewInsets.bottom + 16),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                widget.controller.tr('water_add_custom'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              // Tarih seçici
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    helpText: widget.controller.tr('water_select_date'),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateLabel, style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 100,
                  height: 100,
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
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'ml',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
              min: 50,
              max: 5000,
              label: '${_amount.round()} ml',
              onChanged: (val) {
                setState(() {
                  _amount = val;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Manuel klavye girişi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              height: 40,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
                decoration: InputDecoration(
                  hintText: widget.controller.tr('water_manual_entry'),
                  hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  isDense: true,
                ),
                onSubmitted: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 50 && parsed <= 5000) {
                    setState(() => _amount = parsed.toDouble());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [150, 330, 500, 1000, 2000].map((preset) {
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
              widget.controller.addWater(_amount.round(), date: _selectedDate);
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
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showCustomWaterDialog(context, controller),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 10),
              Text(controller.tr('dash_water_history'), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${(todayTotal / 1000).toStringAsFixed(2)} ${controller.languageCode == 'tr' ? 'Litre' : 'Liters'}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
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
        ),
      ),
    );
  }
}

class _ChartsButton extends StatelessWidget {
  const _ChartsButton({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AuraCard(
      padding: EdgeInsets.zero,
      color: colors.primary.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartsScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.tr('dash_charts'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.tr('dash_charts_sub'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colors.primary, size: 16),
            ],
          ),
        ),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Bugünün uykusunu bul, yoksa null
    final todaySleep = controller.profile.sleepLogs
        .where((l) => l.date.year == today.year && l.date.month == today.month && l.date.day == today.day)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final displaySleep = todaySleep.isNotEmpty ? todaySleep.first : null;
    final target = HealthCalculator.recommendedSleepHours(controller.profile);

    return AuraCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showSleepDialog(context, controller),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined),
                  const SizedBox(width: 10),
                  Text(controller.tr('dash_sleep_track'), style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (displaySleep == null)
                    Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (displaySleep != null) ...[
                Row(
                  children: [
                    Text(
                      '${controller.tr('day_today')}: ${displaySleep.hours} ${controller.tr('sleep_hours_unit')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(displaySleep.feeling.contains('Yorgun') ? '😴 ${controller.tr('feeling_tired')}' : displaySleep.feeling.contains('Normal') ? '😐 ${controller.tr('feeling_normal')}' : '🤩 ${controller.tr('feeling_energetic')}', style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.tr('dash_target')}: ${target.toStringAsFixed(1)} ${controller.tr('sleep_hours_unit')}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.nights_stay, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.languageCode == 'tr' ? 'Bugünün uykusunu girin' : 'Enter today\'s sleep',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.languageCode == 'tr' ? 'Verilerinizi takip etmek için dokunun' : 'Tap to track your data',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

bool _isYesterday(DateTime d) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;
}

void showSleepDialog(BuildContext context, AuraController controller) {
  double hours = 7.5;
  String selectedFeeling = '😐 Normal';
  DateTime selectedDate = DateTime.now();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final dateLabel = _isToday(selectedDate)
              ? controller.tr('day_today')
              : _isYesterday(selectedDate)
                  ? controller.tr('day_yesterday')
                  : '${selectedDate.day}/${selectedDate.month}';

          return AlertDialog(
            title: Text(controller.tr('sleep_add')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tarih seçici
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text('${controller.tr('sleep_date')}: $dateLabel', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          helpText: 'Uyku tarihini seç',
                          useRootNavigator: false,
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Text(controller.tr('btn_change')),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Süre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (hours > 0.5) setState(() => hours -= 0.5);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${hours.toStringAsFixed(1)} ${controller.tr('sleep_hours_unit')}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        if (hours < 24.0) setState(() => hours += 0.5);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('${controller.tr('sleep_feeling')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeelingButton(
                      emoji: '😴',
                      label: controller.tr('feeling_tired'),
                      isSelected: selectedFeeling == '😴 Yorgun',
                      onTap: () => setState(() => selectedFeeling = '😴 Yorgun'),
                    ),
                    _FeelingButton(
                      emoji: '😐',
                      label: controller.tr('feeling_normal'),
                      isSelected: selectedFeeling == '😐 Normal',
                      onTap: () => setState(() => selectedFeeling = '😐 Normal'),
                    ),
                    _FeelingButton(
                      emoji: '🤩',
                      label: controller.tr('feeling_energetic'),
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
                child: Text(controller.tr('btn_cancel')),
              ),
              FilledButton(
                onPressed: () {
                  controller.addSleep(hours, selectedFeeling, date: selectedDate);
                  Navigator.pop(context);
                },
                child: Text(controller.tr('btn_save')),
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
    final controller = AuraScope.of(context);

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
                hasData ? controller.tr('prof_sos_card') : controller.tr('prof_sos_add_info'),
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
                '${controller.tr('dash_target')}: ${target.toStringAsFixed(1)} ${controller.tr('sleep_hours_unit')}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animasyonlu Wave Circle ──────────────────────────────
class _WaveCircle extends StatelessWidget {
  const _WaveCircle({
    required this.progress,
    required this.center,
    required this.label,
    required this.animation,
  });

  final double progress;
  final String center;
  final String label;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavePainter(
              progress: progress,
              phase: animation.value * 2 * pi,
              color: colors.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w900)),
                  Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Wave Painter ─────────────────────────────────────────
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
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 3);

    final waterY = c.dy + r - 2 * r * progress;
    final clipPath = Path()
      ..moveTo(c.dx - r - 10, size.height)
      ..lineTo(c.dx - r - 10, waterY);

    const amp = 5.0;
    const freq = 0.045;
    for (double x = c.dx - r - 10; x <= c.dx + r + 10; x++) {
      clipPath.lineTo(x, waterY + amp * sin(freq * x + phase));
    }
    clipPath..lineTo(c.dx + r + 10, size.height)..close();

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawCircle(c, r, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.45)],
    ).createShader(Rect.fromCircle(center: c, radius: r)));

    final p2 = Path()..moveTo(c.dx - r - 10, waterY + 6);
    for (double x = c.dx - r - 10; x <= c.dx + r + 10; x++) {
      p2.lineTo(x, waterY + 6 + 4 * sin(freq * x + phase + pi / 3));
    }
    p2.lineTo(c.dx + r + 10, waterY + 6); p2.close();
    canvas.drawPath(p2, Paint()..color = color.withValues(alpha: 0.2));
    canvas.restore();

    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false,
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_WavePainter old) => progress != old.progress || phase != old.phase;
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.controller});
  final AuraController controller;

  String _getMoodEmoji(int value) {
    if (value <= 1) return '😣';
    if (value <= 2) return '🙁';
    if (value <= 3) return '😐';
    if (value <= 4) return '🙂';
    return '😁';
  }

  String _getMoodLabel(int value, bool isTr) {
    if (value <= 1) return isTr ? 'Çok Kötü' : 'Very Bad';
    if (value <= 2) return isTr ? 'Kötü' : 'Bad';
    if (value <= 3) return isTr ? 'Nötr' : 'Neutral';
    if (value <= 4) return isTr ? 'İyi' : 'Good';
    return isTr ? 'Harika' : 'Excellent';
  }

  Color _getMoodColor(int value) {
    if (value <= 1) return Colors.redAccent.shade200;
    if (value <= 2) return Colors.orangeAccent;
    if (value <= 3) return Colors.amber.shade400;
    if (value <= 4) return Colors.tealAccent.shade400;
    return Colors.green.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTr = controller.languageCode == 'tr';
    
    // Find today's mood
    final today = DateTime.now();
    final isSameDay = (DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
        
    final todayLogs = controller.profile.moodLogs
        .where((log) => isSameDay(log.timestamp, today))
        .toList();
        
    final hasMood = todayLogs.isNotEmpty;
    final log = hasMood ? todayLogs.first : null;

    final bgColor = hasMood ? _getMoodColor(log!.moodLevel).withValues(alpha: 0.15) : colors.primaryContainer.withValues(alpha: 0.3);
    final fgColor = hasMood ? _getMoodColor(log!.moodLevel) : colors.primary;

    return AuraCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          MoodEntrySheet.show(context, initialLog: log);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                colors.surfaceContainerLowest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: fgColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  hasMood ? _getMoodEmoji(log!.moodLevel) : '🤔',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasMood 
                        ? (isTr ? 'Bugün ${_getMoodLabel(log!.moodLevel, isTr)} Hissediyorsun' : 'You feel ${_getMoodLabel(log!.moodLevel, isTr)} today')
                        : (isTr ? 'Bugün nasıl hissediyorsun?' : 'How are you feeling today?'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasMood 
                        ? (isTr ? 'Güncellemek için dokun' : 'Tap to update')
                        : (isTr ? 'Duygu durumunu kaydetmek için dokun' : 'Tap to log your state of mind'),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
