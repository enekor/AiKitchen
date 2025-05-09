import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';

class RecipeFromFileService {
  Future<List<Recipe>> loadRecipes(String uri) async {
    //read file from uri
    final file = File(uri);
    String jsonString = await file.readAsString();

    jsonString = jsonString.startsWith('{') ? '[$jsonString]' : jsonString;
    //decode json
    return Recipe.fromJsonList(jsonString);
  }
}
