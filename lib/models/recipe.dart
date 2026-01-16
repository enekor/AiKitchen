import 'dart:convert';

class Recipe {
  int? id;
  final String nombre;
  final String descripcion;
  final String tiempoEstimado;
  final List<String> ingredientes;
  final List<String> preparacion;
  final double calorias;
  final int raciones;

  Recipe({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.tiempoEstimado,
    required this.ingredientes,
    required this.preparacion,
    required this.calorias,
    required this.raciones,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tiempoEstimado: json['tiempo_estimado'],
      ingredientes: List<String>.from(json['ingredientes']),
      preparacion: List<String>.from(json['preparacion']),
      calorias: json['calorias']?.toDouble() ?? 0,
      raciones: json['raciones'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempo_estimado': tiempoEstimado,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'calorias': calorias,
      'raciones': raciones,
    };
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
      calorias: map['calorias']?.toDouble() ?? 0,
      raciones: map['raciones'] ?? 1,
    );
  }

  static List<Recipe> fromJsonList(String jsonString) {
    final List<dynamic> jsonData = json.decode(jsonString);
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
