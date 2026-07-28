import 'package:flutter/material.dart';
import '../state/aura_scope.dart';
import '../models/health_profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _tcController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscuringPassword = true;
  String? _error;

  @override
  void dispose() {
    _tcController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final tc = _tcController.text.trim();
    final firstName = _nameController.text.trim();
    final lastName = _surnameController.text.trim();
    final password = _passwordController.text.trim();
    
    final name = '$firstName $lastName'.trim();

    if (tc.length != 11 || int.tryParse(tc) == null) {
      setState(() => _error = 'TC Kimlik numarası 11 haneli olmalıdır.');
      return;
    }
    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _error = 'İsim ve soyisim boş bırakılamaz.');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'Şifre en az 4 karakter olmalıdır.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = AuraScope.of(context, listen: false);
    final success = await controller.registerUser(tc, name, password);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
      );
      Navigator.pop(context); // Go back to login
    } else {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hesap Zaten Var'),
          content: const Text('Bu TC Kimlik numarası ile zaten kayıtlı bir hesap var. Lütfen giriş yapmayı deneyin veya şifrenizi unuttuysanız sıfırlayın.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım'),
            ),
          ],
        ),
      );
    }
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
                    Text(
                      isTr ? 'Kayıt Ol' : 'Sign Up',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 32),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: isTr ? 'Ad' : 'Name',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _surnameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: isTr ? 'Soyad' : 'Surname',
                            ),
                          ),
                        ),
                      ],
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isTr ? 'Kayıt Ol' : 'Sign Up', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button + Theme switch
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
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
      case 'İsim ve soyisim boş bırakılamaz.':
        return isTr ? 'İsim ve soyisim boş bırakılamaz.' : 'Name and surname cannot be empty.';
      case 'Şifre en az 4 karakter olmalıdır.':
        return isTr ? 'Şifre en az 4 karakter olmalıdır.' : 'Password must be at least 4 characters.';
      default:
        return error;
    }
  }
}
