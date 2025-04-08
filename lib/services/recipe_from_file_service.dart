import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/recipe.dart';

class RecipeFromFileService {
  Future<Recipe> loadRecipe(String uri) async {
    //read file from uri
    final file = File(uri);
    final jsonString = await file.readAsString();
    //decode json
    final json = jsonDecode(jsonString);
    //return recipe
    return Recipe.fromJson(json);
  }
}
