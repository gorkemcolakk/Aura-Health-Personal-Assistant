import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_profile.dart';
import '../models/medication.dart';
import 'health_calculator.dart';

class AiCoachService {
  static const _endpoint = 'https://api.deepseek.com/v1/chat/completions';
  static const _model = 'deepseek-chat';

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
      final systemPrompt = _buildPrompt(profile, medications);

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': question},
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      });

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        return text?.toString().trim() ?? 'Aura şu an cevap veremiyor.';
      }

      final errorBody = jsonDecode(response.body);
      final errorMsg = errorBody['error']?['message'] ?? 'Bilinmeyen hata';

      if (response.statusCode == 401) {
        return 'DeepSeek API anahtarı geçersiz.\n\n${_offlineAnswer(profile, question)}';
      }
      if (response.statusCode == 402) {
        return 'DeepSeek hesabında yeterli bakiye yok.\n\n${_offlineAnswer(profile, question)}';
      }
      if (response.statusCode == 429) {
        return 'Çok fazla soru sordun, biraz dinlen.\n(Offline mod: Bol su iç, uykunu al.)';
      }
      return 'API hatası (${response.statusCode}): $errorMsg\n\n${_offlineAnswer(profile, question)}';
    } catch (e) {
      // Show real error to diagnose the issue
      return 'HATA DETAYI: $e\n\n${_offlineAnswer(profile, question)}';
    }
  }

  String _buildPrompt(HealthProfile profile, List<Medication> medications) {
    final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
    final sleepLogs = profile.sleepLogs;
    final lastSleep = sleepLogs.isNotEmpty ? sleepLogs.last : null;
    final sleepText = lastSleep != null
        ? "\n- Son Uykusu: ${lastSleep.hours} saat (${lastSleep.feeling})"
        : "";
    final medList = medications.map((m) => "- ${m.name} (${m.dosage})").join('\n');

    return '''
Sen uzman bir sağlık koçu ve doktor, diyetisyen, spor eğitmeni "Aura Health AI"sın.
Hastanın profili:
- İsim: ${profile.name}
- Yaş: ${profile.age}
- Boy: ${profile.heightCm} cm
- Kilo: ${profile.weightKg} kg
- Aktivite seviyesi: ${profile.activity.name}
- Sağlık hedefi: ${profile.healthGoal}
- Hastalıklar/Durum: ${profile.conditions.isEmpty ? 'Belirtilmedi' : profile.conditions}
- Alerjiler: ${profile.allergies.isEmpty ? 'Belirtilmedi' : profile.allergies}
- Bugün İçilen Su: ${HealthCalculator.todayWaterMl(profile)} / $waterTarget ml$sleepText
- Vücut Kitle İndeksi (VKİ): ${HealthCalculator.bmi(profile).toStringAsFixed(1)}

Şu anki ilaçları:
$medList

Kısa, samimi, empatik ve motive edici cevaplar ver. Tıbbi tavsiye verme, sadece sağlıklı yaşam koçluğu yap.
''';
  }

  String _offlineAnswer(HealthProfile profile, String question) {
    final bmi = HealthCalculator.bmi(profile);
    final water = HealthCalculator.dailyWaterTargetMl(profile);
    final label = HealthCalculator.bmiLabel(bmi);
    return '''
Yerel Aura yorumu:

VKİ değerin yaklaşık ${bmi.toStringAsFixed(1)} ve kategori "$label". Günlük su hedefin yaklaşık ${(water / 1000).toStringAsFixed(1)} L. Bugün ${HealthCalculator.todayWaterMl(profile)} ml kaydetmişsin; küçük aralıklarla su içmek hedefe ulaşmayı kolaylaştırır.

"$question" için güvenli önerim: belirti, ağrı, ilaç yan etkisi veya ani değişim varsa bunu kişisel tıbbi karar gibi ele alma; hekim ya da eczacıya danış. Günlük takip, uyku, su ve ilaç düzeni tarafında yardımcı olabilirim.
''';
  }

  Future<String> generateDoctorSummary({
    required HealthProfile profile,
    String? apiKey,
  }) async {
    final key = (apiKey ?? '').trim();
    if (key.isEmpty) {
      return 'Yapay zeka asistanı aktif değil. Hastanın genel sağlık durumu ekteki verilerde sunulmuştur. Ortalama değerlere dikkat edilmesi önerilir.';
    }

    try {
      final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
      final bmi = HealthCalculator.bmi(profile);
      
      final systemPrompt = '''Sen uzman bir doktora ön değerlendirme sunan tıbbi asistan "Aura"sın.
Hastanın bilgileri:
- Yaş: ${profile.age}, Boy: ${profile.heightCm} cm, Kilo: ${profile.weightKg} kg, VKİ: ${bmi.toStringAsFixed(1)}
- Mevcut Durum/Hastalık: ${profile.conditions.isEmpty ? 'Yok' : profile.conditions}
- Alerjiler: ${profile.allergies.isEmpty ? 'Yok' : profile.allergies}
- Sağlık Hedefi: ${profile.healthGoal}
- Günlük Su Hedefi: $waterTarget ml

Görevin: Bu verileri okuyan uzman doktor için kısa, net ve öz (en fazla 3-4 cümlelik) bir tıbbi ön değerlendirme ve özet yazmak. Hastanın durumunu, hedeflerini ve dikkat etmesi gereken noktaları profesyonel bir tıbbi dille anlat. Sadece doktorun okuyacağı bir rapor notu olarak hazırla. Selamlama veya kapanış yapma.''';

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': 'Lütfen doktor raporu için kapsamlı hasta özetini oluştur.'},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      });

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: body,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content']?.toString().trim() ?? 'Yapay zeka ozeti olusturulamadi.';
      }
      return 'Yapay zeka ozeti olusturulamadi (Hata kodu: ${response.statusCode}).';
    } catch (e) {
      final bmi = HealthCalculator.bmi(profile);
      final bmiText = HealthCalculator.bmiLabel(bmi);
      return 'Yapay zeka sunucusuna baglanilamadi. Yerel Sistem Ozeti: Hastanin VKI degeri ${bmi.toStringAsFixed(1)} ($bmiText). Su hedefine ve uyku duzenine dikkat edilmesi saglikli yasam icin tavsiye edilir.';
    }
  }
}

