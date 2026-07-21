import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/health_profile.dart';
import '../models/medication.dart';
import '../models/sleep_log.dart';
import '../models/water_log.dart';
import '../services/ai_coach_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

class AuraController extends ChangeNotifier {
  AuraController({
    required this.storage,
    required this.notifications,
    AiCoachService? ai,
  }) : ai = ai ?? AiCoachService();

  final StorageService storage;
  final NotificationService notifications;
  final AiCoachService ai;
  final DatabaseService db = DatabaseService();

  HealthProfile profile = HealthProfile.initial();
  List<Medication> medications = const [];
  String? apiKey;
  ThemeMode themeMode = ThemeMode.system;

  String? currentUserTc;
  String? currentUserName;

  Medication? activeAlarm;
  final Set<String> _dismissedAlarms = {};
  Timer? _medicationTimer;

  List<ChatMessage> messages = [
    ChatMessage(
      role: ChatRole.assistant,
      text:
          'Merhaba, ben Aura AI. Profilini, su hedefini ve ilaç düzenini dikkate alarak yardımcı olabilirim.',
      createdAt: DateTime.now(),
    ),
  ];
  bool isThinking = false;

  Future<void> load() async {
    apiKey = await storage.loadApiKey();
    themeMode = await storage.loadThemeMode();
    // Do not load profile/medications until user logs in.
    
    _medicationTimer?.cancel();
    _medicationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkMedications());
    
    notifyListeners();
  }

  // --- Auth ---
  Future<bool> registerUser(String tc, String name, String password) async {
    return await db.registerUser(tc, name, password);
  }

  Future<bool> login(String tc, String password) async {
    final user = await db.loginUser(tc, password);
    if (user != null) {
      currentUserTc = user['tc'] as String;
      currentUserName = user['name'] as String;
      
      profile = await db.loadProfile(currentUserTc!);
      medications = await db.loadMedications(currentUserTc!);
      
      for (final med in medications) {
        try {
          await notifications.scheduleMedication(med);
        } catch (_) {}
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    currentUserTc = null;
    currentUserName = null;
    profile = HealthProfile.initial();
    
    for (final med in medications) {
      await notifications.cancelMedication(med);
    }
    medications = [];
    activeAlarm = null;
    _dismissedAlarms.clear();
    messages = [
      ChatMessage(
        role: ChatRole.assistant,
        text:
            'Merhaba, ben Aura AI. Profilini, su hedefini ve ilaç düzenini dikkate alarak yardımcı olabilirim.',
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

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

  Future<void> setApiKey(String key) async {
    await storage.saveApiKey(key);
    apiKey = key;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await storage.saveThemeMode(mode);
  }

  Future<void> saveProfile(HealthProfile nextProfile) async {
    profile = nextProfile;
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
  }

  Future<void> addWater(int ml) async {
    final newLog = WaterLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amountMl: ml,
    );
    profile = profile.copyWith(
      waterConsumedMl: profile.waterConsumedMl + ml,
      waterLogs: [...profile.waterLogs, newLog],
    );
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

  Future<void> addSleep(double hours, String feeling) async {
    final log = SleepLog(
      date: DateTime.now(),
      hours: hours,
      feeling: feeling,
    );
    profile = profile.copyWith(
      sleepLogs: [...profile.sleepLogs, log],
    );
    if (currentUserTc != null) {
      await db.saveProfile(currentUserTc!, profile);
    }
    notifyListeners();
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

  Future<void> askAi(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || isThinking) {
      return;
    }

    messages = [
      ...messages,
      ChatMessage(
        role: ChatRole.user,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    ];
    isThinking = true;
    notifyListeners();

    final answer = await ai.ask(
      profile: profile,
      medications: medications,
      question: trimmed,
      apiKey: apiKey,
    );
    messages = [
      ...messages,
      ChatMessage(
        role: ChatRole.assistant,
        text: answer,
        createdAt: DateTime.now(),
      ),
    ];
    isThinking = false;
    notifyListeners();
  }
  Future<void> clearMessages() async {
    if (messages.length > 1) {
      messages = [messages.first];
      notifyListeners();
    }
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
