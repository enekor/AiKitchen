import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';
  GenerativeModel? _model;
  String? _apiKey;

  GeminiService(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    this._apiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<String> generateContent(String prompt, BuildContext context) async {
    if (_model == null && _apiKey != null && _apiKey != '') {
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
      if (_apiKey == null || _apiKey == '')
        return "No se ha establecido una api key";

      String apiKey = AppSingleton().apiKey ?? '';
      if (apiKey == '') return "No se ha establecido una api key";
      setApiKey(apiKey);
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } catch (e) {
      return 'Error: $e';
    }
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
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
