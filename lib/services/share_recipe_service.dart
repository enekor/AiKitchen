import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareRecipeService {
  Future<void> shareRecipe(List<Recipe> recipe) async {
    try {
      // Convert the Recipe object to JSON
      final recipeJson = jsonEncode(recipe.map((r)=>r.toJson()));

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
    } catch (e) {
      debugPrint('Error sharing recipe: $e');
    }
  }
}
