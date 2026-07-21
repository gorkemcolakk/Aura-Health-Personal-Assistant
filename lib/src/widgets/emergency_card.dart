import 'package:flutter/material.dart';

import '../models/health_profile.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key, required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('🆘 Acil Durum Kartı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Kırmızı acil kart
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'ACİL DURUM BİLGİLERİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // İsim & Kan Grubu
                  _infoRow(
                    icon: Icons.person,
                    label: profile.name.isNotEmpty ? profile.name : 'İsim girilmemiş',
                    value: profile.bloodType.isNotEmpty ? profile.bloodType : '?',
                    valueStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),

                  // Boy & Kilo
                  if (profile.heightCm > 0 && profile.weightKg > 0) ...[
                    const SizedBox(height: 16),
                    _infoRow(
                      icon: Icons.straighten,
                      label: 'Boy / Kilo',
                      value: '${profile.heightCm.toInt()} cm / ${profile.weightKg.toInt()} kg',
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                  ],

                  // Alerjiler
                  const SizedBox(height: 16),
                  _infoSection(
                    icon: Icons.warning_amber,
                    label: 'Alerjiler',
                    content: profile.allergies.isNotEmpty ? profile.allergies : 'Belirtilmemiş',
                    highlight: profile.allergies.isNotEmpty,
                  ),

                  // Kronik durumlar
                  if (profile.conditions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    _infoSection(
                      icon: Icons.monitor_heart,
                      label: 'Kronik Durumlar',
                      content: profile.conditions,
                      highlight: true,
                    ),
                  ],

                  // Acil iletişim
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  if (profile.emergencyContact.isNotEmpty)
                    _infoRow(
                      icon: Icons.contact_phone,
                      label: 'Acil Kişi',
                      value: profile.emergencyContact,
                    ),
                  if (profile.emergencyPhone.isNotEmpty)
                    _infoRow(
                      icon: Icons.phone,
                      label: 'Acil Telefon',
                      value: profile.emergencyPhone,
                      valueStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Açıklama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu kart acil durumlarda sağlık personeline yardımcı olmak içindir. '
                      'Bilgilerinizi Profil sayfasından güncelleyebilirsiniz.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _infoSection({
    required IconData icon,
    required String label,
    required String content,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: highlight ? Colors.yellow : Colors.white70, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: highlight ? Colors.yellow : Colors.white,
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
