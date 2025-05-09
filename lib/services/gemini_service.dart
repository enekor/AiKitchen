import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  Future<String> generateContent(String prompt, String apiKey) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
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
