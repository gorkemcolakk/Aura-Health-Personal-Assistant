part of '../aura_controller.dart';

mixin AuraMedicationMixin on AuraControllerBase {
  @override
  void _checkMedications() {
    if (activeAlarm != null) return;

    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;
    final todayWeekday = now.weekday;

    for (final med in medications) {
      if (!med.enabled || med.isTakenToday) continue;
      if (!med.daysOfWeek.contains(todayWeekday)) continue;

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

  @override
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
            clearStock: medication.stock == null,
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

  /// Dashboard'daki "İçtim / Geri Al" butonu için kullanılır.
  /// takenHistory ile koordineli çalışır.
  Future<void> toggleMedicationTaken(Medication medication, bool taken) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    // Always fetch the latest version to prevent rapid tap race conditions
    final latestMed = medications.firstWhere(
      (m) => m.id == medication.id,
      orElse: () => medication,
    );
    int? newStock = latestMed.stock;
    final List<String> newHistory = [...latestMed.takenHistory];

    if (taken && !latestMed.isTakenToday) {
      if (newStock != null && newStock > 0) newStock -= 1;
      if (!newHistory.contains(today)) newHistory.add(today);
    } else if (!taken && latestMed.isTakenToday) {
      // Revert stock deduction
      if (newStock != null) newStock += 1;
      newHistory.remove(today);
    }

    final updated = latestMed.copyWith(
      lastTakenDate: taken ? today : null,
      takenHistory: newHistory,
      stock: newStock,
      clearStock: taken ? false : (newStock == null),
      clearDate: !taken,
    );

    await upsertMedication(updated);
  }

  /// Tüketim gridinden belirli bir tarihte doz alımını toggle eder.
  /// Dashboard ile tam koordineli: stok hep tutarlı.
  Future<void> toggleDoseTaken(Medication medication, String date) async {
    final latestMed = medications.firstWhere(
      (m) => m.id == medication.id,
      orElse: () => medication,
    );
    final alreadyTaken = latestMed.isDoseTaken(date);

    final List<String> newHistory = [...latestMed.takenHistory];
    int? newStock = latestMed.stock;

    if (alreadyTaken) {
      newHistory.remove(date);
      if (newStock != null) newStock += 1;
    } else {
      if (!newHistory.contains(date)) newHistory.add(date);
      if (newStock != null && newStock > 0) newStock -= 1;
    }

    // Eğer bugün ise lastTakenDate de güncelle (Dashboard uyumu için)
    final today = DateTime.now().toIso8601String().split('T').first;
    final isToday = date == today;

    final updated = latestMed.copyWith(
      takenHistory: newHistory,
      stock: newStock,
      clearStock: newStock == null,
      lastTakenDate: isToday ? (alreadyTaken ? null : today) : latestMed.lastTakenDate,
      clearDate: isToday && alreadyTaken,
    );

    await upsertMedication(updated);
  }
}
