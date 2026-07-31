part of '../aura_controller.dart';

mixin AuraHealthMixin on AuraControllerBase {
  Future<void> saveProfile(HealthProfile nextProfile) async {
    profile = nextProfile;
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> addMoodLog(MoodLog log) async {
    final isToday = (DateTime d) => _isSameDay(d, log.timestamp);
    
    // Eğer aynı güne ait bir kayıt varsa, onu güncelleriz, yoksa yeni ekleriz
    final filtered = profile.moodLogs
        .where((l) => !isToday(l.timestamp))
        .toList();
    
    filtered.add(log);
    
    // Tarihe göre sırala
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    profile = profile.copyWith(moodLogs: filtered);
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> addBreathLog(BreathLog log) async {
    final updatedList = List<BreathLog>.from(profile.breathLogs)..add(log);
    // En yeni en üstte olsun
    updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    profile = profile.copyWith(breathLogs: updatedList);
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> addWater(int ml, {DateTime? date}) async {
    final logDate = date ?? DateTime.now();
    final isToday = _isSameDay(logDate, DateTime.now());

    if (!isToday) {
      final filtered = profile.waterLogs
          .where((l) => !_isSameDay(l.timestamp, logDate))
          .toList();
      filtered.add(WaterLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: logDate,
        amountMl: ml,
      ));
      profile = profile.copyWith(waterLogs: filtered);
    } else {
      final newLog = WaterLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: logDate,
        amountMl: ml,
      );
      profile = profile.copyWith(
        waterConsumedMl: profile.waterConsumedMl + ml,
        waterLogs: [...profile.waterLogs, newLog],
      );
    }
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> deleteWaterLog(WaterLog log) async {
    final nextLogs = profile.waterLogs.where((item) => item.id != log.id).toList();
    profile = profile.copyWith(
      waterConsumedMl: (profile.waterConsumedMl - log.amountMl).clamp(0, 99999),
      waterLogs: nextLogs,
    );
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> resetWater() async {
    profile = profile.copyWith(
      waterConsumedMl: 0,
      waterLogs: const [],
    );
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> resetAllData() async {
    profile = profile.copyWith(
      waterConsumedMl: 0,
      waterLogs: const [],
      sleepLogs: const [],
    );
    medications = [];
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
      await db.saveMedications(currentUserTc!, medications);
    }
    notifyListeners();
  }

  Future<void> addSleep(double hours, String feeling, {DateTime? date}) async {
    final logDate = date ?? DateTime.now();
    final log = SleepLog(date: logDate, hours: hours, feeling: feeling);

    final updated = profile.sleepLogs
        .where((l) => !_isSameDay(l.date, logDate))
        .toList();
    updated.add(log);
    updated.sort((a, b) => b.date.compareTo(a.date));

    profile = profile.copyWith(sleepLogs: updated);
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
