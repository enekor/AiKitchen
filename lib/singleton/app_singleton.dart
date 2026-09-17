import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/groq_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/warning_modal.dart';
import 'package:flutter/material.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();

  String? _apiKey;
  Recipe? recipe;
  int _numRecetas = 5;
  String _idioma = 'español';
  String _personality = 'neutral';
  String _selectedModel = 'llama-3.3-70b-versatile';
  List<Recipe> recetasFavoritas = [];
  
  GroqService? _groqService;
  
  // Debe coincidir con el nombre de la constante del enum, sin acento, porque
  // ese es el valor que se guarda y se vuelve a leer.
  String _tipoReceta = 'omnivora';
  bool _useTTS = false;
  double _velocidadVoz = 1.0;
  double _creatividad = 0.1;
  bool _densidadCompacta = false;

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  String? get apiKey => _apiKey;
  int get numRecetas => _numRecetas;
  bool get useTTS => _useTTS;
  String get personality => _personality;
  String get idioma => _idioma;
  String get tipoReceta => _tipoReceta;
  String get selectedModel => _selectedModel;
  double get velocidadVoz => _velocidadVoz;
  double get creatividad => _creatividad;
  bool get densidadCompacta => _densidadCompacta;

  set setNumRecetas(int value) {
    _numRecetas = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.numRecetas,
      value.toString(),
    );
  }

  set setUseTTS(bool value) {
    _useTTS = value;
    SharedPreferencesService.setBoolValue(
      SharedPreferencesKeys.useTTS,
      value,
    );
  }

  set setTipoReceta(String value) {
    _tipoReceta = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.tipoReceta,
      value,
    );
  }

  set setIdioma(String value) {
    _idioma = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.idioma,
      value,
    );
  }

  set setPersonality(String value) {
    _personality = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.tonoTextos,
      value,
    );
  }

  set setSelectedModel(String value) {
    _selectedModel = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.selectedModel,
      value,
    );
  }

  set setVelocidadVoz(double value) {
    _velocidadVoz = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.velocidadVoz,
      value.toString(),
    );
  }

  set setCreatividad(double value) {
    _creatividad = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.creatividad,
      value.toString(),
    );
  }

  set setDensidadCompacta(bool value) {
    _densidadCompacta = value;
    SharedPreferencesService.setBoolValue(
      SharedPreferencesKeys.densidadCompacta,
      value,
    );
  }

  Future<void> initializeWithStoredKey() async {
    _numRecetas = int.parse(
      await SharedPreferencesService.getStringValue(
            SharedPreferencesKeys.numRecetas,
          ) ??
          '5',
    );
    _personality =
        await SharedPreferencesService.getStringValue(
          SharedPreferencesKeys.tonoTextos,
        ) ??
        'neutral';
    _idioma =
        await SharedPreferencesService.getStringValue(
          SharedPreferencesKeys.idioma,
        ) ??
        'español';
    _tipoReceta =
        await SharedPreferencesService.getStringValue(
          SharedPreferencesKeys.tipoReceta,
        ) ??
        'omnivora';
    _selectedModel =
        await SharedPreferencesService.getStringValue(
          SharedPreferencesKeys.selectedModel,
        ) ??
        'llama-3.3-70b-versatile';

    // La clave la introduce el usuario en Ajustes y se guarda solo en su
    // dispositivo. Antes se leía también de un fichero de recursos, pero en
    // web ese fichero queda descargable por cualquiera.
    _apiKey = await SharedPreferencesService.getStringValue(
      SharedPreferencesKeys.geminiApiKey,
    );

    _useTTS = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.useTTS,
    );

    _velocidadVoz = double.tryParse(
          await SharedPreferencesService.getStringValue(
                SharedPreferencesKeys.velocidadVoz,
              ) ??
              '',
        ) ??
        1.0;
    _creatividad = double.tryParse(
          await SharedPreferencesService.getStringValue(
                SharedPreferencesKeys.creatividad,
              ) ??
              '',
        ) ??
        0.1;
    _densidadCompacta = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.densidadCompacta,
    );

    _groqService = GroqService();

    recetasFavoritas = await JsonDocumentsService().getFavRecipes();
  }

  Future<void> setApiKey(String apiKey) async {
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.geminiApiKey,
      apiKey,
    );
    _apiKey = apiKey;
  }

  Future<String> generateContent(
    String prompt,
    BuildContext context, {
    int? maxTokens = 4096,
  }) async {
    if (_apiKey == null || _apiKey == "" || _apiKey!.isEmpty) {
      await WarningModal.ShowWarningDialog(
        title: 'Api key no configurada',
        texto:
            'Para poder utilizar las funciones de IA de la aplicación necesita aplicar una api key en la seccion de ajustes.',
        context: context,
        okText: 'Vamos allá',
        onAccept: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/api_key');
        },
      );

      throw NoApiKeyException();
    } else {
      return await _groqService!.generateContent(
        prompt,
        _apiKey!,
        model: _selectedModel,
        maxTokens: maxTokens,
        temperature: _creatividad,
        context: context,
      );
    }
  }

  Future<void> shareRecipe(Recipe recipe, BuildContext context) async {
    await ShareRecipeService().shareRecipe([recipe]);
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
