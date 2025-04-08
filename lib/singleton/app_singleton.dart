import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();
  static const String _apiKeyPref = 'gemini_api_key';

  String? _apiKey;
  Recipe? recipe;
  int _numRecetas = 5;
  String _personality = 'neutral';
  List<Recipe> recetasFavoritas = [];
  GeminiService? _geminiService;

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  String? get apiKey => _apiKey;
  int get numRecetas => _numRecetas;
  set setNumRecetas(int value) => _numRecetas = value;
  String get personality => _personality;
  set setPersonality(String value) => _personality = value;

  Future<void> initializeWithStoredKey() async {
    await SharedPreferences.getInstance().then((prefs) async {
      _numRecetas = int.parse(prefs.getString('numRecetas') ?? '5');
      _personality = prefs.getString('tonoTextos') ?? 'neutral';
      _apiKey = prefs.getString(_apiKeyPref);
      _geminiService = GeminiService();
    });
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Para usar la aplicación, necesitas una API Key de Google AI Studio. Sigue estos pasos:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text('1. Ve a Google AI Studio'),
                const SizedBox(height: 8),
                const Text('2. Inicia sesión con tu cuenta de Google'),
                const SizedBox(height: 8),
                const Text('3. Ve a "Get API Key"'),
                const SizedBox(height: 8),
                const Text('4. Crea una nueva API Key o usa una existente'),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => _launchUrl(
                          'https://makersuite.google.com/app/apikey',
                          context,
                        ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ir a Google AI Studio'),
                  ),
                ),
                const SizedBox(height: 48),
                BasicTextInput(
                  onChanged: (apiKey) {
                    newApiKey.text = apiKey;
                  },
                  onSearch: (apiKey) {
                    AppSingleton().setApiKey(apiKey);
                    Toaster.showToast('API Key guardada');
                    Navigator.pop(context);
                  },

                  hint: 'Pega aquí tu API Key',
                  initialValue: AppSingleton().apiKey ?? '',
                  checkIcon: Icons.save_rounded,
                  padding: const EdgeInsets.all(2),
                  isInnerShadow: true,
                ),
              ],
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
