import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/tipo_receta.dart';
import 'package:aikitchen/services/ai_json.dart';
import 'package:aikitchen/services/ai_service.dart';
import 'package:aikitchen/services/log_file_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/warning_modal.dart';
import 'package:flutter/material.dart';

class AppSingleton {
  static final AppSingleton _instance = AppSingleton._internal();

  String? _groqApiKey;
  String? _openaiApiKey;
  String? _geminiApiKey;
  String? _anthropicApiKey;
  String? _selectedAiProvider;

  Recipe? recipe;
  int _numRecetas = 5;
  String _idioma = 'español';
  String _personality = 'neutral';
  String _selectedModel = 'llama-3.3-70b-versatile';
  List<Recipe> recetasFavoritas = [];
  
  AiService? _aiService;
  
  String _tipoReceta = 'omnivora';
  bool _useTTS = false;
  double _velocidadVoz = 1.0;
  double _creatividad = 0.1;
  bool _densidadCompacta = false;

  factory AppSingleton() {
    return _instance;
  }

  AppSingleton._internal();

  String? get groqApiKey => _groqApiKey;
  String? get openaiApiKey => _openaiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  String? get anthropicApiKey => _anthropicApiKey;
  String? get selectedAiProvider => _selectedAiProvider;

  // For backwards compatibility where apiKey is checked
  String? get apiKey {
    final active = activeProvider;
    if (active == 'openai') return _openaiApiKey;
    if (active == 'gemini') return _geminiApiKey;
    if (active == 'anthropic') return _anthropicApiKey;
    return _groqApiKey;
  }

  int get numRecetas => _numRecetas;
  bool get useTTS => _useTTS;
  String get personality => _personality;
  String get idioma => _idioma;
  /// Dieta y restricciones en texto legible, para los prompts.
  String get tipoReceta => TipoReceta.promptText(_tipoReceta);

  /// Dieta y restricciones elegidas, siempre con una dieta en primer lugar.
  List<TipoReceta> get preferenciasCocina => TipoReceta.parseList(_tipoReceta);

  /// Avisa a las barras de preferencias de toda la app cuando cambian, para
  /// que lo elegido en una pantalla se vea al momento en las demás.
  final ValueNotifier<int> preferenciasCambiadas = ValueNotifier(0);
  String get selectedModel => _selectedModel;
  double get velocidadVoz => _velocidadVoz;
  double get creatividad => _creatividad;
  bool get densidadCompacta => _densidadCompacta;

  /// Cada cuántos días se descarga de nuevo el recetario en segundo plano.
  final ValueNotifier<int> recetarioDias = ValueNotifier(7);

