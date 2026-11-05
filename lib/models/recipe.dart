import 'dart:convert';
import 'dart:typed_data';

/// Cómo se obtuvo una receta. Determina el filtro y la insignia de origen en
/// Favoritos. `null` (recetas guardadas antes de este campo) se trata como
/// [ia], por ser el caso mayoritario.
enum RecipeOrigin {
  manual,
  ia,
  web;

  static RecipeOrigin? fromName(String? name) {
    if (name == null) return null;
    return RecipeOrigin.values.where((o) => o.name == name).firstOrNull;
  }
}

class Recipe {
  int? id;
  final String nombre;
  final String descripcion;
  final String tiempoEstimado;
  final List<String> ingredientes;
  final List<String> preparacion;
  final String calorias;
  final String raciones;

  /// Opcional para no romper las recetas guardadas antes de este campo.
  final RecipeOrigin? origen;

  /// Foto del plato en JPEG codificado en base64. Va dentro del JSON para que
  /// viaje con la receta al compartirla. `null` si no tiene.
  final String? foto;

  /// Etiquetas libres del usuario ("Cenas rápidas", "Táper"...).
  final List<String> etiquetas;

  /// Canal de YouTube del que sale la receta, en las del recetario. En sus
  /// ficheros llega en el campo "origen".
  final String? canal;

  Recipe({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.tiempoEstimado,
    required this.ingredientes,
    required this.preparacion,
    required this.calorias,
    required this.raciones,
    this.origen,
    this.foto,
    this.etiquetas = const [],
    this.canal,
  });

  bool get tieneFoto => foto != null && foto!.isNotEmpty;

  static final RegExp _youtubeUrl = RegExp(
    r'https?://(?:www\.|m\.)?(?:youtube\.com/(?:watch\?\S+|shorts/\S+|live/\S+)|youtu\.be/\S+)',
    caseSensitive: false,
  );

  /// Enlace al vídeo de YouTube que acompaña a la receta, si la descripción
  /// trae uno (las recetas del recetario lo llevan al final). `null` si no.
  String? get videoUrl {
    final match = _youtubeUrl.firstMatch(descripcion)?.group(0);
    // Quita la puntuación que pueda ir pegada al final del enlace.
    return match?.replaceFirst(RegExp(r'[).,;!?»"]+$'), '');
  }

  /// Descripción para mostrar, sin el enlace al vídeo ni el guion que lo
  /// separa del texto. La original se conserva tal cual para que el enlace
  /// siga en favoritos y al compartir.
  String get descripcionVisible {
    if (videoUrl == null) return descripcion;
    return descripcion
        .replaceAll(_youtubeUrl, '')
        .replaceAll(RegExp(r'\s*[-–—|:]\s*$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  Uint8List? _fotoBytes;

  /// Bytes de la foto, decodificados una sola vez. `null` si no tiene o si el
  /// base64 está dañado, para que la tarjeta caiga en su versión sin foto.
  Uint8List? get fotoBytes {
    if (!tieneFoto) return null;
    try {
      return _fotoBytes ??= base64Decode(foto!);
    } catch (_) {
      return null;
    }
  }

  /// Copia con algunos campos cambiados. Para quitar la foto, [sinFoto].
  Recipe copyWith({
    String? foto,
    bool sinFoto = false,
    List<String>? etiquetas,
    RecipeOrigin? origen,
  }) {
    return Recipe(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tiempoEstimado: tiempoEstimado,
      ingredientes: ingredientes,
      preparacion: preparacion,
      calorias: calorias,
      raciones: raciones,
      origen: origen ?? this.origen,
      foto: sinFoto ? null : (foto ?? this.foto),
      etiquetas: etiquetas ?? this.etiquetas,
      canal: canal,
    );
  }

  /// Origen a efectos de mostrar, con las recetas antiguas cayendo en "IA".
  RecipeOrigin get origenEfectivo => origen ?? RecipeOrigin.ia;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // En los ficheros del recetario "origen" trae el nombre del canal, no
    // uno de los orígenes de la app: se guarda como canal y la receta pasa a
    // contar como importada de la web.
    final origenRaw = (json['origen'] as String?)?.trim();
    final origen = RecipeOrigin.fromName(origenRaw);
    final canalJson = (json['canal'] as String?)?.trim();
    final canal = canalJson != null && canalJson.isNotEmpty
        ? canalJson
        : (origen == null && origenRaw != null && origenRaw.isNotEmpty ? origenRaw : null);
    return Recipe(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tiempoEstimado: json['tiempoEstimado'],
      ingredientes: List<String>.from(json['ingredientes']),
      preparacion: List<String>.from(json['preparacion']),
      calorias: json['calorias'].toString(),
      raciones: json['raciones'].toString(),
      origen: origen ?? (canal != null ? RecipeOrigin.web : null),
      foto: json['foto'] as String?,
      etiquetas: _parseEtiquetas(json['etiquetas']),
      canal: canal,
    );
  }

  /// [includeFoto] a `false` para mandar la receta a la IA: la foto en base64
  /// dispararía el tamaño del prompt sin aportar nada.
  Map<String, dynamic> toJson({bool includeFoto = true}) {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempoEstimado': tiempoEstimado,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'calorias': calorias,
      'raciones': raciones,
      if (origen != null) 'origen': origen!.name,
      if (includeFoto && tieneFoto) 'foto': foto,
      if (etiquetas.isNotEmpty) 'etiquetas': etiquetas,
      if (canal != null) 'canal': canal,
    };
  }

  static List<String> _parseEtiquetas(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return const [];
  }

  // Compatibilidad con SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempo_estimado': tiempoEstimado,
      'ingredientes': jsonEncode(ingredientes),
      'preparacion': jsonEncode(preparacion),
      'calorias': calorias,
      'raciones': raciones,
      'origen': origen?.name,
      'foto': foto,
      'etiquetas': jsonEncode(etiquetas),
      'canal': canal,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      tiempoEstimado: map['tiempo_estimado'],
      ingredientes: List<String>.from(jsonDecode(map['ingredientes'])),
      preparacion: List<String>.from(jsonDecode(map['preparacion'])),
      calorias: map['calorias'].toString(),
      raciones: map['raciones'].toString(),
      // Columna añadida en la versión 3 de la base de datos: puede faltar en
      // filas migradas de una versión anterior.
      origen: RecipeOrigin.fromName(map['origen'] as String?),
      // Columnas añadidas en la versión 4; no existen en la tabla del menú.
      foto: map['foto'] as String?,
      etiquetas: _parseEtiquetas(map['etiquetas']),
      // Columna añadida en la versión 5.
      canal: map['canal'] as String?,
    );
  }

  static List<Recipe> fromJsonList(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    
    List<dynamic>? jsonData;

    List<dynamic>? findList(dynamic obj) {
      if (obj is List) return obj;
      if (obj is Map) {
        if (obj.containsKey('recetas') && obj['recetas'] is List) {
          return obj['recetas'];
        }
        if (obj.containsKey('response')) {
          return findList(obj['response']);
        }
      }
      return null;
    }

    jsonData = findList(decoded);

    if (jsonData == null) {
      throw Exception('No se encontró una lista de recetas válida en la respuesta JSON');
    }
    
    return jsonData.map((json) => Recipe.fromJson(json)).toList();
  }

  bool recipeContainsIngredient(String ingredient) {
    for (String ingredientInRecipe in ingredientes) {
      if (ingredientInRecipe.toLowerCase().contains(ingredient.toLowerCase())) {
        return true;
      }
    }
    for (String step in preparacion) {
      if (step.toLowerCase().contains(ingredient.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
