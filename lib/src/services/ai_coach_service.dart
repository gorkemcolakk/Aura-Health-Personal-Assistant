import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/health_profile.dart';
import '../models/medication.dart';
import 'health_calculator.dart';
import 'weather_service.dart';

class AiCoachService {
  static const _endpoint = 'https://api.deepseek.com/v1/chat/completions';
  static const _model = 'deepseek-chat';

  Future<String> ask({
    required HealthProfile profile,
    required List<Medication> medications,
    required String question,
    required String langCode,
    WeatherData? weather,
    String? apiKey,
  }) async {
    final key = (apiKey ?? '').trim();
    if (key.isEmpty) {
      return _offlineAnswer(profile, question);
    }

    try {
      final systemPrompt = _buildPrompt(profile, medications, langCode, weather);

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

  String _buildPrompt(HealthProfile profile, List<Medication> medications, String langCode, WeatherData? weather) {
    final waterTarget = HealthCalculator.dailyWaterTargetMl(profile, currentTemp: weather?.temperature);
    final sleepLogs = profile.sleepLogs;
    final lastSleep = sleepLogs.isNotEmpty ? sleepLogs.first : null;
    final sleepText = lastSleep != null
        ? "\n- Son Uykusu: ${lastSleep.hours} saat (${lastSleep.feeling})"
        : "";
    final medList = medications.map((m) => "- ${m.name} (${m.dosage})").join('\n');

    final moodLogs = profile.moodLogs;
    final lastMood = moodLogs.isNotEmpty ? moodLogs.last : null;
    final moodText = lastMood != null 
        ? "\n- Bugün Hissedilen Duygu (1-5): ${lastMood.moodLevel}/5 (Belirtiler: ${lastMood.symptoms.isEmpty ? 'Yok' : lastMood.symptoms.join(', ')})"
        : "";

    final isSameDay = (DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final todayBreath = profile.breathLogs.where((l) => isSameDay(l.timestamp, DateTime.now())).fold<int>(0, (s, l) => s + l.durationMinutes);
    final breathText = todayBreath > 0 ? "\n- Bugün Yapılan Nefes Egzersizi (Farkındalık): $todayBreath dakika" : "";

    final weatherText = weather != null 
        ? "\n- Dışarıdaki Hava (${weather.city}): ${weather.temperature.toStringAsFixed(1)}°C, ${weather.condition}" 
        : "";

    return '''
Sen uzman bir sağlık koçu, doktor, diyetisyen, spor eğitmeni ve günlük yaşam asistanı "Aura Health AI"sın.
Hastanın profili:
- İsim: ${profile.name}
- Cinsiyet: ${profile.gender}
- Yaş: ${profile.age}
- Boy: ${profile.heightCm} cm
- Kilo: ${profile.weightKg} kg
- Aktivite seviyesi: ${profile.activity.name}
- Sağlık hedefi: ${profile.healthGoal}
- Hastalıklar/Durum: ${profile.conditions.isEmpty ? 'Belirtilmedi' : profile.conditions}
- Alerjiler: ${profile.allergies.isEmpty ? 'Belirtilmedi' : profile.allergies}
- Bugün İçilen Su: ${HealthCalculator.todayWaterMl(profile)} / $waterTarget ml$sleepText$moodText$breathText$weatherText
- Vücut Kitle İndeksi (VKİ): ${HealthCalculator.bmi(profile).toStringAsFixed(1)}

Şu anki ilaçları:
$medList

Senin kişiliğin: Asla robotik, ezberlenmiş, madde madde veya basmakalıp (yapay zeka gibi) cevaplar verme. Kullanıcıyla WhatsApp'tan yazışan, son derece doğal, empatik, zeki ve samimi bir yaşam koçu / arkadaş gibi konuş. Yanıtların günlük konuşma dilinde, akıcı ve bağlama uygun olmalı. 

Sağlık koçluğu kuralı: 
1. Eğer kullanıcı senden kapsamlı bir analiz, özet ("bugünkü özetim", "durumum nasıl") veya detaylı tavsiye isterse: Sağlık verilerini derinlemesine analiz et. Yanıtını yapılandırılmış, okunması kolay (madde madde, kalın yazılarla) ve zekice tasarla. Adeta uzman bir doktor veya koç gibi tüm detayları (uyku, su, ruh hali, hava durumu) harmanla ve uzun, tatmin edici bir rapor sun.
2. Eğer kullanıcı sadece sohbet ediyorsa veya spesifik kısa bir şey soruyorsa: Verileri her defasında listeleme. Sadece soruya odaklan.

ÇOK ÖNEMLİ KURAL (Sohbet Akışı): Eğer kullanıcı "tamam", "teşekkürler", "anladım", "peki", "görüşürüz" gibi muhabbeti kapatan veya sadece onaylayan kısa şeyler yazarsa, KESİNLİKLE uzun sağlık tavsiyeleri verme! Tıpkı bir insan gibi sadece "Rica ederim, kendine iyi bak! 😊", "Süper, görüşmek üzere!" gibi son derece kısa, doğal ve tek cümlelik yanıtlarla sohbeti tamamla.

IMPORTANT: You MUST reply in the language specified by the ISO code: "$langCode". If it's "en", reply entirely in English. If it's "tr", reply entirely in Turkish.
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
    required List<Medication> medications,
    required String langCode,
    String? apiKey,
    int days = 7,
  }) async {
    final key = (apiKey ?? '').trim();
    if (key.isEmpty) {
      return 'Yapay zeka asistanı aktif değil. Hastanın genel sağlık durumu ekteki verilerde sunulmuştur. Ortalama değerlere dikkat edilmesi önerilir.';
    }

    try {
      final waterTarget = HealthCalculator.dailyWaterTargetMl(profile);
      final sleepTarget = HealthCalculator.recommendedSleepHours(profile);
      final bmi = HealthCalculator.bmi(profile);
      
      final dataSleep = HealthCalculator.getHistoricalSleepData(profile, days: days);
      final avgSleep = dataSleep.isEmpty ? 0.0 : dataSleep.map((e) => e.hours).reduce((a, b) => a + b) / days;
      final reachedSleepDays = dataSleep.where((d) => d.hours >= sleepTarget).length;

      final dataWater = HealthCalculator.getHistoricalWaterData(profile, days: days);
      final avgWater = dataWater.isEmpty ? 0.0 : dataWater.map((e) => e.amountMl).reduce((a, b) => a + b) / days;
      final reachedWaterDays = dataWater.where((d) => d.amountMl >= waterTarget).length;
      
      final dataMood = profile.moodLogs.where((log) => DateTime.now().difference(log.timestamp).inDays <= days).toList();
      final avgMood = dataMood.isEmpty ? 0.0 : dataMood.map((e) => e.moodLevel).reduce((a, b) => a + b) / dataMood.length;
      final recentSymptoms = dataMood.expand((e) => e.symptoms).toSet().join(', ');

      final medList = medications.isEmpty ? 'Yok' : medications.map((m) => "- ${m.name} (${m.dosage})").join('\n');
      
      final systemPrompt = '''Sen uzman bir doktora ön değerlendirme sunan tıbbi asistan "Aura"sın.
Hastanın bilgileri:
- Cinsiyet: ${profile.gender}, Yaş: ${profile.age}, Boy: ${profile.heightCm} cm, Kilo: ${profile.weightKg} kg, VKİ: ${bmi.toStringAsFixed(1)}
- Mevcut Durum/Hastalık: ${profile.conditions.isEmpty ? 'Yok' : profile.conditions}
- Alerjiler: ${profile.allergies.isEmpty ? 'Yok' : profile.allergies}
- Sağlık Hedefi: ${profile.healthGoal}

Rapor Periyodu: Son $days Günlük Veriler
- Ortalama Uyku Süresi: ${avgSleep.toStringAsFixed(1)} saat/gün (Hedef: ${sleepTarget.toStringAsFixed(1)} saat, Hedefe ulaşılan gün sayısı: $reachedSleepDays/$days)
- Ortalama Su Tüketimi: ${avgWater.round()} ml/gün (Hedef: $waterTarget ml, Hedefe ulaşılan gün sayısı: $reachedWaterDays/$days)
- Duygu Durumu Ortalaması (1-5): ${avgMood > 0 ? avgMood.toStringAsFixed(1) : 'Veri Yok'} (Sık Görülen Belirtiler: ${recentSymptoms.isEmpty ? 'Yok' : recentSymptoms})

Kullandığı İlaçlar ve Programı:
$medList

Görevin: Bu verileri ve geçmiş performansları okuyan uzman doktor için kapsamlı ve detaylı (yaklaşık 5-7 cümlelik) bir tıbbi ön değerlendirme ve özet yazmak. Hastanın cinsiyeti, yaş, VKİ, alerjileri, mevcut durumu, sağlık hedefleri ve bu süreçteki uyku/su karnesini dikkate alarak profesyonel bir tıbbi dille açıklama yap. Gerekli önerileri ve dikkat edilmesi gereken noktaları da belirt. Sadece doktorun okuyacağı bir rapor notu olarak hazırla. Selamlama veya kapanış yapma.
IMPORTANT: You MUST reply in the language specified by the ISO code: "$langCode". If it's "en", reply entirely in English. If it's "tr", reply entirely in Turkish.''';

      final userContent = langCode == 'en' 
          ? 'Please generate a comprehensive patient summary for the doctor report. Write approximately 5 to 7 sentences covering the patient condition, risks, and recommendations.' 
          : 'Lütfen doktor raporu için kapsamlı bir hasta özeti oluştur. Hastanın durumunu, riskleri ve önerileri kapsayan yaklaşık 5-7 cümle yaz.';

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      });

      int retries = 2;
      while (retries >= 0) {
        try {
          final response = await http.post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: body,
          ).timeout(const Duration(seconds: 30));

          debugPrint('[AiCoach] Doctor Summary status: ${response.statusCode}');
          debugPrint('[AiCoach] Doctor Summary body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['choices']?[0]?['message']?['content']?.toString().trim();
            if (text != null && text.isNotEmpty) {
              return text;
            }
          } else {
            return langCode == 'en'
                ? 'AI Error (${response.statusCode}): ${response.body.substring(0, response.body.length.clamp(0, 200))}'
                : 'Yapay zeka hatası (${response.statusCode}): ${response.body.substring(0, response.body.length.clamp(0, 200))}';
          }
        } catch (e) {
          debugPrint('[AiCoach] Doctor Summary attempt error: $e');
        }
        
        retries--;
        if (retries >= 0) await Future.delayed(const Duration(seconds: 1));
      }

      return langCode == 'en' 
          ? 'AI summary could not be generated. (Empty response)'
          : 'Yapay zeka ozeti olusturulamadi (Bos yanit).';
    } catch (e) {
      final bmi = HealthCalculator.bmi(profile);
      final bmiText = HealthCalculator.bmiLabel(bmi);
      return 'Yapay zeka sunucusuna baglanilamadi. Yerel Sistem Ozeti: Hastanin VKI degeri ${bmi.toStringAsFixed(1)} ($bmiText). Su hedefine ve uyku duzenine dikkat edilmesi saglikli yasam icin tavsiye edilir.';
    }
  }
}

