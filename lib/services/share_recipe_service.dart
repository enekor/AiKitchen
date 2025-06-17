import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html;

class ShareRecipeService {
  Future<void> shareRecipe(List<Recipe> recipe) async {
    try {
      debugPrint('Sharing recipes...' + recipe.length.toString());

      if (kIsWeb) {
        // Implementación para web
        await _shareRecipeOnWeb(recipe);
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

  Future<void> _shareRecipeOnWeb(List<Recipe> recipe) async {
    // Convert the Recipe object to JSON
    final recipeJson = jsonEncode(recipe);

    // Crear el archivo como blob y descargarlo
    final bytes = utf8.encode(recipeJson);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Verificar si el navegador soporta Web Share API
    if (_supportsWebShare()) {
      try {
        // Intentar usar Web Share API nativa del navegador
        await html.window.navigator.share({
          'title': 'Recetas de AiKitchen',
          'text': 'Mira estas recetas que tengo en AiKitchen',
          'files': [
            // Nota: File sharing via Web Share API tiene soporte limitado
          ],
        });
        return;
      } catch (e) {
        debugPrint('Web Share API failed, falling back to download: $e');
      }
    }

    // Fallback: Descargar el archivo
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute('download', 'recetas.aikr')
          ..click();

    // Limpiar la URL del objeto
    html.Url.revokeObjectUrl(url);
  }

  static bool _supportsWebShare() {
    return html.window.navigator.share != null;
  }
}
