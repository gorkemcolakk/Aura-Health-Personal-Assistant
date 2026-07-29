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
      await toggleMedicationTaken(medications[index], true);
      if (activeAlarm?.id == id) {
        activeAlarm = null;
        notifyListeners();
      }
    }
  }

  Future<void> upsertMedication(Medication medication) async {
    final index = medications.indexWhere((item) => item.id == medication.id);
    List<Medication> copy = [...medications];
    
    if (index == -1) {
      copy.add(medication);
    } else {
      copy[index] = medication;
    }

    // Sync stock for medications in the same group
    if (medication.groupId != null && medication.groupId!.isNotEmpty) {
      for (int i = 0; i < copy.length; i++) {
        if (copy[i].groupId == medication.groupId && copy[i].id != medication.id) {
          copy[i] = copy[i].copyWith(
            stock: medication.stock, 
            clearStock: medication.stock == null
          );
        }
      }
    }

    medications = copy;
    
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
    
    // Always fetch the latest version of this medication to prevent rapid tap race conditions
    final latestMed = medications.firstWhere((m) => m.id == medication.id, orElse: () => medication);
    int? newStock = latestMed.stock;
    
    if (taken && !latestMed.isTakenToday) {
      if (newStock != null && newStock > 0) newStock -= 1;
    } else if (!taken && latestMed.isTakenToday) {
      // Revert the stock deduction
      if (newStock != null) newStock += 1;
    }

    final updated = latestMed.copyWith(
      lastTakenDate: taken ? today : null,
      stock: newStock,
      clearStock: taken ? false : (newStock == null),
      clearDate: !taken,
    );

    await upsertMedication(updated);
  }
}
