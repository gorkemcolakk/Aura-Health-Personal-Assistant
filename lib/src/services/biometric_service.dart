import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Cihazda biyometrik donanım olup olmadığını ve aktif olup olmadığını kontrol eder.
  Future<bool> isBiometricsSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Kayıtlı en az bir biyometrik veri (parmak izi veya yüz) olup olmadığını kontrol eder.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Biyometrik kimlik doğrulamayı başlatır.
  Future<bool> authenticate() async {
    try {
      final isSupported = await isBiometricsSupported();
      if (!isSupported) return false;

      final hasEnrolled = await hasEnrolledBiometrics();
      if (!hasEnrolled) return false;

      return await _auth.authenticate(
        localizedReason: 'Aura Health hesabınıza güvenli erişim için doğrulayın.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Biyometrik Giriş',
            biometricHint: 'Sensöre dokunun veya yüzünüzü gösterin',
            cancelButton: 'İptal',
          ),
          IOSAuthMessages(
            cancelButton: 'İptal',
          ),
        ],
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
