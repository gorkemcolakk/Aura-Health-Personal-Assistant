part of '../aura_controller.dart';

mixin AuraSettingsMixin on AuraControllerBase {
  String tr(String key) => TranslationService.get(key, languageCode);

  void setWaterRemindersEnabled(bool val) {
    waterRemindersEnabled = val;
    storage.saveWaterRemindersEnabled(val);
    notifyListeners();
  }

  void setMedsAlarmsEnabled(bool val) {
    medsAlarmsEnabled = val;
    storage.saveMedsAlarmsEnabled(val);
    notifyListeners();
  }

  void setWeeklyReportEnabled(bool val) {
    weeklyReportEnabled = val;
    storage.saveWeeklyReportEnabled(val);
    notifyListeners();
  }

  void setCrashReportsEnabled(bool val) {
    crashReportsEnabled = val;
    storage.saveCrashReportsEnabled(val);
    notifyListeners();
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

  Future<void> setLanguageCode(String code) async {
    languageCode = code;
    notifyListeners();
    await storage.saveLanguageCode(code);
  }
}
