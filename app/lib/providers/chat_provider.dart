import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/voice_service.dart';

class ChatProvider extends ChangeNotifier {
  final _api = ApiService();
  final _loc = LocationService();
  final _voice = VoiceService();
  final List<Message> messages = [];
  bool loading = false;
  bool isListening = false;
  String language = 'auto'; // 'auto', 'English', 'Hindi', 'Telugu'
  List<dynamic> localAlerts = [];
  bool hasActiveWarning = false;

  ChatProvider() {
    _voice.init();
    checkLocalAlerts();
  }

  Future<void> checkLocalAlerts() async {
    final pos = await _loc.current();
    if (pos != null) {
      final res = await _api.getAlerts('${pos.latitude},${pos.longitude}');
      if (res['alerts'] != null) {
        localAlerts = res['alerts'];
        hasActiveWarning = localAlerts.any((a) => a['severity'] == 'red' || a['severity'] == 'orange');
        notifyListeners();
      }
    }
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (isListening) {
      await _voice.stopListening();
      isListening = false;
      notifyListeners();
    } else {
      isListening = true;
      notifyListeners();
      await _voice.listen(language, (words) async {
        isListening = false;
        notifyListeners();
        if (words.isNotEmpty) {
          await send(words, fromVoice: true);
        }
      });
    }
  }

  Future<void> playAudio(String text) async {
    await _voice.speak(text, language);
  }

  Future<String?> send(String text, {bool fromVoice = false}) async {
    if (text.trim().isEmpty) return null;
    
    String messageToSend = text;
    final lowerText = text.toLowerCase();
    if (lowerText.contains('near me') || lowerText.contains('my location')) {
      final pos = await _loc.current();
      if (pos != null) {
        messageToSend = '$text [User current coordinates: ${pos.latitude}, ${pos.longitude}]';
      }
    }
    
    final history = List<Message>.from(messages);
    messages.add(Message(text: text, isUser: true));
    loading = true;
    notifyListeners();
    try {
      final reply = await _api.sendMessage(messageToSend, history, language);
      messages.add(Message(text: reply, isUser: false));
      if (fromVoice) {
        await playAudio(reply);
      }
      return reply;
    } catch (e) {
      const err = 'Could not reach WeatherGPT. Check your connection and try again.';
      messages.add(Message(text: err, isUser: false));
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
