import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/log_file_service.dart';
import 'package:http/http.dart' as http;

/// El recetario no se ha podido cargar. [message] es para el usuario.
class RecetarioException implements Exception {
  const RecetarioException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lee el recetario: un fichero JSON con recetas publicado en GitHub, cuya
/// dirección se configura en Ajustes.
///
/// raw.githubusercontent.com permite leer sus ficheros desde el navegador,
/// así que la versión web no necesita proxy. La lista se guarda en memoria
/// durante la sesión para no descargarla cada vez que se abre la pestaña.
class RecetarioService {
  RecetarioService._();

  static final RecetarioService instance = RecetarioService._();

  String? _cachedUrl;
  List<Recipe>? _cached;

  /// Recetas del recetario en [url]. Con [refresh] vuelve a descargarlas.
  Future<List<Recipe>> load(String url, {bool refresh = false}) async {
    final rawUrl = toRawUrl(url);
    if (!refresh && _cachedUrl == rawUrl && _cached != null) return _cached!;

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      throw const RecetarioException('La URL del recetario no es válida. Revísala en Ajustes.');
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 30));
    } catch (e) {
      await LogFileService().appendLog('ERROR Recetario: $e');
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
    final recipes = parse(utf8.decode(response.bodyBytes, allowMalformed: true));
    _cachedUrl = rawUrl;
    _cached = recipes;
    return recipes;
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
