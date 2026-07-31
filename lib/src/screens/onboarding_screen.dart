import 'package:flutter/material.dart';
import '../state/aura_controller.dart';
import '../state/aura_scope.dart';
import '../models/health_profile.dart';
import '../aura_app.dart'; // To navigate to AuraShell

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Basics
  String _gender = 'Belirtilmedi';
  final _birthDateController = TextEditingController();

  // Step 2: Physical
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  ActivityLevel _activity = ActivityLevel.balanced;

  // Step 3: Goals & Conditions
  final _goalController = TextEditingController();
  final _conditionsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finish() async {
    final controller = AuraScope.of(context, listen: false);
    
    // Save all to profile
    final updatedProfile = controller.profile.copyWith(
      gender: _gender,
      birthDate: HealthProfile.formatToIso(_birthDateController.text),
      heightCm: double.tryParse(_heightController.text) ?? 0.0,
      weightKg: double.tryParse(_weightController.text) ?? 0.0,
      activity: _activity,
      healthGoal: _goalController.text,
      conditions: _conditionsController.text,
    );

    await controller.saveProfile(updatedProfile);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuraShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final isTr = controller.languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(isTr ? 'Atla' : 'Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildStep1(isTr, controller),
                  _buildStep2(isTr, controller),
                  _buildStep3(isTr, controller),
                ],
              ),
            ),
            _buildBottomNav(isTr),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(bool isTr, AuraController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.waving_hand_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            isTr ? 'Aura Health\'e Hoş Geldin!' : 'Welcome to Aura Health!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isTr ? 'Seni daha iyi tanıyabilmemiz için birkaç sorumuz var.' : 'We have a few questions to get to know you better.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _gender,
            decoration: InputDecoration(
              labelText: controller.tr('prof_gender'),
              prefixIcon: const Icon(Icons.wc),
            ),
            items: [
              DropdownMenuItem(value: 'Erkek', child: Text(controller.tr('prof_gender_m'))),
              DropdownMenuItem(value: 'Kadın', child: Text(controller.tr('prof_gender_f'))),
              DropdownMenuItem(value: 'Belirtilmedi', child: Text(controller.tr('prof_gender_u'))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _gender = val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _birthDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: controller.tr('prof_birth'),
              prefixIcon: const Icon(Icons.cake_outlined),
            ),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(now.year - 20),
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
        ],
      ),
    );
  }

  Widget _buildStep2(bool isTr, AuraController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            isTr ? 'Fiziksel Özelliklerin' : 'Physical Attributes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: controller.tr('prof_height'),
                    suffixText: 'cm',
                    prefixIcon: const Icon(Icons.height),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: controller.tr('prof_weight'),
                    suffixText: 'kg',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<ActivityLevel>(
            isExpanded: true,
            initialValue: _activity,
            decoration: InputDecoration(
              labelText: controller.tr('prof_activity'),
              prefixIcon: const Icon(Icons.directions_run),
            ),
            items: ActivityLevel.values.map((a) {
              String label = a.label;
              if (a == ActivityLevel.low) label = controller.tr('act_low');
              if (a == ActivityLevel.balanced) label = controller.tr('act_balanced');
              if (a == ActivityLevel.active) label = controller.tr('act_active');
              if (a == ActivityLevel.athletic) label = controller.tr('act_athletic');
              return DropdownMenuItem(value: a, child: Text(label));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _activity = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isTr, AuraController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.flag_circle_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            isTr ? 'Hedeflerin ve Sağlık Durumun' : 'Goals and Health Status',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _goalController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: controller.tr('prof_goal'),
              hintText: isTr ? 'Kilo vermek, kas yapmak, daha iyi uyumak...' : 'Lose weight, build muscle, sleep better...',
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _conditionsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: controller.tr('prof_conditions'),
              hintText: isTr ? 'Diyabet, hipertansiyon vb. (Yoksa boş bırakın)' : 'Diabetes, hypertension etc. (Leave empty if none)',
              prefixIcon: const Icon(Icons.medical_information_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isTr) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(isTr ? 'Geri' : 'Back'),
                )
              : TextButton(
                  onPressed: _finish,
                  child: Text(isTr ? 'Atla' : 'Skip'),
                ),
          Row(
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          _currentPage < 2
              ? FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(isTr ? 'İleri' : 'Next'),
                )
              : FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(isTr ? 'Tamamla' : 'Finish'),
                ),
        ],
      ),
    );
  }
}