  set setRecetarioDias(int value) {
    recetarioDias.value = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.recetarioDias,
      value.toString(),
    );
  }

  /// Qué pantalla de inicio se usa: la nueva (por defecto) o la clásica. Es
  /// un notificador para que Inicio cambie en cuanto se toca en Ajustes.
  final ValueNotifier<bool> inicioModerno = ValueNotifier(true);

  set setInicioModerno(bool value) {
    inicioModerno.value = value;
    SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.inicioModerno,
      value.toString(),
    );
  }

  Map<String, String> get configuredApiKeys {
    final map = <String, String>{};
    if (_groqApiKey != null && _groqApiKey!.trim().isNotEmpty) map['groq'] = _groqApiKey!.trim();
    if (_openaiApiKey != null && _openaiApiKey!.trim().isNotEmpty) map['openai'] = _openaiApiKey!.trim();
    if (_geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty) map['gemini'] = _geminiApiKey!.trim();
    if (_anthropicApiKey != null && _anthropicApiKey!.trim().isNotEmpty) map['anthropic'] = _anthropicApiKey!.trim();
    return map;
  }

  String? get activeProvider {
    final configured = configuredApiKeys;
    if (configured.isEmpty) return null;
    if (_selectedAiProvider != null && configured.containsKey(_selectedAiProvider)) {
      return _selectedAiProvider;
    }
    if (configured.length == 1) {
      return configured.keys.first;
    }
    // Con varias claves y ninguna elegida, primero las de cuota gratuita.
    for (final free in AiService.freeTierProviders) {
      if (configured.containsKey(free)) return free;
    }
    return configured.keys.first;
  }

  set setNumRecetas(int value) {
    _numRecetas = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.numRecetas, value.toString());
  }

  set setUseTTS(bool value) {
    _useTTS = value;
    SharedPreferencesService.setBoolValue(SharedPreferencesKeys.useTTS, value);
  }

  set setPreferenciasCocina(List<TipoReceta> value) {
    _tipoReceta = TipoReceta.toStored(value);
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.tipoReceta, _tipoReceta);
    preferenciasCambiadas.value++;
  }

  set setIdioma(String value) {
    _idioma = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.idioma, value);
  }

  set setPersonality(String value) {
    _personality = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.tonoTextos, value);
  }

  set setSelectedModel(String value) {
    _selectedModel = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.selectedModel, value);
  }

  set setSelectedAiProvider(String value) {
    _selectedAiProvider = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.selectedAiProvider, value);
  }

  set setVelocidadVoz(double value) {
    _velocidadVoz = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.velocidadVoz, value.toString());
  }

  set setCreatividad(double value) {
    _creatividad = value;
    SharedPreferencesService.setStringValue(SharedPreferencesKeys.creatividad, value.toString());
  }

  set setDensidadCompacta(bool value) {
    _densidadCompacta = value;
    SharedPreferencesService.setBoolValue(SharedPreferencesKeys.densidadCompacta, value);
  }

  Future<void> initializeWithStoredKey() async {
    _numRecetas = int.parse(
      await SharedPreferencesService.getStringValue(SharedPreferencesKeys.numRecetas) ?? '5',
    );
    _personality = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.tonoTextos) ?? 'neutral';
    _idioma = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.idioma) ?? 'español';
    _tipoReceta = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.tipoReceta) ?? 'omnivora';
    _selectedModel = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.selectedModel) ?? 'llama-3.3-70b-versatile';
    _selectedAiProvider = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.selectedAiProvider);

    _groqApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.groqApiKey);
    _openaiApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.openaiApiKey);
    _geminiApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.geminiApiKey);
    _anthropicApiKey = await SharedPreferencesService.getStringValue(SharedPreferencesKeys.anthropicApiKey);

    // Backward compatibility: if groqApiKey is empty but geminiApiKey has a key (which previously stored Groq key), migrate it to groqApiKey
    if ((_groqApiKey == null || _groqApiKey!.isEmpty) && (_geminiApiKey != null && _geminiApiKey!.isNotEmpty)) {
      // Check if it looks like a groq key (starts with gsk_)
      if (_geminiApiKey!.startsWith('gsk_')) {
        _groqApiKey = _geminiApiKey;
        await SharedPreferencesService.setStringValue(SharedPreferencesKeys.groqApiKey, _groqApiKey!);
        _geminiApiKey = null;
        await SharedPreferencesService.removeValue(SharedPreferencesKeys.geminiApiKey);
      }
    }

    _useTTS = await SharedPreferencesService.getBoolValue(SharedPreferencesKeys.useTTS);

    _velocidadVoz = double.tryParse(
          await SharedPreferencesService.getStringValue(SharedPreferencesKeys.velocidadVoz) ?? '',
        ) ?? 1.0;
    _creatividad = double.tryParse(
          await SharedPreferencesService.getStringValue(SharedPreferencesKeys.creatividad) ?? '',
        ) ?? 0.1;
    _densidadCompacta = await SharedPreferencesService.getBoolValue(SharedPreferencesKeys.densidadCompacta);
    // Se guarda como texto para distinguir "nunca elegido" (nueva pantalla)
    // de "desactivado a propósito".
    inicioModerno.value = await SharedPreferencesService.getStringValue(
          SharedPreferencesKeys.inicioModerno,
        ) !=
        'false';
    recetarioDias.value = int.tryParse(
          await SharedPreferencesService.getStringValue(
                SharedPreferencesKeys.recetarioDias,
              ) ??
              '',
        ) ??
        7;

    _aiService = AiService();

    recetasFavoritas = await JsonDocumentsService().getFavRecipes();
  }

  Future<void> setGroqApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.groqApiKey, key);
    _groqApiKey = key;
  }

  Future<void> setOpenAiApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.openaiApiKey, key);
    _openaiApiKey = key;
  }

  Future<void> setGeminiApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.geminiApiKey, key);
    _geminiApiKey = key;
  }

  Future<void> setAnthropicApiKey(String key) async {
    await SharedPreferencesService.setStringValue(SharedPreferencesKeys.anthropicApiKey, key);
    _anthropicApiKey = key;
  }

  Future<void> setApiKey(String apiKey) async {
    // Default setter updating groq or active provider
    final provider = activeProvider ?? 'groq';
    if (provider == 'openai') {
      await setOpenAiApiKey(apiKey);
    } else if (provider == 'gemini') {
      await setGeminiApiKey(apiKey);
    } else if (provider == 'anthropic') {
      await setAnthropicApiKey(apiKey);
    } else {
      await setGroqApiKey(apiKey);
    }
  }

  /// Pide algo a la IA y devuelve siempre JSON limpio: un único objeto o
  /// lista, sin texto alrededor, sin bloques de código y sin repeticiones.
  ///
  /// Si la respuesta llega cortada se repite con el doble de tokens de
  /// salida, y si llega mal formada se repite una vez más. Si aun así no hay
  /// JSON válido, o el proveedor devuelve un error, lanza [AiResponseException]
  /// con un mensaje para el usuario, en vez de devolver texto que la pantalla
  /// intentaría leer como JSON.
  Future<String> generateContent(
    String prompt,
    BuildContext context, {
    int? maxTokens,
  }) async {
    final provider = activeProvider;
    final configured = configuredApiKeys;

    if (provider == null || configured.isEmpty) {
      await WarningModal.ShowWarningDialog(
        title: 'API Key no configurada',
        texto:
            'Para poder utilizar las funciones de IA de la aplicación necesita configurar al menos una API Key de IA en la sección de ajustes.',
        context: context,
        okText: 'Vamos allá',
        onAccept: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/ajustes');
        },
      );

      throw NoApiKeyException();
    }

    // Primero el proveedor activo; si agota su cuota, los demás que tengan
    // cuota gratuita y clave configurada. Nunca se salta por cuenta propia a
    // uno de pago: gastar dinero lo decide el usuario.
    final order = [
      provider,
      for (final free in AiService.freeTierProviders)
        if (free != provider && configured.containsKey(free)) free,
    ];

    for (var i = 0; i < order.length; i++) {
      try {
        return await _generateWith(
          order[i],
          configured[order[i]]!,
          prompt,
          context,
          maxTokens,
        );
      } on _QuotaExceeded catch (e) {
        final next = i + 1 < order.length ? order[i + 1] : null;
        if (next == null) throw AiResponseException(e.message);
        Toaster.showToast(
          'Cuota de ${AiService.providerDisplayNames[order[i]]} agotada. '
          'Probando con ${AiService.providerDisplayNames[next]}...',
        );
      }
    }
    throw AiResponseException('La IA no ha devuelto una respuesta válida.');
  }

  Future<String> _generateWith(
    String provider,
    String apiKey,
    String prompt,
    BuildContext context,
    int? maxTokens,
  ) async {
    final model = AiService.effectiveModel(provider);
    final cap = AiService.maxOutputTokens(provider);
    var tokens = (maxTokens ?? 8192).clamp(1024, cap);
    final log = LogFileService();

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final raw = await _aiService!.generateContent(
        prompt,
        provider,
        apiKey,
        model: model,
        maxTokens: tokens,
        temperature: _creatividad,
        context: context.mounted ? context : null,
      );

      // Los servicios devuelven sus fallos como texto que empieza por "Error".
      if (raw.trimLeft().startsWith('Error')) {
        final message = raw.replaceFirst(RegExp(r'^\s*Error:?\s*'), '');
        if (raw.contains(AiService.quotaMarker)) throw _QuotaExceeded(message);
        throw AiResponseException(message);
      }

      try {
        return AiJson.extract(raw);
      } on AiJsonException catch (e) {
        await log.appendLog(
          'WARNING generateContent ($provider/$model, intento $attempt, '
          'maxTokens $tokens): ${e.message} Inicio de la respuesta: '
          '${raw.length > 300 ? raw.substring(0, 300) : raw}',
        );
        if (attempt == maxAttempts) {
          throw AiResponseException(
            e.truncated
                ? 'La respuesta de la IA era demasiado larga y llegó cortada. '
                    'Prueba a pedir menos recetas en Ajustes.'
                : 'La IA no ha devuelto una respuesta válida. Inténtalo de nuevo.',
          );
        }
        if (e.truncated) tokens = (tokens * 2).clamp(1024, cap);
      }
    }
    throw AiResponseException('La IA no ha devuelto una respuesta válida.');
  }

  Future<void> shareRecipe(Recipe recipe, BuildContext context) async {
    await ShareRecipeService().shareRecipe([recipe]);
  }
}

/// La IA no ha podido dar una respuesta utilizable. [message] está pensado
/// para enseñárselo al usuario tal cual.
class AiResponseException implements Exception {
  AiResponseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El proveedor ha agotado su cuota; se puede probar con otro.
class _QuotaExceeded implements Exception {
  _QuotaExceeded(this.message);

  final String message;
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
