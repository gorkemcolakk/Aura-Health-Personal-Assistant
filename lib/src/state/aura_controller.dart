import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
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
  String themeKey = 'system';

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

  // Sohbet oturumları
  List<ChatSession> chatSessions = [];
  String? _activeSessionId;

  String? get activeSessionId => _activeSessionId;

  Future<void> load() async {
    apiKey = await storage.loadApiKey();
    themeKey = await storage.loadThemeKey();
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
      await loadChatSessions();
      // Login'de her zaman yeni sohbetle başla
      _activeSessionId = null;
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

  Future<void> setThemeKey(String key) async {
    themeKey = key;
    notifyListeners();
    await storage.saveThemeKey(key);
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

    // Auto-save: kayıtlı sohbet varsa sessizce güncelle
    if (_activeSessionId != null) {
      await _silentSave();
    }
  }
  Future<void> clearMessages() async {
    if (messages.length > 1) {
      messages = [messages.first];
      notifyListeners();
    }
  }

  // --- Chat Sessions ---
  Future<void> loadChatSessions() async {
    if (currentUserTc == null) return;
    chatSessions = await db.loadChatSessions(currentUserTc!);
    notifyListeners();
  }

  Future<void> saveCurrentChat({String? title}) async {
    if (currentUserTc == null || messages.length <= 1) return;

    final sessionId = _activeSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final sessionTitle = title ?? _chatTitleFromMessages();

    final session = ChatSession(
      id: sessionId,
      title: sessionTitle,
      messages: List.from(messages),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.saveChatSession(currentUserTc!, session);
    _activeSessionId = sessionId;
    await loadChatSessions();
  }

  Future<void> switchToSession(ChatSession session) async {
    // Önce mevcut sohbeti kaydet (eğer aktif session varsa)
    if (_activeSessionId != null && _activeSessionId != session.id && messages.length > 1) {
      await _silentSave(forceSessionId: _activeSessionId);
    }
    _activeSessionId = session.id;
    messages = List.from(session.messages);
    notifyListeners();
  }

  Future<void> _silentSave({String? forceSessionId}) async {
    if (currentUserTc == null) return;
    final sid = forceSessionId ?? _activeSessionId;
    if (sid == null || messages.length <= 1) return;

    final existing = chatSessions.where((s) => s.id == sid).firstOrNull;
    final title = existing?.title ?? _chatTitleFromMessages();
    final session = ChatSession(
      id: sid,
      title: title,
      messages: List.from(messages),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.saveChatSession(currentUserTc!, session);
    
    final idx = chatSessions.indexWhere((s) => s.id == sid);
    if (idx >= 0) {
      chatSessions[idx] = session;
    } else {
      chatSessions = [session, ...chatSessions];
    }
    chatSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> renameSession(ChatSession session, String newTitle) async {
    if (currentUserTc == null) return;
    final updated = ChatSession(
      id: session.id,
      title: newTitle,
      messages: session.messages,
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.saveChatSession(currentUserTc!, updated);
    await loadChatSessions();
  }

  Future<void> deleteSession(ChatSession session) async {
    if (currentUserTc == null) return;
    await db.deleteChatSession(currentUserTc!, session.id);
    if (_activeSessionId == session.id) {
      _activeSessionId = null;
    }
    await loadChatSessions();
  }

  void newChat() {
    _activeSessionId = null;
    messages = [
      ChatMessage(
        role: ChatRole.assistant,
        text: 'Merhaba, ben Aura AI. Profilini, su hedefini ve ilaç düzenini dikkate alarak yardımcı olabilirim.',
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  String _chatTitleFromMessages() {
    for (final m in messages) {
      if (m.role == ChatRole.user && m.text.isNotEmpty) {
        return m.text.length > 40 ? '${m.text.substring(0, 40)}...' : m.text;
      }
    }
    return 'Yeni Sohbet';
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
