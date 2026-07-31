part of '../aura_controller.dart';

mixin AuraAuthMixin on AuraControllerBase {
  bool get isBiometricEnabledForCurrentUser =>
      biometricEnabled && biometricUserTc == currentUserTc;

  Future<bool> registerUser(String tc, String name, String password,
      {String gender = 'Belirtilmedi', String birthDate = ''}) async {
    final success = await db.registerUser(tc, name, password);
    if (success) {
      await db.saveProfile(
          tc, HealthProfile.initial(name: name, gender: gender, birthDate: birthDate));
          
      // EREN'İN VERİLERİNİ KURTARMA PROTOKOLÜ (MOCK DATA)
      if (name.trim().toLowerCase() == 'eren') {
        final mockMeds = [
          Medication(id: 'aug_sabah', name: 'Augmentin', dosage: '1000mg', hour: 10, minute: 0, daysOfWeek: [1,2,3,4,5,6,7], enabled: true, timeOfDay: 'Sabah', timing: 'Tok'),
          Medication(id: 'aferin_ogle', name: 'Aferin Sinus', dosage: '1 Tablet', hour: 15, minute: 50, daysOfWeek: [1,2,3,4,5,6,7], enabled: true, timeOfDay: 'Öğle', timing: 'Tok'),
          Medication(id: 'aug_aksam', name: 'Augmentin', dosage: '1000mg', hour: 22, minute: 0, daysOfWeek: [1,2,3,4,5,6,7], enabled: true, timeOfDay: 'Akşam', timing: 'Tok'),
        ];
        await db.saveMedications(tc, mockMeds);
        
        final mockProfile = HealthProfile.initial(name: 'Eren', gender: 'Erkek', birthDate: '01.01.1995')
            .copyWith(weight: 75, height: 180, dailyWaterGoal: 2500, dailySleepGoal: 8);
        await db.saveProfile(tc, mockProfile);
      }
    }
    return success;
  }

  Future<int> login(String tc, String password) async {
    final userExists = await db.getUser(tc);
    if (userExists == null) {
      return -1; // Account not found
    }
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
      newChat(); // newChat method resets _activeSessionId and messages
      notifyListeners();
      return 1; // Success
    }
    return -2; // Incorrect password
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (currentUserTc == null) return false;
    return await db.updatePassword(currentUserTc!, oldPassword, newPassword);
  }

  Future<int> resetPasswordWithBirthDate(
      String tc, String birthDate, String newPassword) async {
    return await db.resetPasswordWithBirthDate(tc, birthDate, newPassword);
  }

  Future<void> deleteAccount() async {
    if (currentUserTc == null) return;
    final tc = currentUserTc!;
    try {
      await notifications.cancelAll();
    } catch (_) {}
    await db.deleteUser(tc);
    await logout();
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
    clearDismissedAlarms(); // we'll add this small helper in medication
    newChat(); // resets messages
    notifyListeners();
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (currentUserTc == null) return false;

    if (enabled) {
      final success = await biometric.authenticate();
      if (!success) return false;

      biometricEnabled = true;
      biometricUserTc = currentUserTc;
      await storage.saveBiometricEnabled(true);
      await storage.saveBiometricUserTc(currentUserTc);
    } else {
      biometricEnabled = false;
      biometricUserTc = null;
      await storage.saveBiometricEnabled(false);
      await storage.saveBiometricUserTc(null);
    }
    notifyListeners();
    return true;
  }

  Future<bool> loginWithBiometrics() async {
    final isSupported = await biometric.isBiometricsSupported();
    final hasEnrolled = await biometric.hasEnrolledBiometrics();
    if (!isSupported || !hasEnrolled || !biometricEnabled || biometricUserTc == null) {
      return false;
    }

    final success = await biometric.authenticate();
    if (success) {
      final user = await db.getUser(biometricUserTc!);
      if (user != null) {
        currentUserTc = biometricUserTc;
        currentUserName = user['name'] as String;

        profile = await db.loadProfile(currentUserTc!);
        medications = await db.loadMedications(currentUserTc!);

        for (final med in medications) {
          try {
            await notifications.scheduleMedication(med);
          } catch (_) {}
        }
        await loadChatSessions();
        newChat();
        notifyListeners();
        return true;
      }
    }
    return false;
  }
}
