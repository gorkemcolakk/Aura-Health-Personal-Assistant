import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/secrets.dart';
import '../models/health_profile.dart';
import '../models/medication.dart';

class StorageService {
  static const _profileKey = 'aura.profile';
  static const _medicationsKey = 'aura.medications';

  Future<HealthProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_profileKey);
    if (source == null) {
      return HealthProfile.initial();
    }
    return HealthProfile.fromJson(source);
  }

  Future<void> saveProfile(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());
  }

  Future<List<Medication>> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_medicationsKey);
    if (source == null) {
      return [
        const Medication(
          id: 'morning-sample',
          name: 'D vitamini',
          dosage: '1 kapsül',
          hour: 9,
          minute: 0,
          notes: 'Kahvaltıdan sonra',
          enabled: true,
        ),
      ];
    }
    return Medication.decodeList(source);
  }

  Future<void> saveMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medicationsKey, Medication.encodeList(medications));
  }

  Future<String> loadApiKey() async {
    // Always use the key from secrets.dart (gitignored)
    return deepseekApiKey;
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aura.api_key', key.trim());
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('aura.theme_mode');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aura.theme_mode', mode.name);
  }
}
