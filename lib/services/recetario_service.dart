import 'dart:async';
import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/log_file_service.dart';
import 'package:aikitchen/services/recetario/recetario_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// El recetario no se ha podido cargar. [message] es para el usuario.
class RecetarioException implements Exception {
  const RecetarioException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El recetario: un fichero JSON con recetas publicado en GitHub, cuya
/// dirección se configura en Ajustes.
///
/// La última descarga se guarda en el dispositivo y es lo que se muestra.
/// Solo se vuelve a descargar, en segundo plano y sin bloquear la pantalla,
/// cuando han pasado los días configurados; o cuando el usuario pulsa
/// "Actualizar". Mientras tanto se sigue viendo la lista guardada.
///
/// raw.githubusercontent.com permite leer sus ficheros desde el navegador,
/// así que la versión web no necesita proxy.
class RecetarioService extends ChangeNotifier {
  RecetarioService({
    RecetarioCache? cache,
    Future<String> Function(Uri uri)? fetch,
    DateTime Function()? now,
  })  : _cache = cache ?? createRecetarioCache(),
        _fetch = fetch ?? _httpFetch,
        _now = now ?? DateTime.now;

  static final RecetarioService instance = RecetarioService();

  final RecetarioCache _cache;
  final Future<String> Function(Uri uri) _fetch;
  final DateTime Function() _now;

  String _url = '';
  Duration _maxAge = const Duration(days: 7);
  List<Recipe>? _recipes;
  DateTime? _updatedAt;
  String? _error;
  bool _downloading = false;
  bool _manual = false;
  Future<void>? _inFlight;
  Timer? _ticker;

  /// Recetas de la última descarga; `null` si todavía no hay ninguna.
  List<Recipe>? get recipes => _recipes;

  /// Cuándo se descargaron las recetas que se están mostrando.
  DateTime? get updatedAt => _updatedAt;

  /// Error de la última descarga, para mostrarlo si no hay lista guardada.
  String? get error => _error;

  /// Hay una descarga en marcha, sea automática o pedida por el usuario.
  bool get isDownloading => _downloading;

  /// La descarga en marcha la ha pedido el usuario con "Actualizar". Solo en
  /// ese caso se muestra el indicador de carga; la automática es silenciosa.
  bool get isManualRefresh => _downloading && _manual;

  /// Aplica la configuración de Ajustes: carga la copia guardada y, si es
  /// más antigua que [maxAge] o es de otra URL, descarga en segundo plano.
  /// No espera a la descarga.
  Future<void> configure(String url, Duration maxAge) async {
    final rawUrl = url.trim().isEmpty ? '' : toRawUrl(url);
    final urlChanged = rawUrl != _url;
    _url = rawUrl;
    _maxAge = maxAge;

    if (urlChanged) {
      _recipes = null;
      _updatedAt = null;
      _error = null;
      notifyListeners();
      if (rawUrl.isEmpty) return;
      await _loadFromCache();
    }
    _refreshIfStale();
  }

  /// Revisa cada hora si toca actualizar. En una tableta que se queda
  /// encendida en la cocina, la app puede pasar días abierta sin reiniciarse.
  void startAutoRefresh() {
    _ticker ??= Timer.periodic(const Duration(hours: 1), (_) => _refreshIfStale());
  }

  void _refreshIfStale() {
    if (_url.isEmpty || _downloading) return;
    final updated = _updatedAt;
    if (updated == null || _now().difference(updated) >= _maxAge) {
      unawaited(refresh());
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await _cache.read();
      if (cached == null || cached.url != _url) return;
      _recipes = parse(cached.body);
      _updatedAt = cached.savedAt;
      notifyListeners();
    } catch (e) {
      // Copia ilegible o de un formato viejo: se ignora y se descarga.
      await _log('WARNING Recetario: copia local ilegible: $e');
    }
  }

