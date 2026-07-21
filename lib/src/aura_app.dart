import 'package:flutter/material.dart';

import 'widgets/medication_alarm_overlay.dart';

import 'screens/ai_coach_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/profile_screen.dart';
import 'state/aura_scope.dart';
import 'state/aura_controller.dart';
import 'theme/aura_theme.dart';

class AuraApp extends StatelessWidget {
  const AuraApp({super.key, required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    return AuraScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Aura Health',
            debugShowCheckedModeBanner: false,
            theme: AuraTheme.light(),
            darkTheme: AuraTheme.dark(),
            themeMode: controller.themeMode,
            home: controller.currentUserTc == null
                ? const LoginScreen()
                : const AuraShell(),
          );
        },
      ),
    );
  }
}

class AuraShell extends StatefulWidget {
  const AuraShell({super.key});

  @override
  State<AuraShell> createState() => _AuraShellState();
}

class _AuraShellState extends State<AuraShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ProfileScreen(),
    MedicationScreen(),
    AiCoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controller = AuraScope.of(context);
    final activeAlarm = controller.activeAlarm;

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _screens[_selectedIndex],
            ),
          ),
          const Positioned(
            top: 56,
            right: 16,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: .08),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _DockItem(
                      label: 'Bugün',
                      icon: Icons.monitor_heart_outlined,
                      selectedIcon: Icons.monitor_heart,
                      selected: _selectedIndex == 0,
                      onTap: () => _select(0),
                    ),
                    _DockItem(
                      label: 'Profil',
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      selected: _selectedIndex == 1,
                      onTap: () => _select(1),
                    ),
                    _DockItem(
                      label: 'İlaç',
                      icon: Icons.medication_liquid_outlined,
                      selectedIcon: Icons.medication_liquid,
                      selected: _selectedIndex == 2,
                      onTap: () => _select(2),
                    ),
                    _DockItem(
                      label: 'AI',
                      icon: Icons.auto_awesome_outlined,
                      selectedIcon: Icons.auto_awesome,
                      selected: _selectedIndex == 3,
                      onTap: () => _select(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    if (activeAlarm != null)
      Positioned.fill(
        child: MedicationAlarmOverlay(medication: activeAlarm),
      ),
    ],
  );
}

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: .86)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, color: foreground),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = controller.themeMode;

    IconData icon;
    if (mode == ThemeMode.system) {
      icon = Icons.brightness_medium;
    } else if (mode == ThemeMode.dark) {
      icon = Icons.dark_mode;
    } else {
      icon = Icons.light_mode;
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        tooltip: 'Tema Değiştir',
        onPressed: () {
          ThemeMode nextMode;
          if (mode == ThemeMode.system) {
            nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
          } else if (mode == ThemeMode.dark) {
            nextMode = ThemeMode.light;
          } else {
            nextMode = ThemeMode.system;
          }
          controller.setThemeMode(nextMode);
        },
      ),
    );
  }
}
