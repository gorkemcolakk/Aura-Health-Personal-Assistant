import 'package:flutter/material.dart';
import '../state/aura_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _SectionTitle(title: 'Görünüm ve Dil'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema Modu'),
                  subtitle: const Text('Uygulamanın renk temasını belirleyin'),
                ),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Açık'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Koyu'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Sistem'),
                    ),
                  ],
                  selected: {controller.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    controller.setThemeMode(newSelection.first);
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Dil / Language'),
                  subtitle: const Text('Arayüz ve yapay zeka dilini seçin'),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'tr',
                      label: Text('Türkçe'),
                    ),
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text('English'),
                    ),
                  ],
                  selected: {controller.languageCode},
                  onSelectionChanged: (Set<String> newSelection) {
                    controller.setLanguageCode(newSelection.first);
                    // App needs to handle language changes later, for now we set state.
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Veri ve Gizlilik'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biyometrik Giriş'),
                  subtitle: const Text('Face ID veya parmak izi ile giriş yapın'),
                  trailing: Switch(
                    value: controller.isBiometricEnabledForCurrentUser,
                    onChanged: (val) async {
                      final success = await controller.setBiometricEnabled(val);
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biyometrik doğrulama kurulamadı.')),
                        );
                      }
                    },
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined, color: colors.error),
                  title: Text('Verileri Sıfırla', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Su, uyku ve ilaç kayıtlarınızı siler'),
                  onTap: () => _showResetDialog(context, controller),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'Aura Health',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.2',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text(
          'Su, uyku ve ilaç kayıtlarınız kalıcı olarak silinecektir. '
          'Bu işlem geri alınamaz. Onaylıyor musunuz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              controller.resetAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verileriniz başarıyla sıfırlandı.')),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: child,
    );
  }
}
