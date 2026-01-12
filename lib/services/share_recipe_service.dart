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
        return;
      } else {
        await _shareRecipeOnMobile(recipe);
      }
    } catch (e) {
      debugPrint('Error sharing recipe: $e');
    }
  }

  Future<void> _shareRecipeOnMobile(List<Recipe> recipe) async {
    final recipeJson = jsonEncode(recipe);

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/recetas.aikr');
    await file.writeAsString(recipeJson);

    // Usamos el MIME type personalizado para que el sistema lo vincule a nuestra app
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.aikitchen.recipe')],
      subject: 'Recetas de AiKitchen',
      text: 'Mira estas recetas que tengo en AiKitchen',
    );
  }
}
