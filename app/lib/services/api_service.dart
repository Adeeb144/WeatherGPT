import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // ---------------------------------------------------------
  // DEPLOYMENT INSTRUCTIONS:
  // Android emulator: 'http://10.0.2.2:8000'
  // Real device (local WiFi): 'http://<YOUR-PC-IP>:8000'
  // Production: 'https://your-render-url.onrender.com'
  //
  // Change this URL to your deployed backend BEFORE running:
  // `flutter build apk --release`
  // ---------------------------------------------------------
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<String> sendMessage(String text, List<Message> history, String language) async {
    final body = jsonEncode({
      'message': text,
      'language': language,
      'history': history
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList(),
    });
    
    final res = await http
        .post(Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));
        
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    
    return jsonDecode(utf8.decode(res.bodyBytes))['reply'] as String;
  }

  Future<Map<String, dynamic>> getAlerts(String location) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/alerts?location=$location'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {'error': 'Could not fetch alerts'};
  }

  Future<Map<String, dynamic>> getClimate(String location) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/climate?location=$location'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {'error': 'Could not fetch climate data'};
  }
}
