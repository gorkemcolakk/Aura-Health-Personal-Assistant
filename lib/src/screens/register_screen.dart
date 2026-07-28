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
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  String _gender = 'Erkek';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tcController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final tc = _tcController.text.trim();
    final name = _nameController.text.trim();
    final birthDate = HealthProfile.formatToIso(_birthDateController.text.trim());
    final password = _passwordController.text.trim();

    if (tc.length != 11 || int.tryParse(tc) == null) {
      setState(() => _error = 'TC Kimlik numarası 11 haneli olmalıdır.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'İsim boş bırakılamaz.');
      return;
    }
    if (birthDate.isEmpty) {
      setState(() => _error = 'Doğum tarihi seçmelisiniz.');
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
    final success = await controller.registerUser(tc, name, password, gender: _gender, birthDate: birthDate);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Cinsiyet',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                    DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                    DropdownMenuItem(value: 'Belirtilmedi', child: Text('Belirtilmedi')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarihi',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthDateController.text.isNotEmpty 
                          ? (DateTime.tryParse(HealthProfile.formatToIso(_birthDateController.text)) ?? DateTime(now.year - 20))
                          : DateTime(now.year - 20),
                      firstDate: DateTime(1900),
                      lastDate: now,
                    );
                    if (date != null) {
                      setState(() {
                        _birthDateController.text = HealthProfile.formatToDisplay(date.toIso8601String().split('T').first);
                      });
                    }
                  },
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
