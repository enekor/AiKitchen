import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/sharing/recipe_share.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/foundation.dart';

class ShareRecipeService {
  /// Comparte una o varias recetas. Funciona en móvil y en navegador.
  Future<void> shareRecipe(List<Recipe> recipes) async {
    if (recipes.isEmpty) return;

    try {
      final fileName = recipes.length == 1
          ? '${_safeFileName(recipes.first.nombre)}.aikr'
          : 'recetas.aikr';

      await shareRecipeFile(
        fileName,
        jsonEncode(recipes),
        'Mira estas recetas que tengo en AiKitchen',
      );
    } catch (e) {
      debugPrint('Error compartiendo receta: $e');
      Toaster.showError('No se ha podido compartir la receta');
    }
  }

  /// Quita de un nombre de receta los caracteres que no valen en un fichero.
  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return cleaned.isEmpty ? 'receta' : cleaned;
  }
}
