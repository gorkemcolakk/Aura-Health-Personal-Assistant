import 'package:flutter/material.dart';
import '../state/aura_scope.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _tcController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tcController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final tc = _tcController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (tc.length != 11 || int.tryParse(tc) == null) {
      setState(() => _error = 'TC Kimlik numarası 11 haneli rakam olmalıdır.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'İsim boş bırakılamaz.');
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
        _error = 'Bu TC Kimlik numarası ile zaten kayıtlı bir hesap var.';
      });
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
