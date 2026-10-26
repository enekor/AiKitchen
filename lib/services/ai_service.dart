import 'dart:convert';
import 'dart:math';
import 'package:aikitchen/models/prompt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log_file_service.dart';

class AiService {
  static const Map<String, List<String>> providerModels = {
    'groq': ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
    'openai': ['gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo'],
    'gemini': ['gemini-1.5-flash', 'gemini-1.5-pro'],
    'anthropic': ['claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'],
  };

  static const Map<String, String> providerDisplayNames = {
    'groq': 'Groq',
    'openai': 'OpenAI',
    'gemini': 'Google Gemini',
    'anthropic': 'Anthropic Claude',
  };

  static const Map<String, String> providerTutorialUrls = {
    'groq': 'https://console.groq.com/keys',
    'openai': 'https://platform.openai.com/api-keys',
    'gemini': 'https://aistudio.google.com/app/apikey',
    'anthropic': 'https://console.anthropic.com/settings/keys',
  };

  static const Map<String, List<String>> providerTutorialSteps = {
    'groq': [
      'Entra en Groq Console (console.groq.com).',
      'Inicia sesión o crea una cuenta gratuita.',
      'Dirígete a la sección "API Keys" en el menú lateral.',
      'Haz clic en "Create API Key", cópiala y pégala aquí.'
    ],
    'openai': [
      'Entra en OpenAI Platform (platform.openai.com).',
      'Inicia sesión o crea una cuenta.',
      'Ve a la sección "API keys" en tu perfil de usuario.',
      'Haz clic en "Create new secret key", cópiala y pégala aquí.'
    ],
    'gemini': [
      'Entra en Google AI Studio (aistudio.google.com).',
      'Inicia sesión con tu cuenta de Google.',
      'Haz clic en el botón superior "Get API key".',
      'Crea una clave en tu proyecto y pégala aquí.'
    ],
    'anthropic': [
      'Entra en Anthropic Console (console.anthropic.com).',
      'Inicia sesión o regístrate.',
      'Ve a la sección "API Keys" en la configuración.',
      'Haz clic en "Create Key", cópiala y pégala aquí.'
    ],
  };

  Future<String> generateContent(
    String prompt,
    String provider,
    String apiKey, {
    required String model,
    int? maxTokens = 4096,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _generateOpenAI(prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context);
      case 'gemini':
        return _generateGemini(prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context);
      case 'anthropic':
        return _generateAnthropic(prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context);
      case 'groq':
      default:
        return _generateGroq(prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context);
    }
  }

  Future<String> _generateOpenAI(
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const url = 'https://api.openai.com/v1/chat/completions';
    return _callOpenAiCompatible(url, 'OpenAI', prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context, logService: logService);
  }

  Future<String> _generateGroq(
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const url = 'https://api.groq.com/openai/v1/chat/completions';
    return _callOpenAiCompatible(url, 'Groq', prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature, context: context, logService: logService);
  }

