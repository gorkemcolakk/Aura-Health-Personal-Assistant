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
        title: Text(controller.tr('settings_title')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _SectionTitle(title: controller.tr('settings_appearance')),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(controller.tr('settings_theme')),
                  subtitle: Text(controller.tr('settings_theme_sub')),
                ),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(controller.tr('theme_light')),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(controller.tr('theme_dark')),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.settings_suggest_outlined),
                      label: Text(controller.tr('theme_system')),
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
                  title: Text(controller.tr('settings_lang')),
                  subtitle: Text(controller.tr('settings_lang_sub')),
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
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: controller.tr('settings_data_privacy')),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fingerprint),
                  title: Text(controller.tr('settings_biometric')),
                  subtitle: Text(controller.tr('settings_biometric_sub')),
                  trailing: Switch(
                    value: controller.isBiometricEnabledForCurrentUser,
                    onChanged: (val) async {
                      final success = await controller.setBiometricEnabled(val);
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(controller.tr('msg_biometric_fail'))),
                        );
                      }
                    },
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined, color: colors.error),
                  title: Text(controller.tr('settings_reset'), style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
                  subtitle: Text(controller.tr('settings_reset_sub')),
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
        title: Text(controller.tr('dialog_reset_title')),
        content: Text(controller.tr('dialog_reset_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(controller.tr('btn_cancel')),
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
                SnackBar(content: Text(controller.tr('msg_reset_success'))),
              );
            },
            child: Text(controller.tr('btn_reset')),
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
