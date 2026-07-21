import 'package:flutter/material.dart';

import '../models/health_profile.dart';
import '../state/aura_scope.dart';
import '../widgets/aura_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goal = TextEditingController();
  final _conditions = TextEditingController();
  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _emergencyPhone = TextEditingController();
  bool _didFill = false;
  ActivityLevel _activity = ActivityLevel.balanced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didFill) {
      return;
    }
    final profile = AuraScope.of(context).profile;
    _name.text = profile.name;
    _age.text = profile.age.toString();
    _height.text = profile.heightCm.toStringAsFixed(0);
    _weight.text = profile.weightKg.toStringAsFixed(1);
    _goal.text = profile.healthGoal;
    _conditions.text = profile.conditions;
    _bloodType.text = profile.bloodType;
    _allergies.text = profile.allergies;
    _emergencyContact.text = profile.emergencyContact;
    _emergencyPhone.text = profile.emergencyPhone;
    _activity = profile.activity;
    _didFill = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _goal.dispose();
    _conditions.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    _emergencyContact.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final profile = controller.profile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'VKİ, su ihtiyacı ve AI önerileri bu bilgilerle hesaplanır.',
          ),
          const SizedBox(height: 18),
          AuraCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Ad soyad',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Yaş',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ActivityLevel>(
                        initialValue: _activity,
                        decoration: const InputDecoration(
                          labelText: 'Aktivite',
                          prefixIcon: Icon(Icons.directions_run),
                        ),
                        items: ActivityLevel.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _activity = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm)',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg)',
                          prefixIcon: Icon(Icons.scale),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goal,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Sağlık hedefi',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _conditions,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notlar, hassasiyetler, tanılar',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                // --- Acil Durum Bilgileri ---
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Acil Durum Bilgileri',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bloodType,
                  decoration: const InputDecoration(
                    labelText: 'Kan Grubu (örn: A Rh+)',
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _allergies,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alerjiler (örn: Penisilin, Fıstık)',
                    prefixIcon: Icon(Icons.warning_amber),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyContact,
                  decoration: const InputDecoration(
                    labelText: 'Acil Durumda Aranacak Kişi',
                    prefixIcon: Icon(Icons.person_add),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Acil Durum Telefonu',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await controller.saveProfile(
                      profile.copyWith(
                        name: _name.text.trim().isEmpty
                            ? profile.name
                            : _name.text.trim(),
                        age: int.tryParse(_age.text.trim()) ?? profile.age,
                        heightCm:
                            double.tryParse(
                              _height.text.replaceAll(',', '.'),
                            ) ??
                            profile.heightCm,
                        weightKg:
                            double.tryParse(
                              _weight.text.replaceAll(',', '.'),
                            ) ??
                            profile.weightKg,
                        activity: _activity,
                        healthGoal: _goal.text.trim(),
                        conditions: _conditions.text.trim(),
                        bloodType: _bloodType.text.trim(),
                        allergies: _allergies.text.trim(),
                        emergencyContact: _emergencyContact.text.trim(),
                        emergencyPhone: _emergencyPhone.text.trim(),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil güncellendi')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Kaydet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AuraCard(
            color: const Color(0xFFEAF6F4),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'API anahtarı cihazda tutulur. Yayına çıkmadan önce güvenli anahtar kasasına taşınmalı.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              controller.logout();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Hesaptan Çıkış Yap', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
