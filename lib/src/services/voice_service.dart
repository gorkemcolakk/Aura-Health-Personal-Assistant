import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage("tr-TR");
      await _tts.setSpeechRate(0.70); // Daha da hızlandırıldı
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.5); // Sesi çok daha kalın yaptık

      // Cihazdaki (Özellikle Google TTS) mevcut erkek Türkçe sesini bulmaya çalış
      try {
        final voices = await _tts.getVoices;
        if (voices != null) {
          for (var v in voices) {
            // Android Google TTS'te 'cfs' veya 'network' içerenler genelde erkek sesleridir
            if (v["locale"] == "tr-TR" && v["name"].toString().contains("cfs")) {
              await _tts.setVoice({"name": v["name"], "locale": v["locale"]});
              break;
            }
          }
        }
      } catch (e) {
        debugPrint("Error setting specific male voice: $e");
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (text.isEmpty) return;
    
    // Remove markdown formatting like **, *, # for cleaner speech
    final cleanText = text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'#'), '')
        .replaceAll(RegExp(r'`'), '');

    try {
      await _tts.speak(cleanText);
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint("TTS Stop Error: $e");
    }
  }
}
