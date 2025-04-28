import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/api_key_generator.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _tipoReceta = 'omnívora';

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  String? get apiKey => _apiKey;
  int get numRecetas => _numRecetas;
  set setNumRecetas(int value) => _numRecetas = value;
  String get personality => _personality;
  String get idioma => _idioma;
  String get tipoReceta => _tipoReceta;

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
    _apiKey = await SharedPreferencesService.getStringValue(
      SharedPreferencesKeys.geminiApiKey,
    );

    _geminiService = GeminiService();
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
      TextEditingController newApiKey = TextEditingController();
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Configurar API Key'),
            content: ApiKeyGenerator(
              onChange: (String value) {
                newApiKey.text = value;
              },
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Confirmar'),
                onPressed: () async {
                  if (newApiKey.text.isNotEmpty) {
                    await setApiKey(newApiKey.text);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
      throw NoApiKeyException();
    } else {
      return await _geminiService!.generateContent(
        prompt,
        /*_apiKey!*/ 'AIzaSyBuQtTiEEyB6MrJPrdV4PqG-STYj4_PIzM',
      );
    }
  }

  Future<void> shareRecipe(Recipe recipe) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/${recipe.nombre}.aikr');
        await file.writeAsString(jsonEncode(recipe.toJson()));
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Mira esta receta:');
      } else {
        Toaster.showToast('No se pudo acceder al almacenamiento externo');
      }
    } catch (e) {
      Toaster.showToast('Error al guardar o compartir la receta: $e');
    }
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
