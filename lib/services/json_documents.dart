import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:path_provider/path_provider.dart';

class JsonDocumentsService {
  JsonDocumentsService() {
    getApplicationDocumentsDirectory().then((path) => directory = path.path);
  }

  static String directory = '';
  static String get favFilePath => '${directory}/fav_recipes.json';
  static String get shoppingListFilePath => '${directory}/shopping_list.json';

  static Future<List<Recipe>> getFavRecipes() async {
    try {
      final filePath = favFilePath;
      final file = File(filePath);
      if (await file.exists()) {
        String favRecipes = await file.readAsString();
        return Recipe.fromJsonList(favRecipes);
      } else {
        return [];
      }
    } catch (e) {
      print("Error reading favorite recipes: $e");
      return [];
    }
  }

  static Future<void> setFavRecipes(List<Recipe> recipes) async {
    try {
      final filePath = favFilePath;
      final file = File(filePath);
      String favRecipes = jsonEncode(recipes);
      await file.writeAsString(favRecipes);
    } catch (e) {
      print("Error writing favorite recipes: $e");
    }
  }

  static Future<List<CartItem>> getCartItems() async {
    try {
      final filePath = shoppingListFilePath;
      final file = File(filePath);
      if (await file.exists()) {
        String cartItemsString = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(cartItemsString);
        return jsonList.map((item) => CartItem.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error reading cart items: $e");
      return [];
    }
  }

  static Future<void> setCartItems(List<CartItem> cartItems) async {
    try {
      final filePath = shoppingListFilePath;
      final file = File(filePath);
      String cartItemsString = jsonEncode(cartItems);
      await file.writeAsString(cartItemsString);
    } catch (e) {
      print("Error writing cart items: $e");
    }
  }
}
