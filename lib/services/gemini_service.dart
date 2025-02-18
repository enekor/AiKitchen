import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';
  GenerativeModel? _model;
  
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String?> getStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<String> generateContent(String prompt) async {
    if (_model == null) {
      throw Exception('API key no configurada');
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } catch (e) {
      return 'Error: $e';
    }
  }
} 