  /// Descarga el recetario y, si es válido, sustituye la lista y la copia
  /// guardada. Con [manual] la pantalla muestra el indicador de carga. Si
  /// falla, se conserva la lista anterior y el motivo queda en [error]; nunca
  /// lanza, para poder llamarla en segundo plano sin esperarla.
  Future<void> refresh({bool manual = false}) async {
    if (_url.isEmpty) return;
    if (_inFlight != null) {
      // Ya hay una en marcha: si la pide el usuario, pasa a mostrarse.
      if (manual && !_manual) {
        _manual = true;
        notifyListeners();
      }
      return _inFlight;
    }
    _downloading = true;
    _manual = manual;
    notifyListeners();

    final url = _url;
    final completer = Completer<void>();
    _inFlight = completer.future;
    try {
      final body = await _download(url);
      final recipes = parse(body);
      if (url == _url) {
        _recipes = recipes;
        _updatedAt = _now();
        _error = null;
        try {
          await _cache.write(CachedRecetario(url: url, body: body, savedAt: _updatedAt!));
        } catch (e) {
          // Sin espacio para la copia: la lista sigue valiendo en esta sesión.
          await _log('WARNING Recetario: no se pudo guardar la copia: $e');
        }
      }
    } on RecetarioException catch (e) {
      if (url == _url) _error = e.message;
      await _log('ERROR Recetario: ${e.message}');
    } catch (e) {
      if (url == _url) _error = 'No se ha podido cargar el recetario.';
      await _log('ERROR Recetario: $e');
    } finally {
      _downloading = false;
      _manual = false;
      _inFlight = null;
      notifyListeners();
      completer.complete();
    }
  }

  Future<String> _download(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      throw const RecetarioException('La URL del recetario no es válida. Revísala en Ajustes.');
    }
    return _fetch(uri);
  }

  static Future<String> _httpFetch(Uri uri) async {
    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw const RecetarioException(
        'No se ha podido descargar el recetario. Comprueba la conexión.',
      );
    }
    if (response.statusCode == 404) {
      throw const RecetarioException(
        'No se encuentra el recetario en esa URL. Revisa que el fichero exista y sea público.',
      );
    }
    if (response.statusCode != 200) {
      throw RecetarioException(
        'GitHub ha respondido con un error (${response.statusCode}) al descargar el recetario.',
      );
    }
    // GitHub sirve el fichero como texto: se decodifica siempre como UTF-8
    // para no estropear tildes y eñes.
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  /// El registro es secundario: si falla, no debe afectar a la descarga.
  static Future<void> _log(String message) async {
    try {
      await LogFileService().appendLog(message);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Convierte el enlace normal de GitHub a un fichero
  /// (github.com/usuario/repo/blob/rama/ruta) en su versión descargable
  /// (raw.githubusercontent.com/usuario/repo/rama/ruta). El resto, tal cual.
  static String toRawUrl(String url) {
    final trimmed = url.trim();
    final match = RegExp(
      r'^https?://(?:www\.)?github\.com/([^/]+)/([^/]+)/(?:blob|raw)/(.+)$',
    ).firstMatch(trimmed);
    if (match == null) return trimmed;
    return 'https://raw.githubusercontent.com/${match[1]}/${match[2]}/${match[3]}';
  }

  /// Recetas de un JSON con una lista de recetas, o un objeto con ella en
  /// "recetas". Las recetas mal formadas se saltan en vez de invalidar todo
  /// el recetario.
  static List<Recipe> parse(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const RecetarioException('El fichero del recetario no es un JSON válido.');
    }

    final list = decoded is List
        ? decoded
        : (decoded is Map && decoded['recetas'] is List ? decoded['recetas'] as List : null);
    if (list == null) {
      throw const RecetarioException(
        'El recetario debe ser una lista de recetas en JSON.',
      );
    }

    final recipes = <Recipe>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        // Todo lo del recetario cuenta como importado de la web, traiga o
        // no el campo "origen".
        final recipe = Recipe.fromJson(Map<String, dynamic>.from(item))
            .copyWith(origen: RecipeOrigin.web)
          ..id = null;
        if (recipe.nombre.trim().isNotEmpty) recipes.add(recipe);
      } catch (_) {
        // Receta incompleta: se ignora.
      }
    }
    if (recipes.isEmpty && list.isNotEmpty) {
      throw const RecetarioException('Ninguna receta del recetario tiene el formato esperado.');
    }
    return recipes;
  }
}
