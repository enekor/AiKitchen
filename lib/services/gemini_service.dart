import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiService {
  Future<String> generateContent(String prompt, String apiKey) async {
    try {
      
      final _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
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
