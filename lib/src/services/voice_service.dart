import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage("tr-TR");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
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
