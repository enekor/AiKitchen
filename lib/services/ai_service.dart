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
  static String effectiveModel(String provider) {
    final p = provider.toLowerCase();
    if (p == 'gemini' && _geminiModel != null) return _geminiModel!;
    return providerModel[p] ?? providerModel['groq']!;
  }

  /// Modelos de Gemini de más barato a más caro (precio por millón de tokens
  /// de entrada / salida, noviembre de 2026). Todos con cuota gratuita.
  static const List<String> geminiPreference = [
    'gemini-2.5-flash-lite', // 0,10 $ / 0,40 $
    'gemini-3.1-flash-lite', // 0,25 $ / 1,50 $
    'gemini-3.5-flash-lite', // 0,30 $ / 2,50 $
    'gemini-3.6-flash', // 0,75 $ / 3,75 $
  ];

  /// Modelo de Gemini elegido tras consultar qué admite la clave del usuario.
  /// Qué modelos acepta cada clave depende de su proyecto: Google deja de
  /// ofrecer los antiguos a proyectos nuevos aunque sigan existiendo.
  static String? _geminiModel;

  /// Modelos que Gemini ya ha rechazado en esta sesión.
  static final Set<String> _geminiRejected = {};

  /// Elige, entre los modelos que [available] dice que admite la clave, el
  /// más barato que no haya sido rechazado. Si no hay ninguno conocido, se
  /// queda con el primer Flash-Lite y, si tampoco, con el primer Flash de
  /// texto. `null` si no hay nada utilizable.
  @visibleForTesting
  static String? pickGeminiModel(Iterable<String> available, {Set<String> rejected = const {}}) {
    final usable = available.where((m) => !rejected.contains(m)).toSet();
    for (final preferred in geminiPreference) {
      if (usable.contains(preferred)) return preferred;
    }
    bool isTextModel(String m) =>
        !RegExp(r'image|tts|audio|live|embedding|vision|robotics|computer|transcribe')
            .hasMatch(m);
    final sorted = usable.where(isTextModel).toList()..sort();
    final stable = sorted.where((m) => !m.contains('preview') && !m.contains('exp'));
    for (final pool in [stable, sorted]) {
      for (final family in ['flash-lite', 'flash']) {
        final match = pool.where((m) => m.contains(family));
        if (match.isNotEmpty) return match.first;
      }
    }
    return null;
  }

  /// Pregunta a Gemini qué modelos admite esta clave para generar texto.
  static Future<List<String>> _listGeminiModels(String apiKey) async {
    final models = <String>[];
    String? pageToken;
    do {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000'
        '${pageToken != null ? '&pageToken=$pageToken' : ''}',
      );
      final response = await http
          .get(url, headers: {'x-goog-api-key': apiKey})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) break;
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      for (final m in (data['models'] as List? ?? const [])) {
        if (m is! Map) continue;
        final methods = (m['supportedGenerationMethods'] as List?) ?? const [];
        if (!methods.contains('generateContent')) continue;
        final name = (m['name'] as String?)?.replaceFirst('models/', '');
        if (name != null) models.add(name);
      }
      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return models;
  }

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
    // Un intento más que en otros proveedores: puede gastarse uno en
    // descubrir que el modelo no está disponible para esta clave.
    const int maxAttempts = 4;
    String? lastError;
    var currentModel = _geminiModel ?? model;
    var discovered = false;
    // Los Gemini 3 razonan por defecto; se pide el mínimo para no gastar
    // tokens. Si el modelo no admite ese nivel, se repite sin él.
    String? thinkingLevel;
    void resetThinking() =>
        thinkingLevel = currentModel.startsWith('gemini-3') ? 'minimal' : null;
    resetThinking();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await logService.appendLog('INFO GeminiService: Intento ${attempt + 1} con modelo $currentModel (maxTokens: $maxTokens)...');
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent');

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
          // 2.5 Flash-Lite no razona por defecto, así que a ese no se le manda
          // configuración de razonamiento: pedirla la activaría.
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens ?? 8192,
            'responseMimeType': 'application/json',
            if (thinkingLevel != null) 'thinkingConfig': {'thinkingLevel': thinkingLevel},
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

        final lower = message.toLowerCase();
        if (lower.contains('api key not valid') ||
            lower.contains('api_key_invalid') ||
            response.statusCode == 401) {
          return 'Error: API Key de Gemini inválida. Por favor, revísala en Ajustes.';
        }

        if (response.statusCode == 400 &&
            thinkingLevel != null &&
            lower.contains('thinking')) {
          thinkingLevel = thinkingLevel == 'minimal' ? 'low' : null;
          continue;
        }

        // El modelo no existe o esta clave no puede usarlo: se pregunta a
        // Gemini cuáles admite y se cambia al más barato de ellos.
        final modelUnavailable = response.statusCode == 404 ||
            (response.statusCode == 400 && lower.contains('not found')) ||
            lower.contains('no longer available') ||
            lower.contains('not supported for generatecontent');
        if (modelUnavailable) {
          _geminiRejected.add(currentModel);
          if (!discovered) {
            discovered = true;
            final available = await _listGeminiModels(apiKey);
            await logService.appendLog('INFO GeminiService: modelos disponibles para esta clave: ${available.join(', ')}');
            final next = pickGeminiModel(available, rejected: _geminiRejected);
            if (next != null) {
              await logService.appendLog('INFO GeminiService: $currentModel no disponible, se usa $next.');
              _geminiModel = next;
              currentModel = next;
              resetThinking();
              continue;
            }
          }
          return 'Error: Gemini no permite usar el modelo $currentModel con esta '
              'clave y no se ha encontrado otro disponible. Mensaje de Google: $message';
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
