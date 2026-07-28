import 'package:flutter/material.dart';

import '../models/health_profile.dart';
import '../services/health_calculator.dart';
import '../state/aura_scope.dart';
import '../state/aura_controller.dart';
import '../widgets/aura_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goal = TextEditingController();
  final _conditions = TextEditingController();
  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _emergencyPhone = TextEditingController();

  bool _didFill = false;
  bool _isEditMode = false;
  ActivityLevel _activity = ActivityLevel.balanced;
  String _gender = 'Belirtilmedi';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didFill) return;
    _fillFromProfile(AuraScope.of(context).profile);
    _didFill = true;
  }

  void _fillFromProfile(HealthProfile profile) {
    _name.text = profile.name;
    _birthDate.text = HealthProfile.formatToDisplay(profile.birthDate);
    _height.text = profile.heightCm.toStringAsFixed(0);
    _weight.text = profile.weightKg.toStringAsFixed(1);
    _goal.text = profile.healthGoal;
    _conditions.text = profile.conditions;
    _bloodType.text = profile.bloodType;
    _allergies.text = profile.allergies;
    _emergencyContact.text = profile.emergencyContact;
    _emergencyPhone.text = profile.emergencyPhone;
    _activity = profile.activity;
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _birthDate.dispose();
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

  Future<void> _saveProfile(BuildContext context, AuraController controller) async {
    final profile = controller.profile;
    await controller.saveProfile(
      profile.copyWith(
        name: _name.text.trim().isEmpty ? profile.name : _name.text.trim(),
        birthDate: HealthProfile.formatToIso(_birthDate.text.trim()),
        heightCm: double.tryParse(_height.text.replaceAll(',', '.')) ?? profile.heightCm,
        weightKg: double.tryParse(_weight.text.replaceAll(',', '.')) ?? profile.weightKg,
        activity: _activity,
        gender: _gender,
        healthGoal: _goal.text.trim(),
        conditions: _conditions.text.trim(),
        bloodType: _bloodType.text.trim(),
        allergies: _allergies.text.trim(),
        emergencyContact: _emergencyContact.text.trim(),
        emergencyPhone: _emergencyPhone.text.trim(),
      ),
    );
    if (context.mounted) {
      setState(() => _isEditMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.languageCode == 'tr' ? 'Profil güncellendi ✓' : 'Profile updated ✓'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final profile = controller.profile;
    final bmi = HealthCalculator.bmi(profile);
    final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
    final sleepTarget = HealthCalculator.recommendedSleepHours(profile);
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          // ── Hero Header ────────────────────────────────────────
          _buildHeroCard(context, controller, profile, colors),
          const SizedBox(height: 18),

          // ── Stats (view mode only) ─────────────────────────────
          if (!_isEditMode) ...[
            _buildStatCards(context, controller, profile, bmi, waterTarget, sleepTarget, colors),
            const SizedBox(height: 18),
            _buildViewInfo(context, controller, profile, colors),
          ] else ...[
            _buildEditForm(context, controller, profile, colors),
          ],

          const SizedBox(height: 28),
          // ── Logout ────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => controller.logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: .5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(controller.tr('prof_logout'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _confirmDeleteAccount(context, controller),
            style: TextButton.styleFrom(
              foregroundColor: colors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text(
              controller.languageCode == 'tr' ? 'Hesabımı Kalıcı Olarak Sil' : 'Permanently Delete My Account',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuraController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(controller.languageCode == 'tr' ? 'Hesabını Sil' : 'Delete Account'),
        content: Text(controller.languageCode == 'tr'
            ? 'Hesabınız ve tüm sağlık verileriniz (ilaçlar, su takibi, sohbet geçmişi) kalıcı olarak silinecektir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'
            : 'Your account and all health data (medications, water logs, chat history) will be permanently deleted. This action cannot be undone. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(controller.languageCode == 'tr' ? 'Vazgeç' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(controller.languageCode == 'tr' ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card ───────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context, AuraController controller, HealthProfile profile, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.65)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .35), width: 2),
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditMode)
                  Text(
                    controller.languageCode == 'tr' ? 'Düzenleme Modu' : 'Edit Mode',
                    style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12, fontWeight: FontWeight.w500),
                  )
                else ...[
                  Text(
                    profile.name.isEmpty ? 'Kullanıcı' : profile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.tr('act_${profile.activity.name}')} • ${profile.age} ${controller.tr('prof_age_suffix')}',
                    style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 13),
                  ),
                  if (profile.bloodType.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.bloodType,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (_isEditMode) ...[
            // Cancel
            GestureDetector(
              onTap: () {
                _fillFromProfile(controller.profile);
                setState(() => _isEditMode = false);
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            // Save
            GestureDetector(
              onTap: () => _saveProfile(context, AuraScope.of(context)),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: colors.primary, size: 20),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => setState(() => _isEditMode = true),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stat Mini Cards (View Mode) ─────────────────────────────
  Widget _buildStatCards(BuildContext context, AuraController controller, HealthProfile profile,
      double bmi, int waterTarget, double sleepTarget, ColorScheme colors) {
    final bmiLabel = HealthCalculator.bmiLabel(bmi, lang: controller.languageCode);
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.monitor_weight_outlined,
          iconColor: colors.primary,
          value: bmi.toStringAsFixed(1),
          label: controller.tr('dash_bmi'),
          sublabel: bmiLabel,
          context: context,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.water_drop_outlined,
          iconColor: const Color(0xFF1A8C83),
          value: '${(waterTarget / 1000).toStringAsFixed(2)} ${controller.languageCode == 'tr' ? 'Litre' : 'Liters'}',
          label: controller.tr('prof_water_target'),
          sublabel: controller.languageCode == 'tr' ? 'Önerilen' : 'Recommended',
          context: context,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.nights_stay_outlined,
          iconColor: const Color(0xFFE76F51),
          value: '${sleepTarget.toStringAsFixed(1)} ${controller.languageCode == 'tr' ? 'Saat' : 'Hours'}',
          label: controller.tr('prof_sleep_target'),
          sublabel: controller.languageCode == 'tr' ? 'Önerilen' : 'Recommended',
          context: context,
        )),
      ],
    );
  }

  // ─── View Info Card (Read-only) ──────────────────────────────
  Widget _buildViewInfo(BuildContext context, AuraController controller, HealthProfile profile, ColorScheme colors) {
    return AuraCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _ViewSection(
            icon: Icons.person_outline_rounded,
            title: controller.languageCode == 'tr' ? 'Kişisel Bilgiler' : 'Personal Info',
            rows: [
              _InfoRow(controller.tr('prof_name'), profile.name.isEmpty ? '—' : profile.name),
              _InfoRow(controller.tr('prof_gender'), _genderLabel(profile.gender, controller)),
              _InfoRow(controller.languageCode == 'tr' ? 'Doğum Tarihi' : 'Birth Date', '${HealthProfile.formatToDisplay(profile.birthDate)} (${profile.age} ${controller.tr('prof_age_suffix')})'),
            ],
            isFirst: true,
          ),
          _SectionDivider(),
          _ViewSection(
            icon: Icons.straighten_rounded,
            title: controller.languageCode == 'tr' ? 'Fiziksel Bilgiler' : 'Physical Info',
            rows: [
              _InfoRow(controller.tr('prof_height'), '${profile.heightCm.toStringAsFixed(0)} cm'),
              _InfoRow(controller.tr('prof_weight'), '${profile.weightKg.toStringAsFixed(1)} kg'),
              _InfoRow(controller.tr('prof_activity'), controller.tr('act_${profile.activity.name}')),
            ],
          ),
          if (profile.healthGoal.isNotEmpty) ...[
            _SectionDivider(),
            _ViewSection(
              icon: Icons.flag_outlined,
              title: controller.tr('prof_goal'),
              rows: [
                _InfoRow('', profile.healthGoal, valueOnly: true),
              ],
            ),
          ],
          if (profile.conditions.isNotEmpty) ...[
            _SectionDivider(),
            _ViewSection(
              icon: Icons.note_alt_outlined,
              title: controller.tr('prof_conditions'),
              rows: [
                _InfoRow('', profile.conditions, valueOnly: true),
              ],
            ),
          ],
          _SectionDivider(),
          _ViewSection(
            icon: Icons.emergency_outlined,
            title: controller.tr('prof_emerg_info'),
            iconColor: Colors.red,
            titleColor: Colors.red,
            rows: [
              if (profile.bloodType.isNotEmpty) _InfoRow(controller.tr('prof_blood'), profile.bloodType),
              if (profile.allergies.isNotEmpty) _InfoRow(controller.tr('prof_allergies'), profile.allergies),
              if (profile.emergencyContact.isNotEmpty) _InfoRow(controller.tr('prof_emerg_contact'), profile.emergencyContact),
              if (profile.emergencyPhone.isNotEmpty) _InfoRow(controller.tr('prof_emerg_phone'), profile.emergencyPhone),
              if (profile.bloodType.isEmpty && profile.allergies.isEmpty && profile.emergencyContact.isEmpty && profile.emergencyPhone.isEmpty)
                _InfoRow('', controller.languageCode == 'tr' ? 'Bilgi girilmemiş' : 'No information added', valueOnly: true),
            ],
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ─── Edit Form ───────────────────────────────────────────────
  Widget _buildEditForm(BuildContext context, AuraController controller, HealthProfile profile, ColorScheme colors) {
    return Column(
      children: [
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.person_outline_rounded,
                title: controller.languageCode == 'tr' ? 'Kişisel Bilgiler' : 'Personal Info',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: controller.tr('prof_name'), prefixIcon: const Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: ['Erkek', 'Kadın', 'Belirtilmedi'].contains(_gender) ? _gender : 'Belirtilmedi',
                      decoration: InputDecoration(labelText: controller.tr('prof_gender'), prefixIcon: const Icon(Icons.wc)),
                      items: [
                        DropdownMenuItem(value: 'Erkek', child: Text(controller.tr('prof_gender_m'))),
                        DropdownMenuItem(value: 'Kadın', child: Text(controller.tr('prof_gender_f'))),
                        DropdownMenuItem(value: 'Belirtilmedi', child: Text(controller.tr('prof_gender_u'))),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _gender = v); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _birthDate,
                      readOnly: true,
                      onTap: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _birthDate.text.isNotEmpty 
                              ? (DateTime.tryParse(HealthProfile.formatToIso(_birthDate.text)) ?? DateTime(now.year - 20))
                              : DateTime(now.year - 20),
                          firstDate: DateTime(1900),
                          lastDate: now,
                        );
                        if (date != null) {
                          setState(() {
                            _birthDate.text = HealthProfile.formatToDisplay(date.toIso8601String().split('T').first);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: controller.languageCode == 'tr' ? 'Doğum Tarihi' : 'Birth Date', 
                        prefixIcon: const Icon(Icons.cake_outlined)
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.straighten_rounded,
                title: controller.languageCode == 'tr' ? 'Fiziksel Bilgiler' : 'Physical Info',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ActivityLevel>(
                isExpanded: true,
                initialValue: _activity,
                decoration: InputDecoration(labelText: controller.tr('prof_activity'), prefixIcon: const Icon(Icons.directions_run)),
                items: ActivityLevel.values.map((a) {
                  String label = a.label;
                  if (a == ActivityLevel.low) label = controller.tr('act_low');
                  if (a == ActivityLevel.balanced) label = controller.tr('act_balanced');
                  if (a == ActivityLevel.active) label = controller.tr('act_active');
                  if (a == ActivityLevel.athletic) label = controller.tr('act_athletic');
                  return DropdownMenuItem(value: a, child: Text(label));
                }).toList(),
                onChanged: (v) { if (v != null) setState(() => _activity = v); },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: controller.tr('prof_height'), prefixIcon: const Icon(Icons.straighten)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: controller.tr('prof_weight'), prefixIcon: const Icon(Icons.scale)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.flag_outlined, title: controller.tr('prof_goal')),
              const SizedBox(height: 14),
              TextField(
                controller: _goal,
                maxLines: 2,
                decoration: InputDecoration(labelText: controller.tr('prof_goal'), prefixIcon: const Icon(Icons.flag_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _conditions,
                maxLines: 3,
                decoration: InputDecoration(labelText: controller.tr('prof_conditions'), prefixIcon: const Icon(Icons.note_alt_outlined)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.emergency_outlined, title: controller.tr('prof_emerg_info'), iconColor: Colors.red, titleColor: Colors.red),
              const SizedBox(height: 14),
              TextField(
                controller: _bloodType,
                decoration: InputDecoration(labelText: controller.tr('prof_blood'), prefixIcon: const Icon(Icons.bloodtype)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _allergies,
                maxLines: 2,
                decoration: InputDecoration(labelText: controller.tr('prof_allergies'), prefixIcon: const Icon(Icons.warning_amber)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emergencyContact,
                decoration: InputDecoration(labelText: controller.tr('prof_emerg_contact'), prefixIcon: const Icon(Icons.person_add)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emergencyPhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: controller.tr('prof_emerg_phone'), prefixIcon: const Icon(Icons.phone)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _saveProfile(context, AuraScope.of(context)),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.check_rounded),
                label: Text(AuraScope.of(context).tr('btn_save')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _genderLabel(String gender, AuraController c) {
    if (gender == 'Erkek') return c.tr('prof_gender_m');
    if (gender == 'Kadın') return c.tr('prof_gender_f');
    return c.tr('prof_gender_u');
  }
}

// ─── Helper Widgets ──────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.context,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final colors = Theme.of(ctx).colorScheme;
    return AuraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colors.onSurface), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          Text(sublabel, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ViewSection extends StatelessWidget {
  const _ViewSection({
    required this.icon,
    required this.title,
    required this.rows,
    this.iconColor,
    this.titleColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final List<_InfoRow> rows;
  final Color? iconColor;
  final Color? titleColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colors.primary;
    final effectiveTitleColor = titleColor ?? colors.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, isFirst ? 20 : 16, 20, isLast ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: effectiveIconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: effectiveTitleColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueOnly = false});

  final String label;
  final String value;
  final bool valueOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (valueOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.onSurface)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 20,
      endIndent: 20,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .4),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.iconColor, this.titleColor});

  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: (iconColor ?? colors.primary).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor ?? colors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor ?? colors.onSurface),
        ),
      ],
    );
  }
}
