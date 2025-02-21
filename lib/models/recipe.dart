import 'dart:convert';

class Recipe {
  final String nombre;
  final List<String> ingredientes;
  final String tiempoPreparacion;
  final String tipo;
  final String descripcion;
  List<String>? pasos;

  Recipe({
    required this.nombre,
    required this.ingredientes,
    required this.tiempoPreparacion,
    required this.tipo,
    required this.descripcion,
    this.pasos,
  });

  // Crear una instancia de Recipe desde un JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      nombre: json['nombre'] as String,
      ingredientes: List<String>.from(json['ingredientes'] as List),
      tiempoPreparacion: json['tiempo_preparacion'] as String,
      tipo: json['tipo_plato'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  // Convertir la instancia de Recipe a JSON
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'ingredientes': ingredientes,
        'tiempo_preparacion': tiempoPreparacion,
        'tipo_plato': tipo,
        'descripcion': descripcion,
      };

  // Método estático para convertir una lista de JSON a lista de Recipe
  static List<Recipe> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList.map((json) => Recipe.fromJson(json)).toList();
  }

  void addSteps(String steps) {
    if(steps.contains('[')){
      var _p = json.decode(steps);
      pasos = _p.map((step) => step.toString()).toList();
    }
  }
}
