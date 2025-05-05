import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareRecipeService {
  Future<void> shareRecipe(Recipe recipe) async {
    try {
      // Convert the Recipe object to JSON
      final recipeJson = jsonEncode(recipe.toJson());

      // Create a temporary file with .aikr extension
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/${recipe.nombre}.aikr');
      await file.writeAsString(recipeJson);

      // Trigger the system share menu using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: recipe.nombre,
        text: 'Mira esta receta: ${recipe.nombre}',
      );
    } catch (e) {
      debugPrint('Error sharing recipe: $e');
    }
  }
}
