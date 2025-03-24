import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';
  GenerativeModel? _model;
  String? _apiKey;

  GeminiService(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<String> generateContent(String prompt) async {
    if (_model == null) {
      String apiKey = AppSingleton().apiKey ?? '';
      if (apiKey == '') return "No se ha establecido una api key";
      setApiKey(apiKey);
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

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
