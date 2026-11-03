import 'dart:convert';
import 'dart:math';
import 'package:aikitchen/models/prompt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log_file_service.dart';

/// Llamadas a los proveedores de IA.
///
/// Cada proveedor usa siempre un único modelo: el más barato por token que
/// aguanta de sobra una respuesta con cinco recetas (unos 3.000-4.000 tokens
/// de salida). Precios de referencia por millón de tokens, noviembre de 2026:
///
/// | Proveedor | Modelo                | Entrada | Salida |
/// |-----------|-----------------------|---------|--------|
/// | Groq      | openai/gpt-oss-20b    | 0,075 $ | 0,30 $ |
/// | Gemini    | gemini-2.5-flash-lite | 0,10 $  | 0,40 $ |
/// | OpenAI    | gpt-6-luna            | 0,10 $  | 0,50 $ |
/// | Anthropic | claude-haiku-5-5      | 0,10 $  | 0,50 $ |
///
/// Gemini y Groq tienen cuota gratuita para estos modelos; OpenAI y
/// Anthropic no, así que allí se usa el más barato. La app no decide si se
/// paga: eso depende de la cuenta de cada clave. Lo que sí hace es preferir
/// los proveedores gratuitos y pasar de uno a otro cuando se agota la cuota
/// (ver `AppSingleton.generateContent`).
///
/// Los que razonan se configuran con el mínimo razonamiento, porque esos
/// tokens también se pagan y cuentan contra el tope de salida.
///
/// Todos los fallos se devuelven como texto que empieza por "Error"; quien
/// llama los distingue así de una respuesta.
class AiService {
  static const Map<String, String> providerModel = {
    'groq': 'openai/gpt-oss-20b',
    'openai': 'gpt-6-luna',
    'gemini': 'gemini-2.5-flash-lite',
    'anthropic': 'claude-haiku-5-5',
  };

  /// Proveedores con cuota gratuita para su modelo, en orden de preferencia.
  static const List<String> freeTierProviders = ['gemini', 'groq'];

  static bool hasFreeTier(String provider) =>
      freeTierProviders.contains(provider.toLowerCase());

  /// Texto con el que los servicios avisan de que se ha agotado la cuota
  /// (error 429). Quien llama lo busca para probar con otro proveedor.
  static const String quotaMarker = 'límite de uso';

  static String _quotaMessage(String providerName, String detail) =>
      'has alcanzado el $quotaMarker de $providerName (la cuota gratuita o la '
      'de tu plan). Espera un rato o revisa tu cuenta. Detalle: $detail';

  /// Se mantiene como lista por compatibilidad con Ajustes: un modelo por
  /// proveedor.
  static Map<String, List<String>> get providerModels =>
      providerModel.map((k, v) => MapEntry(k, [v]));

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

  /// Modelo con el que llamar a [provider]: siempre el fijado para él. Antes
  /// se usaba el modelo guardado en Ajustes aunque fuera de otro proveedor
  /// (con solo una clave de Gemini se quedaba el de Groq por defecto), la API
  /// lo rechazaba y la pantalla acababa leyendo como JSON un mensaje de error.
  static String effectiveModel(String provider) =>
      providerModel[provider.toLowerCase()] ?? providerModel['groq']!;

  /// Tope de tokens de salida. Todos los modelos admiten bastante más, pero
  /// sin streaming una respuesta muy larga arriesga a agotar el tiempo de
  /// espera, y cinco recetas caben con holgura.
  static int maxOutputTokens(String provider) =>
      // Groq limita los tokens por minuto de sus planes básicos (unos 8.000,
      // contando la petición). Con este tope caben cinco recetas y el prompt.
      provider.toLowerCase() == 'groq' ? 6144 : 16384;

