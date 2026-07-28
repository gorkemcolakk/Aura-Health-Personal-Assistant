import 'package:flutter/material.dart';

import 'widgets/medication_alarm_overlay.dart';

import 'screens/ai_coach_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/pdf_preview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
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
    ChartsScreen(),
    ProfileScreen(),
    AiCoachScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 4) {
      _showQuickActions();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickActionsSheet(parentContext: context),
    );
  }

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
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _screens[_selectedIndex],
                  ),
                ),
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
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: .10),
                        blurRadius: 32,
                        spreadRadius: 0,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: .04),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Row(
                      children: [
                        _DockItem(
                          label: controller.tr('nav_today'),
                          icon: Icons.monitor_heart_outlined,
                          selectedIcon: Icons.monitor_heart,
                          selected: _selectedIndex == 0,
                          onTap: () => _onNavTap(0),
                        ),
                        _DockItem(
                          label: controller.tr('nav_charts'),
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart,
                          selected: _selectedIndex == 1,
                          onTap: () => _onNavTap(1),
                        ),
                        _DockItem(
                          label: controller.tr('nav_profile'),
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          selected: _selectedIndex == 2,
                          onTap: () => _onNavTap(2),
                        ),
                        _DockItem(
                          label: controller.tr('nav_ai'),
                          icon: Icons.auto_awesome_outlined,
                          selectedIcon: Icons.auto_awesome,
                          selected: _selectedIndex == 3,
                          onTap: () => _onNavTap(3),
                        ),
                        _QuickActionDockItem(
                          label: controller.tr('nav_quick'),
                          onTap: () => _onNavTap(4),
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
}

// ─── Standard Dock Item ──────────────────────────────────────
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
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: .80)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey(selected),
                    color: foreground,
                    size: 22,
                  ),
                ),
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

// ─── Quick Action Special Dock Item ─────────────────────────
class _QuickActionDockItem extends StatelessWidget {
  const _QuickActionDockItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurfaceVariant;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: foreground,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

// ─── Quick Actions Bottom Sheet ──────────────────────────────
class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: .28),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                controller.tr('nav_quick'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: colors.onSurfaceVariant, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _ActionItem(
            color: const Color(0xFF1A8C83),
            icon: Icons.water_drop_rounded,
            title: controller.tr('quick_water'),
            subtitle: controller.tr('quick_water_sub'),
            onTap: () {
              Navigator.pop(context);
              showCustomWaterDialog(context, controller);
            },
          ),
          _ActionItem(
            color: const Color(0xFFE76F51),
            icon: Icons.nights_stay_rounded,
            title: controller.tr('quick_sleep'),
            subtitle: controller.tr('quick_sleep_sub'),
            onTap: () {
              Navigator.pop(context);
              showSleepDialog(context, controller);
            },
          ),
          _ActionItem(
            color: const Color(0xFFFFB300),
            icon: Icons.medication_rounded,
            title: controller.tr('quick_med'),
            subtitle: controller.tr('quick_med_sub'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
            },
          ),
          _ActionItem(
            color: const Color(0xFFD32F2F),
            icon: Icons.local_hospital_rounded,
            title: controller.tr('quick_nearby'),
            subtitle: controller.tr('quick_nearby_sub'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(parentContext, MaterialPageRoute(builder: (_) => const NearbyScreen()));
            },
          ),
          _ActionItem(
            color: const Color(0xFF3949AB),
            icon: Icons.picture_as_pdf_rounded,
            title: controller.tr('quick_pdf'),
            subtitle: controller.tr('quick_pdf_sub'),
            onTap: () {
              Navigator.pop(context);
              _showPdfPeriodDialog(parentContext, controller);
            },
          ),
          _ActionItem(
            color: const Color(0xFF607D8B),
            icon: Icons.settings_rounded,
            title: controller.tr('settings_title'),
            subtitle: controller.languageCode == 'tr' ? 'Uygulama ayarlarını yönetin' : 'Manage app settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(parentContext, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// ─── Individual Action Row ───────────────────────────────────
class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant.withValues(alpha: .6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PDF Period Dialog ───────────────────────────────────────
void _showPdfPeriodDialog(BuildContext context, AuraController controller) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3949AB), size: 20),
          ),
          const SizedBox(width: 12),
          Text(controller.tr('quick_pdf')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.languageCode == 'tr'
                ? 'Raporun kapsayacağı zaman aralığını seçin:'
                : 'Select the time range for the report:',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () { Navigator.pop(ctx); _openPdf(context, controller, 7); },
                  child: Text(controller.languageCode == 'tr' ? '7 Günlük' : '7 Days', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () { Navigator.pop(ctx); _openPdf(context, controller, 30); },
                  child: Text(controller.languageCode == 'tr' ? '1 Aylık' : '1 Month', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () { Navigator.pop(ctx); _openPdf(context, controller, 90); },
                  child: Text(controller.languageCode == 'tr' ? '3 Aylık' : '3 Months', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _openPdf(BuildContext context, AuraController controller, int days) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfPreviewScreen(
        profile: controller.profile,
        apiKey: controller.apiKey,
        langCode: controller.languageCode,
        days: days,
      ),
    ),
  );
}
