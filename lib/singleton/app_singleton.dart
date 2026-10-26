import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/ai_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/warning_modal.dart';
import 'package:flutter/material.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();

  String? _groqApiKey;
  String? _openaiApiKey;
  String? _geminiApiKey;
  String? _anthropicApiKey;
  String? _selectedAiProvider;

  Recipe? recipe;
  int _numRecetas = 5;
  String _idioma = 'español';
  String _personality = 'neutral';
  String _selectedModel = 'llama-3.3-70b-versatile';
  List<Recipe> recetasFavoritas = [];
  
  AiService? _aiService;
  
  String _tipoReceta = 'omnivora';
  bool _useTTS = false;
  double _velocidadVoz = 1.0;
  double _creatividad = 0.1;
  bool _densidadCompacta = false;

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  String? get groqApiKey => _groqApiKey;
  String? get openaiApiKey => _openaiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  String? get anthropicApiKey => _anthropicApiKey;
  String? get selectedAiProvider => _selectedAiProvider;

  // For backwards compatibility where apiKey is checked
  String? get apiKey {
    final active = activeProvider;
    if (active == 'openai') return _openaiApiKey;
    if (active == 'gemini') return _geminiApiKey;
    if (active == 'anthropic') return _anthropicApiKey;
    return _groqApiKey;
  }

  int get numRecetas => _numRecetas;
  bool get useTTS => _useTTS;
  String get personality => _personality;
  String get idioma => _idioma;
  String get tipoReceta => _tipoReceta;
  String get selectedModel => _selectedModel;
  double get velocidadVoz => _velocidadVoz;
  double get creatividad => _creatividad;
  bool get densidadCompacta => _densidadCompacta;

  Map<String, String> get configuredApiKeys {
    final map = <String, String>{};
    if (_groqApiKey != null && _groqApiKey!.trim().isNotEmpty) map['groq'] = _groqApiKey!.trim();
    if (_openaiApiKey != null && _openaiApiKey!.trim().isNotEmpty) map['openai'] = _openaiApiKey!.trim();
    if (_geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty) map['gemini'] = _geminiApiKey!.trim();
    if (_anthropicApiKey != null && _anthropicApiKey!.trim().isNotEmpty) map['anthropic'] = _anthropicApiKey!.trim();
    return map;
  }

  String? get activeProvider {
    final configured = configuredApiKeys;
    if (configured.isEmpty) return null;
    if (_selectedAiProvider != null && configured.containsKey(_selectedAiProvider)) {
      return _selectedAiProvider;
    }
    if (configured.length == 1) {
      return configured.keys.first;
    }
    // If multiple configured but selected is invalid, pick the first configured one
    return configured.keys.first;
  }

  set setNumRecetas(int value) {
    _numRecetas = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.numRecetas, value.toString());
  }

  set setUseTTS(bool value) {
    _useTTS = value;
    SharedPreferencesService.setBoolValue(SharedPreferencesKeys.useTTS, value);
  }

  set setTipoReceta(String value) {
    _tipoReceta = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.tipoReceta, value);
  }

  set setIdioma(String value) {
    _idioma = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.idioma, value);
  }

  set setPersonality(String value) {
    _personality = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.tonoTextos, value);
  }

  set setSelectedModel(String value) {
    _selectedModel = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.selectedModel, value);
  }

  set setSelectedAiProvider(String value) {
    _selectedAiProvider = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.selectedAiProvider, value);
  }

  set setVelocidadVoz(double value) {
    _velocidadVoz = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.velocidadVoz, value.toString());
  }

  set setCreatividad(double value) {
    _creatividad = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.creatividad, value.toString());
  }

  set setDensidadCompacta(bool value) {
    _densidadCompacta = value;
    SharedPreferencesService.setBoolValue(SharedPreferencesKeys.densidadCompacta, value);
  }

  Future<void> initializeWithStoredKey() async {
    _numRecetas = int.parse(
      await SharedPreferencesService.getStringValue(SharedPreferencesKeys.numRecetas) ?? '5',
    );
    _personality = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.tonoTextos) ?? 'neutral';
    _idioma = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.idioma) ?? 'español';
    _tipoReceta = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.tipoReceta) ?? 'omnivora';
    _selectedModel = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.selectedModel) ?? 'llama-3.3-70b-versatile';
    _selectedAiProvider = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.selectedAiProvider);

    _groqApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.groqApiKey);
    _openaiApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.openaiApiKey);
    _geminiApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.geminiApiKey);
    _anthropicApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.anthropicApiKey);

    // Backward compatibility: if groqApiKey is empty but geminiApiKey has a key (which previously stored Groq key), migrate it to groqApiKey
    if ((_groqApiKey == null || _groqApiKey!.isEmpty) && (_geminiApiKey != null && _geminiApiKey!.isNotEmpty)) {
      // Check if it looks like a groq key (starts with gsk_)
      if (_geminiApiKey!.startsWith('gsk_')) {
        _groqApiKey = _geminiApiKey;
        await SharedPreferencesService.setStringValue(SharedPreferencesKeys.groqApiKey, _groqApiKey!);
        _geminiApiKey = null;
        await SharedPreferencesService.removeValue(SharedPreferencesKeys.geminiApiKey);
      }
    }

    _useTTS = await SharedPreferencesService.getBoolValue(SharedPreferencesKeys.useTTS);

    _velocidadVoz = double.tryParse(
          await SharedPreferencesService.getStringValue(SharedPreferencesKeys.velocidadVoz) ?? '',
        ) ?? 1.0;
    _creatividad = double.tryParse(
          await SharedPreferencesService.getStringValue(SharedPreferencesKeys.creatividad) ?? '',
        ) ?? 0.1;
    _densidadCompacta = await SharedPreferencesService.getBoolValue(SharedPreferencesKeys.densidadCompacta);

    _aiService = AiService();

    recetasFavoritas = await JsonDocumentsService().getFavRecipes();
  }

  Future<void> setGroqApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.groqApiKey, key);
    _groqApiKey = key;
  }

  Future<void> setOpenAiApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.openaiApiKey, key);
    _openaiApiKey = key;
  }

  Future<void> setGeminiApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.geminiApiKey, key);
    _geminiApiKey = key;
  }

  Future<void> setAnthropicApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.anthropicApiKey, key);
    _anthropicApiKey = key;
  }

  Future<void> setApiKey(String apiKey) async {
    // Default setter updating groq or active provider
    final provider = activeProvider ?? 'groq';
    if (provider == 'openai') {
      await setOpenAiApiKey(apiKey);
    } else if (provider == 'gemini') {
      await setGeminiApiKey(apiKey);
    } else if (provider == 'anthropic') {
      await setAnthropicApiKey(apiKey);
    } else {
      await setGroqApiKey(apiKey);
    }
  }

  Future<String> generateContent(
    String prompt,
    BuildContext context, {
    int? maxTokens = 4096,
  }) async {
    final provider = activeProvider;
    final configured = configuredApiKeys;

    if (provider == null || configured.isEmpty) {
      await WarningModal.ShowWarningDialog(
        title: 'API Key no configurada',
        texto:
            'Para poder utilizar las funciones de IA de la aplicación necesita configurar al menos una API Key de IA en la sección de ajustes.',
        context: context,
        okText: 'Vamos allá',
        onAccept: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/ajustes');
        },
      );

      throw NoApiKeyException();
    }

    final apiKey = configured[provider]!;
    return await _aiService!.generateContent(
      prompt,
      provider,
      apiKey,
      model: _selectedModel,
      maxTokens: maxTokens,
      temperature: _creatividad,
      context: context,
    );
  }

  Future<void> shareRecipe(Recipe recipe, BuildContext context) async {
    await ShareRecipeService().shareRecipe([recipe]);
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
