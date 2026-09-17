import 'dart:convert';
import 'dart:typed_data';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/files/text_file_reader.dart';

class RecipeFromFileService {
  /// Carga recetas desde una ruta de fichero. Solo en móvil y escritorio.
  Future<List<Recipe>> loadRecipes(String uri) async {
    return parseRecipes(await readTextFile(uri));
  }

  /// Carga recetas desde el contenido en memoria. Es la vía del navegador,
  /// donde el selector de ficheros entrega bytes y nunca una ruta.
  List<Recipe> loadRecipesFromBytes(Uint8List bytes) {
    return parseRecipes(utf8.decode(bytes));
  }

  List<Recipe> parseRecipes(String jsonString) {
    final trimmed = jsonString.trim();
    // Un fichero puede contener una receta suelta o una lista de ellas.
    final normalized = trimmed.startsWith('{') ? '[$trimmed]' : trimmed;
    return Recipe.fromJsonList(normalized);
  }
}
