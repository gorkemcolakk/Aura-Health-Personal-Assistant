import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medication.dart';
import '../state/aura_scope.dart';
import '../state/aura_controller.dart';
import '../widgets/aura_card.dart';

// ─── Global helpers ──────────────────────────────────────────────────────────

const _kPeriodOrder = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

String _localPeriod(String? period, String lang) {
  if (period == null) return '';
  if (lang == 'tr') return period;
  switch (period) {
    case 'Sabah':
      return 'Morning';
    case 'Öğle':
      return 'Noon';
    case 'Akşam':
      return 'Evening';
    case 'Gece':
      return 'Night';
    default:
      return period;
  }
}

String _dayShort(int weekday, String lang) {
  const tr = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];
  const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (lang == 'tr' ? tr : en)[weekday];
}

// ─── Root Screen ─────────────────────────────────────────────────────────────

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final isTr = controller.languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.tr('med_title')),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: isTr ? 'İlaç Planı' : 'Medications'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text(isTr ? 'Tüketimim' : 'My History'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PlanTab(controller: controller),
          _ConsumptionTab(controller: controller),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMedicationSheet(context, controller),
              icon: const Icon(Icons.add),
              label: Text(isTr ? 'İlaç Ekle' : 'Add Med'),
            )
          : null,
    );
  }
}

// ─── Plan Tab ────────────────────────────────────────────────────────────────

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.controller});
  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTr = controller.languageCode == 'tr';

    final stockItems = <String, int>{};
    for (final med in controller.medications) {
      if (med.stock != null) {
        stockItems[med.name] = med.stock!;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        Text(
          controller.tr('med_subtitle'),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
        ),
        if (stockItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            isTr ? 'Kalan İlaç Stoklarım' : 'Remaining Stocks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stockItems.entries.map((entry) {
              final isLow = entry.value <= 5;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final stockCtrl =
                        TextEditingController(text: entry.value.toString());
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                            isTr ? 'Stok Güncelle' : 'Update Stock'),
                        content: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: entry.key,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(isTr ? 'İptal' : 'Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final newStock =
                                  int.tryParse(stockCtrl.text);
                              if (newStock != null) {
                                final firstMed = controller.medications
                                    .firstWhere(
                                        (m) => m.name == entry.key);
                                controller.upsertMedication(firstMed
                                    .copyWith(
                                        stock: newStock,
                                        clearStock: false));
                                Navigator.pop(context);
                              }
                            },
                            child: Text(isTr ? 'Kaydet' : 'Save'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLow
                          ? colors.errorContainer
                          : colors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: isLow
                          ? Border.all(
                              color:
                                  colors.error.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.key}: ${entry.value} ${isTr ? 'adet' : 'pcs'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isLow
                                ? colors.onErrorContainer
                                : colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: isLow
                              ? colors.onErrorContainer
                              : colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(
              color: colors.outlineVariant.withValues(alpha: 0.5)),
        ],
        const SizedBox(height: 24),
        if (controller.medications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.medication_liquid,
                      size: 64,
                      color: colors.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    isTr
                        ? 'Henüz hiç ilaç eklenmedi.'
                        : 'No medications added yet.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          ...controller.medications.map(
            (med) => _MedicationCard(medication: med),
          ),
      ],
    );
  }
}

// ─── Medication Card ─────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});
  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;

    final daysStr = medication.daysOfWeek.length == 7
        ? (controller.languageCode == 'tr' ? 'Her gün' : 'Everyday')
        : medication.daysOfWeek
            .map((d) => _dayShort(d, controller.languageCode))
            .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuraCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final group = controller.medications
                .where((m) => m.groupId == medication.groupId)
                .toList();
            _showAddMedicationSheet(context, controller,
                existingGroup: group.isEmpty ? [medication] : group);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medication.enabled
                        ? colors.primaryContainer.withValues(alpha: 0.5)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    medication.enabled
                        ? Icons.medication
                        : Icons.notifications_off,
                    color: medication.enabled
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_localPeriod(medication.period, controller.languageCode)} • ${medication.timeLabel}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medication.mealTiming == 'Aç' ? controller.tr('med_meal_before') : medication.mealTiming == 'Tok' ? controller.tr('med_meal_after') : medication.mealTiming == 'Yemekle Beraber' ? (controller.languageCode == 'tr' ? 'Yemekle Beraber' : 'With Meal') : controller.tr('med_meal_any')} • $daysStr',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: medication.enabled,
                      onChanged: (value) {
                        controller
                            .upsertMedication(medication.copyWith(enabled: value));
                      },
                    ),
                    IconButton(
                      tooltip: controller.tr('btn_delete'),
                      onPressed: () =>
                          controller.removeMedication(medication),
                      icon: Icon(Icons.delete_outline,
                          color: colors.error.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Consumption Tab ─────────────────────────────────────────────────────────

class _ConsumptionTab extends StatelessWidget {
  const _ConsumptionTab({required this.controller});
  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTr = controller.languageCode == 'tr';

    // Group by groupId (or id if solo)
    final Map<String, List<Medication>> groups = {};
    for (final med in controller.medications) {
      if (!med.enabled) continue;
      final key = (med.groupId != null && med.groupId!.isNotEmpty)
          ? med.groupId!
          : med.id;
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(med);
    }

    // Sort periods within each group (Sabah → Öğle → Akşam → Gece)
    for (final g in groups.values) {
      g.sort((a, b) {
        final ai = _kPeriodOrder.indexOf(a.period ?? '');
        final bi = _kPeriodOrder.indexOf(b.period ?? '');
        return (ai < 0 ? 999 : ai).compareTo(bi < 0 ? 999 : bi);
      });
    }

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 64, color: colors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              isTr
                  ? 'Takip edilecek aktif ilaç bulunamadı.'
                  : 'No active medications to track.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        Text(
          isTr
              ? 'İlaca basarak tüketim takibini açın ve kutulara tıklayarak dozlarınızı işaretleyin.'
              : 'Tap a medication to open its grid. Tap each cell to mark a dose.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...groups.values.map((group) => _ContributionCard(
              group: group,
              controller: controller,
            )),
      ],
    );
  }
}

