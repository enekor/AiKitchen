import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
      _geminiService = GeminiService(_apiKey ?? '');
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
    _geminiService!.setApiKey(_apiKey ?? '');
    _apiKey = apiKey;
  }

  Future<String> generateContent(String prompt) async {
    return await _geminiService!.generateContent(prompt);
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
