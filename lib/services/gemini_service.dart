import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  Future<String> generateContent(
    String prompt,
    String apiKey, {
    BuildContext? context,
  }) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } on GenerativeAIException catch (e) {
      if (e.message.contains('503')) {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inténtalo de nuevo más tarde.')),
          );
        }
        return 'Error: El servicio de IA está sobrecargado. Inténtalo de nuevo más tarde.';
      }
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
