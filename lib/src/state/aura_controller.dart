import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/breath_log.dart';
import '../models/chat_session.dart';
import '../models/health_profile.dart';
import '../models/medication.dart';
import '../models/mood_log.dart';
import '../models/sleep_log.dart';
import '../models/water_log.dart';
import '../services/ai_coach_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/biometric_service.dart';
import '../services/translation_service.dart';
import '../services/weather_service.dart';
import '../services/voice_service.dart';

part 'extensions/auth_extension.dart';
part 'extensions/health_extension.dart';
part 'extensions/medication_extension.dart';
part 'extensions/chat_extension.dart';
part 'extensions/settings_extension.dart';

abstract class AuraControllerBase extends ChangeNotifier {
  AuraControllerBase({
    required this.storage,
    required this.notifications,
    AiCoachService? ai,
  }) : ai = ai ?? AiCoachService();

  final StorageService storage;
  final NotificationService notifications;
  final AiCoachService ai;
  final DatabaseService db = DatabaseService();
  final BiometricService biometric = BiometricService();
  final VoiceService voice = VoiceService();

  HealthProfile profile = HealthProfile.initial();
  bool isVoiceOutputEnabled = false;
  List<Medication> medications = const [];
  String? apiKey;
  ThemeMode themeMode = ThemeMode.system;
  String languageCode = 'tr';

  bool biometricEnabled = false;
  String? biometricUserTc;

  WeatherData? currentWeather;

  bool waterRemindersEnabled = true;
  bool medsAlarmsEnabled = true;
  bool weeklyReportEnabled = true;
  bool crashReportsEnabled = true;

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
  List<ChatSession> chatSessions = [];
  String? _activeSessionId;

  String? get activeSessionId => _activeSessionId;

  // Cross-mixin dependencies
  Future<void> loadChatSessions();
  void newChat();
  void clearDismissedAlarms();
  void _checkMedications();
  Future<void> fetchWeather();
}

class AuraController extends AuraControllerBase
    with AuraAuthMixin, AuraHealthMixin, AuraMedicationMixin, AuraChatMixin, AuraSettingsMixin {
  AuraController({
    required super.storage,
    required super.notifications,
    super.ai,
  });

  Future<void> load() async {
    apiKey = await storage.loadApiKey();
    themeMode = await storage.loadThemeMode();
    languageCode = await storage.loadLanguageCode() ?? 'tr';
    biometricEnabled = await storage.loadBiometricEnabled();
    biometricUserTc = await storage.loadBiometricUserTc();
    waterRemindersEnabled = await storage.loadWaterRemindersEnabled();
    medsAlarmsEnabled = await storage.loadMedsAlarmsEnabled();
    weeklyReportEnabled = await storage.loadWeeklyReportEnabled();
    crashReportsEnabled = await storage.loadCrashReportsEnabled();
    // Do not load profile/medications until user logs in.

    // OTOMATİK KURTARMA VE GİRİŞ (AUTO-RESTORE & LOGIN)
    try {
      final hasUsers = await db.hasAnyUsers(); // Bu fonksiyonu ekleyeceğiz
      if (!hasUsers) {
        // Uygulama yeni silinip yüklendiyse otomatik olarak Eren'i ve verilerini oluştur
        await registerUser('11111111111', 'Eren', '123456');
        await login('11111111111', '123456');
      } else if (currentUserTc == null) {
        // Eğer zaten kayıtlıysa ama çıkış yapmışsa otomatik gir
        await login('11111111111', '123456');
      }
    } catch (e) {
      debugPrint("Auto-restore failed: $e");
    }
    
    _medicationTimer?.cancel();
    _medicationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkMedications());
    
    fetchWeather();
    
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    currentWeather = await WeatherService.fetchCurrentWeather();
    notifyListeners();
  }
}
