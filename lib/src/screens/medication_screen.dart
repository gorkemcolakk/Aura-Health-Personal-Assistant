import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medication.dart';
import '../state/aura_scope.dart';
import '../state/aura_controller.dart';
import '../widgets/aura_card.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;

    final stockItems = <String, int>{};
    for (final med in controller.medications) {
      if (med.stock != null) {
        stockItems[med.name] = med.stock!;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.tr('med_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
          children: [
            Text(
              controller.tr('med_subtitle'),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
            ),
            if (stockItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                controller.languageCode == 'tr' ? 'Kalan İlaç Stoklarım' : 'Remaining Stocks',
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
                        final stockController = TextEditingController(text: entry.value.toString());
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(controller.languageCode == 'tr' ? 'Stok Güncelle: ${entry.key}' : 'Update Stock: ${entry.key}'),
                            content: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: controller.languageCode == 'tr' ? 'Yeni Stok' : 'New Stock',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(controller.tr('btn_cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final newStock = int.tryParse(stockController.text);
                                  if (newStock != null) {
                                    final firstMed = controller.medications.firstWhere((m) => m.name == entry.key);
                                    controller.upsertMedication(firstMed.copyWith(stock: newStock, clearStock: false));
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text(controller.languageCode == 'tr' ? 'Kaydet' : 'Save'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLow ? colors.errorContainer : colors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: isLow ? Border.all(color: colors.error.withValues(alpha: 0.5)) : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.key}: ${entry.value} ${controller.languageCode == 'tr' ? 'adet' : 'pcs'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLow ? colors.onErrorContainer : colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: isLow ? colors.onErrorContainer : colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Divider(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ],
            const SizedBox(height: 24),
            if (controller.medications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.medication_liquid, size: 64, color: colors.primary.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        controller.languageCode == 'tr' ? 'Henüz hiç ilaç eklenmedi.' : 'No medications added yet.',
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationSheet(context, controller),
        icon: const Icon(Icons.add),
        label: Text(controller.languageCode == 'tr' ? 'İlaç Ekle' : 'Add Med'),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});
  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;
    
    // Formatting days
    final daysStr = medication.daysOfWeek.length == 7
        ? (controller.languageCode == 'tr' ? 'Her gün' : 'Everyday')
        : medication.daysOfWeek.map((d) => _dayNameShort(d, controller.languageCode)).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuraCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final group = controller.medications.where((m) => m.groupId == medication.groupId).toList();
            _showAddMedicationSheet(context, controller, existingGroup: group.isEmpty ? [medication] : group);
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
                    medication.enabled ? Icons.medication : Icons.notifications_off,
                    color: medication.enabled ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_periodName(medication.period, controller.languageCode)} • ${medication.timeLabel}',
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
                        controller.upsertMedication(medication.copyWith(enabled: value));
                      },
                    ),
                    IconButton(
                      tooltip: controller.tr('btn_delete'),
                      onPressed: () => controller.removeMedication(medication),
                      icon: Icon(Icons.delete_outline, color: colors.error.withValues(alpha: 0.7)),
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

  String _dayNameShort(int day, String lang) {
    if (lang == 'tr') {
      switch (day) {
        case 1: return 'Pzt';
        case 2: return 'Sal';
        case 3: return 'Çar';
        case 4: return 'Per';
        case 5: return 'Cum';
        case 6: return 'Cts';
        case 7: return 'Paz';
        default: return '';
      }
    } else {
      switch (day) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
        default: return '';
      }
    }
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

void _showAddMedicationSheet(BuildContext context, AuraController controller, {List<Medication>? existingGroup}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddMedicationSheet(controller: controller, existingGroup: existingGroup),
  );
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet({required this.controller, this.existingGroup});
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
          _selectedPeriods[med.period!] = TimeOfDay(hour: med.hour, minute: med.minute);
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
          case 'Sabah': defaultTime = const TimeOfDay(hour: 9, minute: 0); break;
          case 'Öğle': defaultTime = const TimeOfDay(hour: 13, minute: 0); break;
          case 'Akşam': defaultTime = const TimeOfDay(hour: 20, minute: 0); break;
          case 'Gece': defaultTime = const TimeOfDay(hour: 23, minute: 0); break;
          default: defaultTime = const TimeOfDay(hour: 9, minute: 0);
        }
        _selectedPeriods[period] = defaultTime;
      }
    });
  }

  String _periodName(String period, String lang) {
    if (lang == 'tr') return period;
    switch (period) {
      case 'Sabah': return 'Morning';
      case 'Öğle': return 'Noon';
      case 'Akşam': return 'Evening';
      case 'Gece': return 'Night';
      default: return period;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    super.dispose();
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
      padding: EdgeInsets.fromLTRB(24, 16, 24, media.viewInsets.bottom + 24),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: tr('med_name'),
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: isTr ? 'Stok (Kutudaki Toplam İlaç)' : 'Stock (Total in Box)',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                  label: Text(_periodName(period, widget.controller.languageCode)),
                  selected: isSelected,
                  onSelected: (_) => _togglePeriod(period),
                  selectedColor: colors.primaryContainer,
                  checkmarkColor: colors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? colors.primary : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final next = await showTimePicker(
                              context: context,
                              initialTime: entry.value,
                              initialEntryMode: TimePickerEntryMode.input,
                            );
                            if (next != null) {
                              setState(() => _selectedPeriods[entry.key] = next);
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text('${isTr ? "${_periodName(entry.key, widget.controller.languageCode)} Saati:" : "${_periodName(entry.key, widget.controller.languageCode)} Time:"} ${entry.value.format(context)}'),
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
                      if (val) {
                        _selectedDays.addAll([1, 2, 3, 4, 5, 6, 7]);
                      }
                    });
                  },
                  selectedColor: colors.primaryContainer,
                  checkmarkColor: colors.primary,
                  labelStyle: TextStyle(
                    color: _selectedDays.length == 7 ? colors.primary : colors.onSurface,
                    fontWeight: _selectedDays.length == 7 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                ...List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  final label = _dayNameShort(day, widget.controller.languageCode);
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                    selectedColor: colors.primaryContainer,
                    checkmarkColor: colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.primary : colors.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                _mealChip('Aç', tr('med_meal_before'), Icons.fastfood_outlined),
                _mealChip('Tok', tr('med_meal_after'), Icons.restaurant),
                _mealChip('Yemekle Beraber', isTr ? 'Yemekle Beraber' : 'With Meal', Icons.set_meal),
                _mealChip('Farketmez', tr('med_meal_any'), Icons.all_inclusive),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (_name.text.trim().isEmpty) return;

                if (_selectedDays.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isTr ? 'Lütfen en az bir gün seçin.' : 'Please select at least one day.')),
                    );
                  }
                  return;
                }

                if (_selectedPeriods.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isTr ? 'Lütfen en az bir periyot (Sabah, Akşam vb.) seçin.' : 'Please select at least one period.')),
                    );
                  }
                  return;
                }

                int? stockVal;
                if (_stock.text.trim().isNotEmpty) {
                  stockVal = int.tryParse(_stock.text.trim());
                }

                final groupId = widget.existingGroup != null && widget.existingGroup!.isNotEmpty
                    ? widget.existingGroup!.first.groupId ?? DateTime.now().microsecondsSinceEpoch.toString()
                    : DateTime.now().microsecondsSinceEpoch.toString();

                // If editing, remove the old ones first
                if (widget.existingGroup != null) {
                  for (final med in widget.existingGroup!) {
                    await widget.controller.removeMedication(med);
                  }
                }

                for (final entry in _selectedPeriods.entries) {
                  await widget.controller.upsertMedication(
                    Medication(
                      id: DateTime.now().microsecondsSinceEpoch.toString() + entry.key,
                      name: _name.text.trim(),
                      dosage: '', // Dosage field is removed from UI
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
                    SnackBar(content: Text(widget.existingGroup != null ? (isTr ? 'İlaç güncellendi' : 'Medication updated') : tr('med_add_success'))),
                  );
                }
              },
              child: Text(widget.existingGroup != null ? (isTr ? 'Kaydet' : 'Save') : tr('med_btn_add'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      avatar: Icon(icon, size: 16, color: isSelected ? colors.primary : colors.onSurfaceVariant),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _mealTiming = value);
      },
      selectedColor: colors.primaryContainer.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _dayNameShort(int day, String lang) {
    if (lang == 'tr') {
      switch (day) {
        case 1: return 'Pzt';
        case 2: return 'Sal';
        case 3: return 'Çar';
        case 4: return 'Per';
        case 5: return 'Cum';
        case 6: return 'Cts';
        case 7: return 'Paz';
        default: return '';
      }
    } else {
      switch (day) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
        default: return '';
      }
    }
  }
}