  Future<String> _callOpenAiCompatible(
    String endpointUrl,
    String providerName,
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    double temperature = 0.1,
    BuildContext? context,
    required LogFileService logService,
  }) async {
    const int maxAttempts = 3;
    List<String> attemptErrors = [];
    int? currentMaxTokens = maxTokens;

    try {
      final url = Uri.parse(endpointUrl);

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO ${providerName}Service: Intento ${attempt + 1} con modelo $model (maxTokens: $currentMaxTokens)...');

          final body = {
            'model': model,
            'messages': [
              {'role': 'system', 'content': Prompt.systemPrompt},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': temperature,
          };

          final officialModels = ['llama', 'mixtral', 'gemma', 'gpt', 'o1', 'o3'];
          if (officialModels.any((m) => model.toLowerCase().contains(m)) && !model.toLowerCase().contains('gpt-3.5-turbo')) {
            // Some models support json_object
            if (providerName == 'Groq' || model.contains('gpt-4')) {
              body['response_format'] = {'type': 'json_object'};
            }
          }

          if (currentMaxTokens != null) {
            body['max_tokens'] = currentMaxTokens;
          }

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 60));

          if (response.statusCode == 200) {
            final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
            Map<String, dynamic> data;
            try {
              data = jsonDecode(decodedBody);
            } catch (e) {
              final errorMsg = 'Error JSON (${providerName} Intento ${attempt + 1})';
              attemptErrors.add(errorMsg);
              await logService.appendLog('ERROR ${providerName}Service: $errorMsg');

              if (decodedBody.contains('"recetas"') || decodedBody.contains('"nombre"')) {
                 try {
                   int start = decodedBody.indexOf('{');
                   int end = decodedBody.lastIndexOf('}');
                   if (start != -1 && end > start) {
                     String candidate = decodedBody.substring(start, end + 1);
                     data = jsonDecode(candidate);
                   } else {
                     continue;
                   }
                 } catch (_) {
                   continue;
                 }
              } else {
                continue;
              }
            }

            String content = data['choices'][0]['message']['content'] as String;

            if (content.isNotEmpty) {
              content = content.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
              content = content.replaceAll(RegExp(r'```json\s*'), '');
              content = content.replaceAll(RegExp(r'```\s*'), '');
              content = content.trim();
              return content;
            }
          } else {
            String errorMessage = 'Status ${response.statusCode}';
            try {
              final errorData = jsonDecode(response.body);
              errorMessage = errorData['error']?['message'] ?? errorMessage;
            } catch (_) {}

            final errorMsg = 'Error $providerName (Intento ${attempt + 1}): $errorMessage';
            attemptErrors.add(errorMsg);
            await logService.appendLog('ERROR ${providerName}Service: $errorMsg');

            if (response.statusCode == 401) {
              return 'Error: API Key de $providerName inválida. Por favor, revísala en Ajustes.';
            }

            if (response.statusCode == 413) {
              currentMaxTokens = (currentMaxTokens ?? 4000) ~/ 2;
              continue;
            }

            if (response.statusCode == 429) {
              final waitMs = pow(2, attempt) * 1000 + 500;
              await Future.delayed(Duration(milliseconds: waitMs.toInt()));
              continue;
            }
            
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        } catch (e) {
          attemptErrors.add('Error en intento ${attempt + 1}: $e');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return 'No se pudo generar respuesta con $providerName tras varios intentos.';
    } catch (e) {
      return 'Error crítico en $providerName: $e';
    }
  }

  Future<String> _generateGemini(
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await logService.appendLog('INFO GeminiService: Intento ${attempt + 1} con modelo $model...');
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

        final body = {
          'contents': [
            {
              'parts': [
                {'text': '${Prompt.systemPrompt}\n\nInstrucción de usuario:\n$prompt'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens ?? 4096,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
          final data = jsonDecode(decoded);
          final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
          if (content.isNotEmpty) {
            String cleaned = content.replaceAll(RegExp(r'```json\s*'), '');
            cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '').trim();
            return cleaned;
          }
        } else {
          if (response.statusCode == 401 || response.statusCode == 403) {
            return 'Error: API Key de Gemini inválida. Por favor, revísala en Ajustes.';
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        attemptErrors.add('Gemini intento $attempt: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return 'No se pudo generar respuesta con Gemini tras varios intentos.';
  }

  Future<String> _generateAnthropic(
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await logService.appendLog('INFO AnthropicService: Intento ${attempt + 1} con modelo $model...');
        final url = Uri.parse('https://api.anthropic.com/v1/messages');

        final body = {
          'model': model,
          'max_tokens': maxTokens ?? 4096,
          'system': Prompt.systemPrompt,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
        };

        final response = await http.post(
          url,
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
          final data = jsonDecode(decoded);
          final content = data['content'][0]['text'] as String;
          if (content.isNotEmpty) {
            String cleaned = content.replaceAll(RegExp(r'```json\s*'), '');
            cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '').trim();
            return cleaned;
          }
        } else {
          if (response.statusCode == 401 || response.statusCode == 403) {
            return 'Error: API Key de Anthropic inválida. Por favor, revísala en Ajustes.';
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        attemptErrors.add('Anthropic intento $attempt: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return 'No se pudo generar respuesta con Anthropic tras varios intentos.';
  }
}
