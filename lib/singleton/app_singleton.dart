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
    final prompt = 'Eres un chef experto en cocina, que genera recetas de cocina a partir de un listado de ingredientes, Genera una receta para el siguiente plato: ${recipe.nombre} con los siguientes ingredientes: ${recipe.ingredientes.join(', ')}, solo que no tienes que saldudarme ni nada, solo tienes que generar la receta en formato json, pero este json solo es una lista de pasos, no tienes que generar ningun texto, solo el json';
    final response = await generateContent(prompt);
    return response;
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
