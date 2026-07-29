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
      
      int? newStock = med.stock;
      if (!med.isTakenToday && newStock != null && newStock > 0) {
        newStock -= 1;
      }
      
      final updatedMed = med.copyWith(
        lastTakenDate: todayStr,
        stock: newStock,
      );
      
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
    int? newStock = medication.stock;
    
    if (taken && !medication.isTakenToday) {
      if (newStock != null && newStock > 0) newStock -= 1;
    } else if (!taken && medication.isTakenToday) {
      // Revert the stock deduction
      if (newStock != null) newStock += 1;
    }

    final updated = medication.copyWith(
      lastTakenDate: taken ? today : null,
      stock: newStock,
      clearStock: taken ? false : (newStock == null), // Avoid accidentally setting stock to null in copyWith if it wasn't null
    );
    // Actually wait, if clearStock is false, copyWith(stock: null) will just keep original stock, which is what we want?
    // Let me check copyWith: `stock: clearStock ? null : (stock ?? this.stock)`. 
    // If I want to update stock to 0, I pass stock: 0. clearStock will be false. It sets stock: 0.
    // So the above `clearStock` logic is not strictly needed here unless I want to explicitly remove stock, which I don't.
    // Let's just pass `stock: newStock`.

    await upsertMedication(updated);
  }
}
