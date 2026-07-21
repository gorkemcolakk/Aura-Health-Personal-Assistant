import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../state/aura_scope.dart';

class MedicationAlarmOverlay extends StatelessWidget {
  const MedicationAlarmOverlay({super.key, required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Backdrop Blur (Glassmorphism)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: colors.surface.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Content
        Positioned.fill(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Animated Icon
                _BreathingIcon(
                  icon: Icons.medication_liquid,
                  color: colors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'İlaç Vakti!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${medication.name} (${medication.dosage})\nSaat: ${medication.timeLabel}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
                if (medication.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      medication.notes,
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                  ),
                ],
                const Spacer(),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          controller.markMedicationAsTaken(medication.id);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Şimdi İçtim'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          controller.dismissAlarm();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          foregroundColor: colors.onSurfaceVariant,
                        ),
                        child: const Text('Şimdilik Geç'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BreathingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BreathingIcon({required this.icon, required this.color});

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.15),
        ),
        child: Icon(widget.icon, size: 90, color: widget.color),
      ),
    );
  }
}
