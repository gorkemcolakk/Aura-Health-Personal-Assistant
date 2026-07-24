import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _mealTiming = 'Farketmez';

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Text(controller.tr('med_title'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(controller.tr('med_subtitle')),
          const SizedBox(height: 18),
          AuraCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: controller.tr('med_name'),
                    prefixIcon: const Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dosage,
                  decoration: InputDecoration(
                    labelText: controller.tr('med_dosage'),
                    prefixIcon: const Icon(Icons.local_pharmacy_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  decoration: InputDecoration(
                    labelText: controller.tr('med_notes'),
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final next = await showTimePicker(
                      context: context,
                      initialTime: _time,
                      initialEntryMode: TimePickerEntryMode.input,
                    );
                    if (next != null) {
                      setState(() => _time = next);
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text('${controller.tr('med_hour')} ${_time.format(context)}'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'Aç', label: Text(controller.tr('med_meal_before'))),
                    ButtonSegment(value: 'Tok', label: Text(controller.tr('med_meal_after'))),
                    ButtonSegment(value: 'Farketmez', label: Text(controller.tr('med_meal_any'))),
                  ],
                  selected: {_mealTiming},
                  onSelectionChanged: (set) {
                    setState(() => _mealTiming = set.first);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    if (_name.text.trim().isEmpty) {
                      return;
                    }
                    await controller.upsertMedication(
                      Medication(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: _name.text.trim(),
                        dosage: _dosage.text.trim().isEmpty
                            ? controller.tr('med_no_dosage')
                            : _dosage.text.trim(),
                        hour: _time.hour,
                        minute: _time.minute,
                        notes: _notes.text.trim(),
                        enabled: true,
                        mealTiming: _mealTiming,
                      ),
                    );
                    _name.clear();
                    _dosage.clear();
                    _notes.clear();
                    setState(() {
                      _mealTiming = 'Farketmez';
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(controller.tr('med_add_success'))),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_alert),
                  label: Text(controller.tr('med_btn_add')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...controller.medications.map(
            (medication) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AuraCard(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medication.enabled
                            ? const Color(0xFFEAF6F4)
                            : const Color(0xFFF0F1F0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        medication.enabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: medication.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    Checkbox(
                      value: medication.isTakenToday,
                      onChanged: (val) {
                        if (val != null) {
                          controller.toggleMedicationTaken(medication, val);
                        }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: medication.isTakenToday ? TextDecoration.lineThrough : null,
                              color: medication.isTakenToday ? Colors.grey : null,
                            ),
                          ),
                          Text(
                            '${medication.dosage} • ${medication.timeLabel} • ${controller.tr(medication.mealTiming == 'Aç' ? 'med_meal_before' : medication.mealTiming == 'Tok' ? 'med_meal_after' : 'med_meal_any')}',
                            style: TextStyle(
                              color: medication.isTakenToday ? Colors.grey : null,
                            ),
                          ),
                          if (medication.notes.isNotEmpty)
                            Text(
                              medication.notes,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: medication.enabled,
                      onChanged: (value) {
                        controller.upsertMedication(
                          medication.copyWith(enabled: value),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: controller.tr('btn_delete'),
                      onPressed: () => controller.removeMedication(medication),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