// ─── Contribution Card ───────────────────────────────────────────────────────

class _ContributionCard extends StatefulWidget {
  const _ContributionCard({required this.group, required this.controller});
  final List<Medication> group;
  final AuraController controller;

  @override
  State<_ContributionCard> createState() => _ContributionCardState();
}

class _ContributionCardState extends State<_ContributionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _anim;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = widget.controller.languageCode;
    final isTr = lang == 'tr';
    final rep = widget.group.first;

    final today = DateTime.now().toIso8601String().split('T').first;
    final takenToday =
        widget.group.where((m) => m.isDoseTaken(today)).length;
    final total = widget.group.length;
    final allTaken = takenToday == total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: allTaken
                            ? colors.primaryContainer
                            : colors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        allTaken ? Icons.check_circle : Icons.medication,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rep.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rep.daysOfWeek.length == 7 ? (isTr ? 'Her gün' : 'Everyday') : rep.daysOfWeek.map((d) => _dayShort(d, lang)).join(', ')} • ${widget.group.map((m) => _localPeriod(m.period, lang)).join(' & ')}',
                            style: TextStyle(
                                color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Today progress badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: allTaken
                            ? colors.primaryContainer
                            : takenToday > 0
                                ? colors.secondaryContainer
                                : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTr
                            ? 'Bugün $takenToday/$total'
                            : 'Today $takenToday/$total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: allTaken
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // ── Grid (animated expand) ───────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Divider(
                      height: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 14),
                  _ContributionGrid(
                    group: widget.group,
                    controller: widget.controller,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contribution Grid ───────────────────────────────────────────────────────

class _ContributionGrid extends StatelessWidget {
  const _ContributionGrid({required this.group, required this.controller});
  final List<Medication> group;
  final AuraController controller;

  static const double _box = 16.0;
  static const double _gap = 3.0;
  static const double _labelW = 34.0;
  static const double _colPad = 6.0;

  String _monthShort(DateTime d, String lang) {
    const tr = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    const en = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return (lang == 'tr' ? tr : en)[d.month];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = controller.languageCode;
    final isTr = lang == 'tr';

    final nowRaw = DateTime.now();
    final today = DateTime(nowRaw.year, nowRaw.month, nowRaw.day);

    // 4 weeks back + 2 weeks forward, aligned to Monday
    final mondayThis = today.subtract(Duration(days: today.weekday - 1));
    final startMonday = mondayThis.subtract(const Duration(days: 28));
    const totalWeeks = 6;

    final weeks = List.generate(
      totalWeeks,
      (i) => startMonday.add(Duration(days: i * 7)),
    );

    final numPeriods = group.length;
    final colW = numPeriods * (_box + _gap) + _colPad;
    final scheduledDays = Set<int>.from(group.first.daysOfWeek);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Week headers ──────────────────────────────────────
          Row(
            children: [
              SizedBox(width: _labelW),
              ...weeks.map((w) => SizedBox(
                    width: colW,
                    child: Text(
                      '${w.day}\n${_monthShort(w, lang)}',
                      style: TextStyle(
                        fontSize: 9, 
                        color: colors.onSurfaceVariant,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 5),
          // ── Day rows Mon – Sun ────────────────────────────────
          for (int dow = 1; dow <= 7; dow++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: _labelW,
                    child: Text(
                      _dayShort(dow, lang),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheduledDays.contains(dow)
                            ? colors.onSurface
                            : colors.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  ...weeks.map((weekStart) {
                    final date = weekStart.add(Duration(days: dow - 1));
                    final dateStr =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final isScheduled = scheduledDays.contains(dow);
                    final isFuture = date.isAfter(today);
                    final isToday = date == today;

                    return SizedBox(
                      width: colW,
                      child: Row(
                        children: isScheduled
                            ? group.map((med) {
                                final taken = med.isDoseTaken(dateStr);
                                Color fill;
                                Color? border;

                                if (isFuture) {
                                  fill = Colors.transparent;
                                  border = colors.outline.withValues(alpha: 0.8);
                                } else if (taken) {
                                  fill = colors.primary;
                                } else {
                                  fill = colors.onSurfaceVariant.withValues(alpha: 0.45);
                                }

                                return GestureDetector(
                                  onTap: isFuture
                                      ? () {
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isTr
                                                    ? 'Gelecek doz: ${date.day} ${_monthShort(date, lang)} ${_dayShort(dow, lang)}'
                                                    : 'Upcoming dose: ${date.day} ${_monthShort(date, lang)} ${_dayShort(dow, lang)}',
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      : () => controller.toggleDoseTaken(
                                          med, dateStr),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: _box,
                                    height: _box,
                                    margin:
                                        EdgeInsets.only(right: _gap),
                                    decoration: BoxDecoration(
                                      color: fill,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: border != null
                                          ? Border.all(color: border)
                                          : null,
                                      boxShadow: isToday && taken
                                          ? [
                                              BoxShadow(
                                                color: colors.primary
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 6,
                                                spreadRadius: 0,
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList()
                            : [
                                SizedBox(
                                  width: colW - _colPad,
                                  height: _box,
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: colors.onSurfaceVariant.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          // ── Legend ────────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: _labelW),
              _legendDot(colors.primary,
                  isTr ? 'Alındı' : 'Taken', colors),
              const SizedBox(width: 14),
              _legendDot(colors.onSurfaceVariant.withValues(alpha: 0.45),
                  isTr ? 'Alınmadı' : 'Missed', colors),
              const SizedBox(width: 14),
              _legendBorder(colors, isTr ? 'Gelecek' : 'Upcoming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, ColorScheme colors) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _legendBorder(ColorScheme colors, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
                color: colors.outline.withValues(alpha: 0.8)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: colors.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Add / Edit Sheet ────────────────────────────────────────────────────────

void _showAddMedicationSheet(
  BuildContext context,
  AuraController controller, {
  List<Medication>? existingGroup,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddMedicationSheet(
        controller: controller, existingGroup: existingGroup),
  );
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet(
      {required this.controller, this.existingGroup});
  final AuraController controller;
  final List<Medication>? existingGroup;

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _name = TextEditingController();
  final _stock = TextEditingController();
  final Map<String, TimeOfDay> _selectedPeriods = {};
  String _mealTiming = 'Farketmez';
  final List<int> _selectedDays = [];
  final List<String> _availablePeriods = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null && widget.existingGroup!.isNotEmpty) {
      final first = widget.existingGroup!.first;
      _name.text = first.name;
      _stock.text = first.stock?.toString() ?? '';
      _mealTiming = first.mealTiming;
      _selectedDays.addAll(first.daysOfWeek);
      for (final med in widget.existingGroup!) {
        if (med.period != null) {
          _selectedPeriods[med.period!] =
              TimeOfDay(hour: med.hour, minute: med.minute);
        }
      }
    }
  }

  void _togglePeriod(String period) {
    setState(() {
      if (_selectedPeriods.containsKey(period)) {
        _selectedPeriods.remove(period);
      } else {
        TimeOfDay defaultTime;
        switch (period) {
          case 'Sabah':
            defaultTime = const TimeOfDay(hour: 9, minute: 0);
            break;
          case 'Öğle':
            defaultTime = const TimeOfDay(hour: 13, minute: 0);
            break;
          case 'Akşam':
            defaultTime = const TimeOfDay(hour: 20, minute: 0);
            break;
          case 'Gece':
            defaultTime = const TimeOfDay(hour: 23, minute: 0);
            break;
          default:
            defaultTime = const TimeOfDay(hour: 9, minute: 0);
        }
        _selectedPeriods[period] = defaultTime;
      }
    });
  }

  String _periodName(String period, String lang) {
    if (lang == 'tr') return period;
    switch (period) {
      case 'Sabah':
        return 'Morning';
      case 'Öğle':
        return 'Noon';
      case 'Akşam':
        return 'Evening';
      case 'Gece':
        return 'Night';
      default:
        return period;
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final tr = widget.controller.tr;
    final isTr = widget.controller.languageCode == 'tr';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, media.viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medication, color: colors.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.existingGroup != null
                      ? (isTr ? 'İlacı Düzenle' : 'Edit Medication')
                      : (isTr ? 'Yeni İlaç Ekle' : 'Add New Medication'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: tr('med_name'),
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: isTr
                    ? 'Stok (Kutudaki Toplam İlaç)'
                    : 'Stock (Total in Box)',
                prefixIcon:
                    const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isTr ? 'Günde Kaç Kere?' : 'How Many Times a Day?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availablePeriods.map((period) {
                final isSelected = _selectedPeriods.containsKey(period);
                return FilterChip(
                  label: Text(
                      _periodName(period, widget.controller.languageCode)),
                  selected: isSelected,
                  onSelected: (_) => _togglePeriod(period),
                  selectedColor: colors.primaryContainer,
                  checkmarkColor: colors.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? colors.primary : colors.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            if (_selectedPeriods.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedPeriods.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final next = await showTimePicker(
                              context: context,
                              initialTime: entry.value,
                              initialEntryMode:
                                  TimePickerEntryMode.input,
                            );
                            if (next != null) {
                              setState(() =>
                                  _selectedPeriods[entry.key] = next);
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                              '${isTr ? "${_periodName(entry.key, widget.controller.languageCode)} Saati:" : "${_periodName(entry.key, widget.controller.languageCode)} Time:"} ${entry.value.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            Text(
              isTr ? 'Hangi Günler?' : 'Which Days?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(isTr ? 'Her gün' : 'Everyday'),
                  selected: _selectedDays.length == 7,
                  onSelected: (val) {
                    setState(() {
                      _selectedDays.clear();
                      if (val) _selectedDays.addAll([1, 2, 3, 4, 5, 6, 7]);
                    });
                  },
                  selectedColor: colors.primaryContainer,
                  checkmarkColor: colors.primary,
                  labelStyle: TextStyle(
                    color: _selectedDays.length == 7
                        ? colors.primary
                        : colors.onSurface,
                    fontWeight: _selectedDays.length == 7
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                ...List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  final label =
                      _dayShort(day, widget.controller.languageCode);
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                    selectedColor: colors.primaryContainer,
                    checkmarkColor: colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colors.primary
                          : colors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _mealChip('Aç', tr('med_meal_before'),
                    Icons.fastfood_outlined),
                _mealChip(
                    'Tok', tr('med_meal_after'), Icons.restaurant),
                _mealChip(
                    'Yemekle Beraber',
                    isTr ? 'Yemekle Beraber' : 'With Meal',
                    Icons.set_meal),
                _mealChip(
                    'Farketmez', tr('med_meal_any'), Icons.all_inclusive),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (_name.text.trim().isEmpty) return;

                if (_selectedDays.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isTr
                              ? 'Lütfen en az bir gün seçin.'
                              : 'Please select at least one day.')),
                    );
                  }
                  return;
                }

                if (_selectedPeriods.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isTr
                              ? 'Lütfen en az bir periyot seçin.'
                              : 'Please select at least one period.')),
                    );
                  }
                  return;
                }

                int? stockVal;
                if (_stock.text.trim().isNotEmpty) {
                  stockVal = int.tryParse(_stock.text.trim());
                }

                final groupId = widget.existingGroup != null &&
                        widget.existingGroup!.isNotEmpty
                    ? widget.existingGroup!.first.groupId ??
                        DateTime.now().microsecondsSinceEpoch.toString()
                    : DateTime.now().microsecondsSinceEpoch.toString();

                // Remove old entries when editing
                if (widget.existingGroup != null) {
                  for (final med in widget.existingGroup!) {
                    await widget.controller.removeMedication(med);
                  }
                }

                for (final entry in _selectedPeriods.entries) {
                  await widget.controller.upsertMedication(
                    Medication(
                      id: DateTime.now().microsecondsSinceEpoch
                              .toString() +
                          entry.key,
                      name: _name.text.trim(),
                      dosage: '',
                      hour: entry.value.hour,
                      minute: entry.value.minute,
                      notes: '',
                      enabled: true,
                      mealTiming: _mealTiming,
                      daysOfWeek: List.from(_selectedDays),
                      stock: stockVal,
                      period: entry.key,
                      groupId: groupId,
                    ),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(widget.existingGroup != null
                            ? (isTr
                                ? 'İlaç güncellendi'
                                : 'Medication updated')
                            : tr('med_add_success'))),
                  );
                }
              },
              child: Text(
                widget.existingGroup != null
                    ? (isTr ? 'Kaydet' : 'Save')
                    : tr('med_btn_add'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealChip(String value, String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _mealTiming == value;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16,
          color: isSelected ? colors.primary : colors.onSurfaceVariant),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _mealTiming = value);
      },
      selectedColor: colors.primaryContainer.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.onSurface,
        fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
