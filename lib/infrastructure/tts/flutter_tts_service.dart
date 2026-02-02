import 'package:flutter_tts/flutter_tts.dart';

class FlutterTtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set Turkish language
      await _tts.setLanguage('tr-TR');
      
      // Set speech rate (0.0 - 1.0, default 0.5)
      await _tts.setSpeechRate(0.5);
      
      // Set volume (0.0 - 1.0, default 1.0)
      await _tts.setVolume(1.0);
      
      // Set pitch (0.5 - 2.0, default 1.0)
      await _tts.setPitch(1.0);

      _isInitialized = true;
      print('✅ TTS initialized with Turkish language');
    } catch (e) {
      print('⚠️ TTS initialization failed: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _tts.speak(text);
      print('🔊 TTS: $text');
    } catch (e) {
      print('⚠️ TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('⚠️ TTS stop failed: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      print('⚠️ TTS setSpeechRate failed: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _tts.setVolume(volume);
    } catch (e) {
      print('⚠️ TTS setVolume failed: $e');
    }
  }

  void dispose() {
    _tts.stop();
  }
}
