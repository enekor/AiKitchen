import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class ShareRecipeService {
  Future<void> shareRecipe(List<Recipe> recipe) async {
    try {
      debugPrint('Sharing recipes...' + recipe.length.toString());

      if (kIsWeb) {
        // Implementación para web
        return;
      } else {
        // Implementación para móvil/desktop usando share_plus
        await _shareRecipeOnMobile(recipe);
      }
    } catch (e) {
      debugPrint('Error sharing recipe: $e');
    }
  }

  Future<void> _shareRecipeOnMobile(List<Recipe> recipe) async {
    // Convert the Recipe object to JSON
    final recipeJson = jsonEncode(recipe);

    // Create a temporary file with .aikr extension
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/recetas.aikr');
    await file.writeAsString(recipeJson);

    // Trigger the system share menu using share_plus
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'recetas',
      text: 'Mira estas recetas que tengo en AiKitchen',
    );
  }

  // Future<void> _shareRecipeOnWeb(List<Recipe> recipe) async {
  //   // Convert the Recipe object to JSON
  //   final recipeJson = jsonEncode(recipe);

  //   // Crear el archivo como blob y descargarlo
  //   final bytes = utf8.encode(recipeJson);
  //   final blob = web.Blob(
  //     [bytes.toJS].toJS,
  //     web.BlobPropertyBag(type: 'application/json'),
  //   );
  //   final url = web.URL.createObjectURL(blob);

  //   // Descargar el archivo directamente (más simple y confiable)
  //   web.HTMLAnchorElement()
  //     ..href = url
  //     ..download = 'recetas.aikr'
  //     ..click();

  //   // Limpiar la URL del objeto
  //   web.URL.revokeObjectURL(url);
  // }
}
