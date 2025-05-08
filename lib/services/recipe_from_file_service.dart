import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';

class RecipeFromFileService {
  Future<List<Recipe>> loadRecipes(String uri) async {
    //read file from uri
    final file = File(uri);
    final jsonString = await file.readAsString();
    //decode json
    return Recipe.fromJsonList(jsonString);
  }
}
