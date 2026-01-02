import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:aikitchen/services/groq_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/warning_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:properties/properties.dart';
import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();

  String? _apiKey;
  Recipe? recipe;
  int _numRecetas = 5;
  String _idioma = 'español';
  String _personality = 'neutral';
  List<Recipe> recetasFavoritas = [];
  
  GeminiService? _geminiService;
  GroqService? _groqService;
  
  String _tipoReceta = 'omnívora';
  bool _useTTS = false;

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

  set setNumRecetas(int value) => _numRecetas = value;
  set setUseTTS(bool setUseTTS) => _useTTS = setUseTTS;
  set setTipoReceta(String value) => _tipoReceta = value;
  set setIdioma(String value) => _idioma = value;
  set setPersonality(String value) => _personality = value;

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

    // Primero intentamos cargar la API Key del archivo de configuración (config.properties en assets)
    try {
      // Hay que cargarlos mediante rootBundle y luego usar Properties.fromString
      final propertiesContent = await rootBundle.loadString('config.properties');
      Properties p = Properties.fromString(propertiesContent);

      _apiKey = p.get('GROQ_API_KEY');

      if (_apiKey != null && (_apiKey!.isEmpty || _apiKey == 'tu_api_key_aqui')) {
        _apiKey = null;
      }
    } catch (e) {
      debugPrint('Error cargando config.properties: $e');
      _apiKey = null;
    }

    // Si no se encontró en config.properties, miramos en SharedPreferences (ajustes manuales)
    if (_apiKey == null) {
      _apiKey = await SharedPreferencesService.getStringValue(
        SharedPreferencesKeys.geminiApiKey,
      );
    }

    _useTTS = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.useTTS,
    );

    _geminiService = GeminiService();
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

  Future<void> _launchUrl(String url, BuildContext context) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<String> generateContent(String prompt, BuildContext context) async {
    if (_apiKey == null || _apiKey == "" || _apiKey!.isEmpty) {
      await WarningModal.ShowWarningDialog(
        title: 'Api key no configurada',
        texto:
            'Para poder utilizar las funciones de IA de la aplicación necesita aplicar una api key en la seccion de ajustes. No se preocupe, viene bien explicado como obtener una.',
        context: context,
        okText: 'Vamos allá',
        onAccept: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/api_key');
        },
      );

      throw NoApiKeyException();
    } else {
      return await _groqService!.generateContent(prompt, _apiKey!, context: context);
    }
  }

  Future<void> shareRecipe(Recipe recipe, BuildContext context) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/${recipe.nombre}.aikr');
        await file.writeAsString(jsonEncode(recipe.toJson()));
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Mira esta receta:');
      } else {
        await WarningModal.ShowWarningDialog(
          texto: 'No se pudo acceder al almacenamiento externo',
          context: context,
        );
      }
    } catch (e) {
      Toaster.showError('Error al guardar o compartir la receta: $e');
    }
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
