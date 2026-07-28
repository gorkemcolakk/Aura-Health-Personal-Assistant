part of '../aura_controller.dart';

mixin AuraMedicationMixin on AuraControllerBase {
  void _checkMedications() {
    if (activeAlarm != null) return;
    
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;

    for (final med in medications) {
      if (!med.enabled || med.isTakenToday) continue;
      
      if (med.hour == now.hour && med.minute == now.minute) {
        final alarmId = '${med.id}_$todayStr';
        if (!_dismissedAlarms.contains(alarmId)) {
          activeAlarm = med;
          notifyListeners();
          break; // Show one alarm at a time
        }
      }
    }
  }

  void clearDismissedAlarms() {
    _dismissedAlarms.clear();
  }

  void dismissAlarm() {
    if (activeAlarm != null) {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      _dismissedAlarms.add('${activeAlarm!.id}_$todayStr');
      activeAlarm = null;
      notifyListeners();
    }
  }

  Future<void> markMedicationAsTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index >= 0) {
      final med = medications[index];
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final updatedMed = med.copyWith(lastTakenDate: todayStr);
      final newList = List<Medication>.from(medications)..[index] = updatedMed;
      medications = newList;
      if (currentUserTc != null) {
        await db.saveMedications(currentUserTc!, newList);
      }
      
      if (activeAlarm?.id == id) {
        activeAlarm = null;
      }
      notifyListeners();
    }
  }

  Future<void> upsertMedication(Medication medication) async {
    final index = medications.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      medications = [...medications, medication];
    } else {
      final copy = [...medications];
      copy[index] = medication;
      medications = copy;
    }
    if (currentUserTc != null) {
      await db.saveMedications(currentUserTc!, medications);
    }
    try {
      await notifications.scheduleMedication(medication);
    } catch (_) {
      // Scheduling reminders is best-effort only.
    }
    notifyListeners();
  }

  Future<void> removeMedication(Medication medication) async {
    medications = medications
        .where((item) => item.id != medication.id)
        .toList();
    if (currentUserTc != null) {
      await db.saveMedications(currentUserTc!, medications);
    }
    await notifications.cancelMedication(medication);
    notifyListeners();
  }

  Future<void> toggleMedicationTaken(Medication medication, bool taken) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = Medication(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      hour: medication.hour,
      minute: medication.minute,
      notes: medication.notes,
      enabled: medication.enabled,
      mealTiming: medication.mealTiming,
      daysOfWeek: medication.daysOfWeek,
      lastTakenDate: taken ? today : null,
    );
    await upsertMedication(updated);
  }
}
