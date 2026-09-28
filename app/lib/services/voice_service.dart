import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _ready = false;

  static const localeMap = {
    'English': 'en_IN', 'Hindi': 'hi_IN', 'Telugu': 'te_IN', 'auto': 'en_IN',
  };

  Future<bool> init() async => _ready = await _stt.initialize();

  Future<void> listen(String language, void Function(String) onResult) async {
    if (!_ready) await init();
    if (!_ready) return;
    await _stt.listen(
      localeId: localeMap[language] ?? 'en_IN',
      onResult: (r) { if (r.finalResult) onResult(r.recognizedWords); },
    );
  }

  Future<void> stopListening() => _stt.stop();

  Future<void> speak(String text, String language) async {
    await _tts.setLanguage(localeMap[language]?.replaceAll('_', '-') ?? 'en-IN');
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
