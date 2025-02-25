import 'dart:convert';

class Recipe {
  final String nombre;
  final String descripcion;
  final String tiempoEstimado;
  final List<String> ingredientes;
  final List<String> preparacion;

  Recipe({
    required this.nombre,
    required this.descripcion,
    required this.tiempoEstimado,
    required this.ingredientes,
    required this.preparacion,
  });

  // Método para crear una instancia de Recipe a partir de un JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tiempoEstimado: json['tiempo_estimado'],
      ingredientes: List<String>.from(json['ingredientes']),
      preparacion: List<String>.from(json['preparacion']),
    );
  }

  // Método para convertir una instancia de Recipe a JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempo_estimado': tiempoEstimado,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
    };
  }

  // Método para crear una lista de Recipe a partir de una lista de JSON
  static List<Recipe> fromJsonList(String jsonString) {
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((json) => Recipe.fromJson(json)).toList();
  }

  bool recipeContainsIngredient(String ingredient){
    for(String ingredientInRecipe in ingredientes){
      if(ingredientInRecipe.contains(ingredient)){
        return true;
      }
    }
    return false;
  }
}
