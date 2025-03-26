import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/fav_recipes.json';
  }

  Future<void> getFavRecipes() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        String favRecipes = await file.readAsString();
        recetasFavoritas = Recipe.fromJsonList(favRecipes);
      } else {
        recetasFavoritas = [];
      }
    } catch (e) {
      print("Error reading favorite recipes: $e");
      recetasFavoritas = [];
    }
  }

  Future<void> setFavRecipes() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      String favRecipes = jsonEncode(recetasFavoritas);
      await file.writeAsString(favRecipes);
    } catch (e) {
      print("Error writing favorite recipes: $e");
    }
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
              children: [
                const Text(
                  'AI Kitchen',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
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
                TextField(
                  controller: newApiKey,
                  decoration: const InputDecoration(
                    labelText: 'API Key de Gemini',
                    hintText: 'Pega aquí tu API Key',
                    border: OutlineInputBorder(),
                  ),
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
      return await _geminiService!.generateContent(prompt, _apiKey!);
    }
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
