import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();
  static const String _apiKeyPref = 'gemini_api_key';

  GenerativeModel? _model;
  String? _apiKey;
  Recipe? recipe;
  int numRecetas = 5;
  String personality = 'neutral';
  List<Recipe> recetasFavoritas = [];

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  GenerativeModel? get model => _model;
  String? get apiKey => _apiKey;

  Future<void> initializeWithStoredKey() async {
    String? storedKey;

    await SharedPreferences.getInstance().then((prefs) async{
      numRecetas = int.parse(prefs.getString('numRecetas') ?? '5');
      personality = prefs.getString('tonoTextos') ?? 'neutral';
      if(kIsWeb){
        storedKey = 'AIzaSyBO-abaWglQOnVQM4YdIEASxgOVNtadVPY';
      }else{
        storedKey = prefs.getString(_apiKeyPref);
      }
      if (storedKey != null) {
        await setApiKey(storedKey!);
      }
    });
  }

  Future<void> getFavRecipes(){
    return SharedPreferences.getInstance().then((prefs) {
      final List<String> favRecipes = prefs.getStringList('favRecipes') ?? [];
      recetasFavoritas = favRecipes.map((e) => Recipe.fromJson(json.decode(e))).toList();
    });
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
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
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
