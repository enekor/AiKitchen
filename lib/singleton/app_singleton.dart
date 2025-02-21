import 'package:aikitchen/models/recipe.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();
  static const String _apiKeyPref = 'gemini_api_key';
  
  GenerativeModel? _model;
  String? _apiKey;
  Recipe? recipe;

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  GenerativeModel? get model => _model;
  String? get apiKey => _apiKey;

  Future<void> initializeWithStoredKey() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_apiKeyPref);
    if (storedKey != null) {
      await setApiKey(storedKey);
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _apiKey = apiKey;
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
      throw NoApiKeyException();
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> generateRecipe(Recipe recipe) async {
    final prompt = 'Eres un chef de fama mundial, y necesito que me des en formato de json en una lista de strings los pasos a seguir para hacer la receta ${recipe.nombre} con estos ingredientes: ${recipe.ingredientes.join(',')}, pero los pasos tienen que estar muy bien explicados para alguien que no sabe cocinar, no necesito que me saludes ni que me hables, solo el json y nada mas que el json ';
    final response = await generateContent(prompt);
    return response;
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
