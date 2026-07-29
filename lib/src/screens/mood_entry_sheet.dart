import 'package:flutter/material.dart';
import '../models/mood_log.dart';
import '../state/aura_scope.dart';

class MoodEntrySheet extends StatefulWidget {
  const MoodEntrySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoodEntrySheet(),
    );
  }

  @override
  State<MoodEntrySheet> createState() => _MoodEntrySheetState();
}

class _MoodEntrySheetState extends State<MoodEntrySheet> {
  // 1.0 (Very Bad) to 5.0 (Excellent)
  double _moodValue = 3.0;

  final Set<String> _selectedSymptoms = {};
  final TextEditingController _noteController = TextEditingController();

  final List<String> _symptomsTr = [
    'Baş Ağrısı',
    'Yorgunluk',
    'Uykusuzluk',
    'Stres',
    'Mide Bulantısı',
    'Enerjik',
    'Odaklanmış',
    'Huzursuz',
    'Ağrı',
    'Endişeli'
  ];

  final List<String> _symptomsEn = [
    'Headache',
    'Fatigue',
    'Insomnia',
    'Stress',
    'Nausea',
    'Energetic',
    'Focused',
    'Restless',
    'Pain',
    'Anxious'
  ];

  Color _getMoodColor(double value) {
    if (value <= 1.5) return Colors.redAccent.shade200;
    if (value <= 2.5) return Colors.orangeAccent;
    if (value <= 3.5) return Colors.amber.shade400;
    if (value <= 4.5) return Colors.tealAccent.shade400;
    return Colors.green.shade500;
  }

  String _getMoodEmoji(double value) {
    if (value <= 1.5) return '😣';
    if (value <= 2.5) return '🙁';
    if (value <= 3.5) return '😐';
    if (value <= 4.5) return '🙂';
    return '😁';
  }

  String _getMoodLabel(double value, bool isTr) {
    if (value <= 1.5) return isTr ? 'Çok Kötü' : 'Very Bad';
    if (value <= 2.5) return isTr ? 'Kötü' : 'Bad';
    if (value <= 3.5) return isTr ? 'Nötr' : 'Neutral';
    if (value <= 4.5) return isTr ? 'İyi' : 'Good';
    return isTr ? 'Harika' : 'Excellent';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final isTr = controller.languageCode == 'tr';
    final sysColors = Theme.of(context).colorScheme;
    final activeColor = _getMoodColor(_moodValue);

    final symptoms = isTr ? _symptomsTr : _symptomsEn;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: sysColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            activeColor.withValues(alpha: 0.15),
            sysColors.surface,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: sysColors.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            isTr ? 'Bugün nasıl hissediyorsun?' : 'How are you feeling today?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),

          // Emoji and Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Column(
              key: ValueKey(_moodValue.round()),
              children: [
                Text(
                  _getMoodEmoji(_moodValue),
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 8),
                Text(
                  _getMoodLabel(_moodValue, isTr),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Vertical Slider
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: activeColor,
                      inactiveTrackColor: activeColor.withValues(alpha: 0.2),
                      thumbColor: activeColor,
                      trackHeight: 12,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      overlayColor: activeColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _moodValue,
                      min: 1.0,
                      max: 5.0,
                      divisions: 40, // Allows smooth dragging
                      onChanged: (val) {
                        setState(() {
                          _moodValue = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Symptoms
          Text(
            isTr ? 'Belirtiler (İsteğe bağlı)' : 'Symptoms (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((sym) {
              final isSelected = _selectedSymptoms.contains(sym);
              return FilterChip(
                label: Text(sym),
                selected: isSelected,
                selectedColor: activeColor.withValues(alpha: 0.3),
                checkmarkColor: activeColor,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSymptoms.add(sym);
                    } else {
                      _selectedSymptoms.remove(sym);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: isTr ? 'Günün hakkında bir not...' : 'A note about your day...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: activeColor, width: 2),
              ),
              prefixIcon: Icon(Icons.edit_note, color: activeColor),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Save Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: sysColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              // Save
              final log = MoodLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                timestamp: DateTime.now(),
                moodLevel: _moodValue.round(), // Save as 1-5 integer
                symptoms: _selectedSymptoms.toList(),
                note: _noteController.text.trim(),
              );
              controller.addMoodLog(log);
              Navigator.of(context).pop();
            },
            child: Text(
              isTr ? 'Kaydet' : 'Save',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
