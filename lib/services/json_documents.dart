import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:path_provider/path_provider.dart';

class JsonDocumentsService {
  String get favFilePath => '/fav_recipes.json';
  String get shoppingListFilePath => '/shopping_list.json';

  Future<List<Recipe>> getFavRecipes() async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      final filePath = '${documentPath.path}$favFilePath';
      final file = File(filePath);
      if (await file.exists()) {
        String favRecipes = await file.readAsString();
        return Recipe.fromJsonList(favRecipes);
      } else {
        File(filePath).createSync();
        return [];
      }
    } catch (e) {
      print("Error reading favorite recipes: $e");
      return [];
    }
  }

  Future<void> setFavRecipes(List<Recipe> recipes) async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      final filePath = '${documentPath.path}$favFilePath';
      final file = File(filePath);
      String favRecipes = jsonEncode(recipes);
      await file.writeAsString(favRecipes);
    } catch (e) {
      print("Error writing favorite recipes: $e");
    }
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      final filePath = '${documentPath.path}$shoppingListFilePath';
      final file = File(filePath);
      if (await file.exists()) {
        String cartItemsString = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(cartItemsString);
        return jsonList.map((item) => CartItem.fromJson(item)).toList();
      } else {
        File(filePath).createSync();

        return [];
      }
    } catch (e) {
      print("Error reading cart items: $e");
      return [];
    }
  }

  Future<void> setCartItems(List<CartItem> cartItems) async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      final filePath = '${documentPath.path}$shoppingListFilePath';
      final file = File(filePath);
      String cartItemsString = jsonEncode(cartItems);
      await file.writeAsString(cartItemsString);
    } catch (e) {
      print("Error writing cart items: $e");
    }
  }
}
