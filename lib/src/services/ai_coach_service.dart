import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/health_profile.dart';
import '../models/medication.dart';
import 'health_calculator.dart';

class AiCoachService {
  Future<String> ask({
    required HealthProfile profile,
    required List<Medication> medications,
    required String question,
    String? apiKey,
  }) async {
    final key = (apiKey ?? '').trim();
    if (key.isEmpty) {
      return _offlineAnswer(profile, question);
    }

    try {
      final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
      final sleepLogs = profile.sleepLogs;
      final lastSleep = sleepLogs.isNotEmpty ? sleepLogs.last : null;
      final sleepText = lastSleep != null
          ? "\n- Son Uykusu: ${lastSleep.hours} saat (${lastSleep.feeling})"
          : "";
      final medList = medications.map((m) => "- ${m.name} (${m.dosage})").join('\n');

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        systemInstruction: Content.system('''
Sen uzman bir sağlık koçu ve doktor, diyetisyen, spor eğitmeni "Aura Health AI"sın.
Hastanın profili:
- İsim: ${profile.name}
- Yaş: ${profile.age}
- Boy: ${profile.heightCm} cm
- Kilo: ${profile.weightKg} kg
- Aktivite seviyesi: ${profile.activity.name}
- Sağlık hedefi: ${profile.healthGoal}
- Hastalıklar/Alerjiler/Durum: ${profile.conditions}
- Bugün İçilen Su: ${profile.waterConsumedMl} / $waterTarget ml$sleepText
- Vücut Kitle İndeksi (VKİ): ${HealthCalculator.bmi(profile).toStringAsFixed(1)}

Şu anki ilaçları:
$medList

Kısa, samimi, empatik ve motive edici cevaplar ver. Tıbbi tavsiye verme, sadece sağlıklı yaşam koçluğu yap.
'''),
      );

      final response = await model.generateContent([Content.text(question)]);
      return response.text?.trim() ?? 'Aura şu an cevap veremiyor.';
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      String friendlyMessage = 'Bir hata oluştu.';
      if (errorStr.contains('quota') || errorStr.contains('rate') || errorStr.contains('429')) {
        friendlyMessage = 'Çok fazla soru sordun, API limitine takıldın. Lütfen yaklaşık 1 dakika bekleyip tekrar dene.';
      } else if (errorStr.contains('key') || errorStr.contains('invalid') || errorStr.contains('403') || errorStr.contains('401')) {
        friendlyMessage = 'API anahtarın geçersiz veya yetkisiz. Hata: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}';
      } else if (errorStr.contains('socket') || errorStr.contains('host') || errorStr.contains('network')) {
        friendlyMessage = 'İnternet bağlantını kontrol et.';
      } else {
        friendlyMessage = 'Yapay zeka servisine bağlanılamadı. Hata: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}';
      }
      return '$friendlyMessage\n\n${_offlineAnswer(profile, question)}';
    }
  }

  String _offlineAnswer(HealthProfile profile, String question) {
    final bmi = HealthCalculator.bmi(profile);
    final water = HealthCalculator.dailyWaterTargetMl(profile);
    final label = HealthCalculator.bmiLabel(bmi);
    return '''
Yerel Aura yorumu:

VKİ değerin yaklaşık ${bmi.toStringAsFixed(1)} ve kategori "$label". Günlük su hedefin yaklaşık ${(water / 1000).toStringAsFixed(1)} L. Bugün ${profile.waterConsumedMl} ml kaydetmişsin; küçük aralıklarla su içmek hedefe ulaşmayı kolaylaştırır.

"$question" için güvenli önerim: belirti, ağrı, ilaç yan etkisi veya ani değişim varsa bunu kişisel tıbbi karar gibi ele alma; hekim ya da eczacıya danış. Günlük takip, uyku, su ve ilaç düzeni tarafında yardımcı olabilirim.
''';
  }
}