  Future<String> generateContent(
    String prompt,
    String provider,
    String apiKey, {
    required String model,
    int? maxTokens = 8192,
    double temperature = 0.1,
    BuildContext? context,
  }) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _callOpenAiCompatible(
          'https://api.openai.com/v1/chat/completions',
          'OpenAI',
          prompt,
          apiKey,
          model: model,
          maxTokens: maxTokens,
          // GPT-6 Luna razona: "none" es el nivel más barato y basta aquí.
          // Como modelo de razonamiento no se le manda temperatura.
          extraParams: const {'reasoning_effort': 'none'},
        );
      case 'gemini':
        return _generateGemini(prompt, apiKey, model: model, maxTokens: maxTokens, temperature: temperature);
      case 'anthropic':
        return _generateAnthropic(prompt, apiKey, model: model, maxTokens: maxTokens);
      case 'groq':
      default:
        return _callOpenAiCompatible(
          'https://api.groq.com/openai/v1/chat/completions',
          'Groq',
          prompt,
          apiKey,
          model: model,
          maxTokens: maxTokens,
          extraParams: {
            'temperature': temperature,
            // gpt-oss razona; con poco esfuerzo gasta menos y responde antes,
            // y sin devolver el razonamiento no ensucia la respuesta.
            'reasoning_effort': 'low',
            'include_reasoning': false,
          },
        );
    }
  }

  /// Quita del cuerpo los parámetros opcionales que el proveedor diga no
  /// admitir en un error 400. Devuelve `true` si ha quitado alguno, para
  /// repetir la llamada sin ellos en vez de fallar.
  static bool _dropRejectedParams(
    Map<String, dynamic> body,
    String errorMessage,
    Iterable<String> optional,
  ) {
    final message = errorMessage.toLowerCase();
    var dropped = false;
    for (final key in optional) {
      if (body.containsKey(key) && message.contains(key.toLowerCase())) {
        body.remove(key);
        dropped = true;
      }
    }
    return dropped;
  }

  Future<String> _callOpenAiCompatible(
    String endpointUrl,
    String providerName,
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
    Map<String, dynamic> extraParams = const {},
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 4;
    String? lastError;

    final body = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': Prompt.systemPrompt},
        {'role': 'user', 'content': prompt}
      ],
      // Modo JSON: el modelo solo puede devolver un objeto JSON válido.
      'response_format': {'type': 'json_object'},
      // `max_tokens` está obsoleto y los modelos de razonamiento lo rechazan.
      'max_completion_tokens': maxTokens ?? 8192,
      ...extraParams,
    };
    final optional = ['response_format', ...extraParams.keys];

    try {
      final url = Uri.parse(endpointUrl);

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO ${providerName}Service: Intento ${attempt + 1} con modelo $model (maxTokens: ${body['max_completion_tokens']})...');

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 90));

          final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);

          if (response.statusCode == 200) {
            final data = jsonDecode(decodedBody) as Map<String, dynamic>;
            final choice = (data['choices'] as List).first as Map<String, dynamic>;
            final content = (choice['message']?['content'] as String?) ?? '';
            if (choice['finish_reason'] == 'length') {
              await logService.appendLog('WARNING ${providerName}Service: respuesta cortada por el tope de tokens.');
            }
            if (content.trim().isNotEmpty) return content.trim();
            lastError = '$providerName ha devuelto una respuesta vacía.';
            continue;
          }

          String errorMessage = 'Status ${response.statusCode}';
          try {
            errorMessage = (jsonDecode(decodedBody) as Map)['error']?['message'] ?? errorMessage;
          } catch (_) {}
          lastError = '$providerName respondió con un error: $errorMessage';
          await logService.appendLog('ERROR ${providerName}Service (Intento ${attempt + 1}): $errorMessage');

          if (response.statusCode == 401) {
            return 'Error: API Key de $providerName inválida. Por favor, revísala en Ajustes.';
          }
          if (response.statusCode == 404) {
            return 'Error: el modelo $model no está disponible en $providerName.';
          }
          if (response.statusCode == 400 &&
              _dropRejectedParams(body, errorMessage, optional)) {
            continue;
          }
          if (response.statusCode == 413) {
            body['max_completion_tokens'] = ((body['max_completion_tokens'] as int?) ?? 8192) ~/ 2;
            continue;
          }
          if (response.statusCode == 429) {
            lastError = _quotaMessage(providerName, errorMessage);
            final waitMs = pow(2, attempt) * 1000 + 500;
            await Future.delayed(Duration(milliseconds: waitMs.toInt()));
            continue;
          }
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          lastError = 'Error de conexión con $providerName: $e';
          await logService.appendLog('ERROR ${providerName}Service (Catch): $e');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return 'Error: ${lastError ?? 'no se pudo generar respuesta con $providerName tras varios intentos.'}';
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
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    String? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await logService.appendLog('INFO GeminiService: Intento ${attempt + 1} con modelo $model (maxTokens: $maxTokens)...');
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

        final body = {
          'systemInstruction': {
            'parts': [
              {'text': Prompt.systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          // 2.5 Flash-Lite no razona por defecto, así que todos los tokens
          // de salida son para la respuesta. No se le manda configuración de
          // razonamiento: pedirla la activaría.
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens ?? 8192,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            // En cabecera y no en la URL, para que no acabe en registros.
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 90));

        final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);

        if (response.statusCode == 200) {
          final data = jsonDecode(decoded) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            final reason = data['promptFeedback']?['blockReason'];
            lastError = reason != null
                ? 'Gemini ha bloqueado la petición ($reason).'
                : 'Gemini no ha devuelto ninguna respuesta.';
            await logService.appendLog('ERROR GeminiService: $lastError');
            continue;
          }

          final candidate = candidates.first as Map<String, dynamic>;
          final finishReason = candidate['finishReason'];
          // La respuesta puede venir en varias partes; las de razonamiento
          // llevan "thought": true y no forman parte de la respuesta.
          final parts = (candidate['content']?['parts'] as List?) ?? const [];
          final content = parts
              .whereType<Map>()
              .where((p) => p['thought'] != true && p['text'] is String)
              .map((p) => p['text'] as String)
              .join();

          if (finishReason == 'MAX_TOKENS') {
            await logService.appendLog('WARNING GeminiService: respuesta cortada por MAX_TOKENS.');
          }
          if (content.trim().isNotEmpty) return content.trim();

          lastError = 'Gemini ha devuelto una respuesta vacía ($finishReason).';
          await logService.appendLog('ERROR GeminiService: $lastError');
          continue;
        }

        String message = 'Status ${response.statusCode}';
        try {
          message = (jsonDecode(decoded) as Map)['error']?['message'] ?? message;
        } catch (_) {}
        await logService.appendLog('ERROR GeminiService (Intento ${attempt + 1}): $message');

        if (response.statusCode == 401 || response.statusCode == 403) {
          return 'Error: API Key de Gemini inválida. Por favor, revísala en Ajustes.';
        }
        if (response.statusCode == 404) {
          return 'Error: el modelo $model no está disponible en Gemini.';
        }
        lastError = response.statusCode == 429
            ? _quotaMessage('Gemini', message)
            : 'Gemini respondió con un error: $message';
        if (response.statusCode == 429) {
          await Future.delayed(Duration(milliseconds: (pow(2, attempt) * 1000 + 500).toInt()));
          continue;
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        lastError = 'Error de conexión con Gemini: $e';
        await logService.appendLog('ERROR GeminiService (Catch): $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return 'Error: ${lastError ?? 'no se pudo generar respuesta con Gemini tras varios intentos.'}';
  }

  /// Claude Haiku 5.5 razona por defecto y rechaza cualquier temperatura
  /// distinta de la suya, así que no se le manda y el razonamiento se deja en
  /// esfuerzo bajo. La respuesta puede empezar con bloques de razonamiento:
  /// solo se leen los de texto.
  Future<String> _generateAnthropic(
    String prompt,
    String apiKey, {
    required String model,
    int? maxTokens,
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    String? lastError;

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens ?? 8192,
      'system': Prompt.systemPrompt,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'output_config': {'effort': 'low'},
    };

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await logService.appendLog('INFO AnthropicService: Intento ${attempt + 1} con modelo $model...');
        final response = await http.post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 90));

        final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);

        if (response.statusCode == 200) {
          final data = jsonDecode(decoded) as Map<String, dynamic>;
          final stopReason = data['stop_reason'];
          if (stopReason == 'refusal') {
            return 'Error: Claude ha rechazado la petición.';
          }
          final blocks = (data['content'] as List?) ?? const [];
          final content = blocks
              .whereType<Map>()
              .where((b) => b['type'] == 'text' && b['text'] is String)
              .map((b) => b['text'] as String)
              .join();
          if (stopReason == 'max_tokens') {
            await logService.appendLog('WARNING AnthropicService: respuesta cortada por max_tokens.');
          }
          if (content.trim().isNotEmpty) return content.trim();
          lastError = 'Claude ha devuelto una respuesta vacía ($stopReason).';
          continue;
        }

        String message = 'Status ${response.statusCode}';
        try {
          message = (jsonDecode(decoded) as Map)['error']?['message'] ?? message;
        } catch (_) {}
        await logService.appendLog('ERROR AnthropicService (Intento ${attempt + 1}): $message');

        if (response.statusCode == 401 || response.statusCode == 403) {
          return 'Error: API Key de Anthropic inválida. Por favor, revísala en Ajustes.';
        }
        if (response.statusCode == 404) {
          return 'Error: el modelo $model no está disponible en Anthropic.';
        }
        final lower = message.toLowerCase();
        if (response.statusCode == 400 &&
            body.containsKey('output_config') &&
            (lower.contains('output_config') || lower.contains('effort'))) {
          body.remove('output_config');
          continue;
        }
        lastError = response.statusCode == 429
            ? _quotaMessage('Anthropic', message)
            : 'Anthropic respondió con un error: $message';
        if (response.statusCode == 429 || response.statusCode == 529) {
          await Future.delayed(Duration(milliseconds: (pow(2, attempt) * 1000 + 500).toInt()));
          continue;
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        lastError = 'Error de conexión con Anthropic: $e';
        await logService.appendLog('ERROR AnthropicService (Catch): $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return 'Error: ${lastError ?? 'no se pudo generar respuesta con Anthropic tras varios intentos.'}';
  }
}
