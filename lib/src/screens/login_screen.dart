import 'package:flutter/material.dart';
import '../state/aura_scope.dart';
import 'register_screen.dart';
import '../models/health_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tcController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscuringPassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = AuraScope.of(context, listen: false);
      if (controller.biometricEnabled) {
        _loginWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _tcController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = AuraScope.of(context, listen: false);
    final success = await controller.loginWithBiometrics();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      setState(() {
        _error = 'Biyometrik doğrulama başarısız oldu veya iptal edildi.';
      });
    }
  }

  void _login() async {
    final tc = _tcController.text.trim();
    final password = _passwordController.text.trim();

    if (tc.length != 11 || int.tryParse(tc) == null) {
      setState(() => _error = 'TC Kimlik numarası 11 haneli olmalıdır.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Şifre boş bırakılamaz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = AuraScope.of(context, listen: false);
    final result = await controller.login(tc, password);

    if (!mounted) return;

    if (result == 1) {
      // AuraApp will rebuild and automatically show AuraShell
    } else {
      setState(() {
        _isLoading = false;
        if (result == -1) {
          _error = 'Hesap bulunamadı.';
        } else {
          _error = 'Şifre hatalı.';
        }
      });
    }
  }

  void _showForgotPasswordSheet() {
    final tcCtrl = TextEditingController(text: _tcController.text);
    final birthDateCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Şifremi Unuttum', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Lütfen hesabınızı doğrulamak için TC kimlik numaranızı ve doğum tarihinizi girin.'),
                  const SizedBox(height: 16),
                  if (localError != null) ...[
                    Text(localError!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: tcCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: const InputDecoration(labelText: 'TC Kimlik No', prefixIcon: Icon(Icons.badge_outlined), counterText: ''),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: birthDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Doğum Tarihi', prefixIcon: Icon(Icons.cake_outlined)),
                    onTap: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: birthDateCtrl.text.isNotEmpty 
                            ? (DateTime.tryParse(HealthProfile.formatToIso(birthDateCtrl.text)) ?? DateTime(now.year - 20))
                            : DateTime(now.year - 20),
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (date != null) {
                        setModalState(() {
                          birthDateCtrl.text = HealthProfile.formatToDisplay(date.toIso8601String().split('T').first);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () async {
                        if (tcCtrl.text.isEmpty || birthDateCtrl.text.isEmpty || newPasswordCtrl.text.length < 4) {
                          setModalState(() => localError = 'Lütfen tüm alanları geçerli şekilde doldurun (Şifre en az 4 karakter).');
                          return;
                        }
                        final controller = AuraScope.of(context, listen: false);
                        final isoBirthDate = HealthProfile.formatToIso(birthDateCtrl.text.trim());
                        final result = await controller.resetPasswordWithBirthDate(tcCtrl.text, isoBirthDate, newPasswordCtrl.text);
                        if (result == 1) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Şifreniz başarıyla güncellendi. Yeni şifrenizle giriş yapabilirsiniz.')));
                          }
                        } else if (result == -1) {
                          setModalState(() => localError = 'Böyle bir TC Kimlik Numarası bulunamadı.');
                        } else {
                          setModalState(() => localError = 'Doğum Tarihi hatalı.');
                        }
                      },
                      child: const Text('Şifreyi Sıfırla'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final isTr = controller.languageCode == 'tr';
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 72.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aura Health',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTr ? 'Kişisel Sağlık Asistanınız' : 'Your Personal Health Assistant',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 48),
                    if (_error != null) ...[
                      Text(
                        _getTranslatedError(isTr, _error)!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                TextField(
                  controller: _tcController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: isTr ? 'TC Kimlik No' : 'ID Number',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscuringPassword,
                  decoration: InputDecoration(
                    labelText: isTr ? 'Şifre' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscuringPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscuringPassword = !_obscuringPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isTr ? 'Giriş Yap' : 'Log In', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    if (controller.biometricEnabled) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _loginWithBiometrics,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(isTr ? 'Hesabın yok mu? Kayıt Ol' : "Don't have an account? Sign Up"),
                ),
                TextButton(
                  onPressed: _showForgotPasswordSheet,
                  child: Text(isTr ? 'Şifremi Unuttum' : 'Forgot Password'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Theme Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: controller.themeMode == ThemeMode.dark ||
                        (controller.themeMode == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness == Brightness.dark),
                    onChanged: (isDark) {
                      controller.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
              // Language Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    controller.languageCode.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: controller.languageCode == 'en',
                    onChanged: (isEn) {
                      controller.setLanguageCode(isEn ? 'en' : 'tr');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
      ),
    );
  }

  String? _getTranslatedError(bool isTr, String? error) {
    if (error == null) return null;
    switch (error) {
      case 'TC Kimlik numarası 11 haneli olmalıdır.':
        return isTr ? 'TC Kimlik numarası 11 haneli olmalıdır.' : 'ID Number must be 11 digits.';
      case 'Şifre boş bırakılamaz.':
        return isTr ? 'Şifre boş bırakılamaz.' : 'Password cannot be empty.';
      case 'Hesap bulunamadı.':
        return isTr ? 'Hesap bulunamadı.' : 'Account not found.';
      case 'Şifre hatalı.':
        return isTr ? 'Şifre hatalı.' : 'Incorrect password.';
      case 'Biyometrik doğrulama başarısız oldu veya iptal edildi.':
        return isTr ? 'Biyometrik doğrulama başarısız oldu veya iptal edildi.' : 'Biometric authentication failed or cancelled.';
      default:
        return error;
    }
  }
}
