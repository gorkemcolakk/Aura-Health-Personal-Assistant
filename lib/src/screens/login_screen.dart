import 'package:flutter/material.dart';
import '../state/aura_scope.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tcController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
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
      setState(() => _error = 'TC Kimlik numarası 11 haneli rakam olmalıdır.');
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
    final success = await controller.login(tc, password);

    if (!mounted) return;

    if (success) {
      // AuraApp will rebuild and automatically show AuraShell
    } else {
      setState(() {
        _isLoading = false;
        _error = 'TC Kimlik numarası veya şifre hatalı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                  'Kişisel Sağlık Asistanınız',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 48),
                if (_error != null) ...[
                  Text(
                    _error!,
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
                  decoration: const InputDecoration(
                    labelText: 'TC Kimlik No',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
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
                              : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
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
                  child: const Text('Hesabın yok mu? Kayıt Ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
