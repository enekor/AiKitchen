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
  });

  bool get tieneFoto => foto != null && foto!.isNotEmpty;

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
      origen: origen,
      foto: sinFoto ? null : (foto ?? this.foto),
      etiquetas: etiquetas ?? this.etiquetas,
    );
  }

  /// Origen a efectos de mostrar, con las recetas antiguas cayendo en "IA".
  RecipeOrigin get origenEfectivo => origen ?? RecipeOrigin.ia;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tiempoEstimado: json['tiempoEstimado'],
      ingredientes: List<String>.from(json['ingredientes']),
      preparacion: List<String>.from(json['preparacion']),
      calorias: json['calorias'].toString(),
      raciones: json['raciones'].toString(),
      origen: RecipeOrigin.fromName(json['origen'] as String?),
      foto: json['foto'] as String?,
      etiquetas: _parseEtiquetas(json['etiquetas']),
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
