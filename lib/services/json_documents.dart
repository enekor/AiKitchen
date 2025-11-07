import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/models/cart_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:path_provider/path_provider.dart';

class JsonDocumentsService {
  String get favFilePath => '/fav_recipes.json';
  String get shoppingListFilePath => '/shopping_list.json';
  String get weeklyMenuFilePath => '/weekly_menu.json';

  Future<List<Recipe>> getFavRecipes() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favRecipesString = prefs.getString('fav_recipes');
        if (favRecipesString != null) {
          return Recipe.fromJsonList(favRecipesString);
        } else {
          return [];
        }
      } else {
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
      }
    } catch (e) {
      print("Error reading favorite recipes: $e");
      return [];
    }
  }

  Future<void> setFavRecipes(List<Recipe> recipes) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favRecipesString = jsonEncode(recipes);
        await prefs.setString('fav_recipes', favRecipesString);
      } else {
        final documentPath = await getApplicationDocumentsDirectory();
        final filePath = '${documentPath.path}$favFilePath';
        final file = File(filePath);
        String favRecipes = jsonEncode(recipes);
        await file.writeAsString(favRecipes);
      }
    } catch (e) {
      print("Error writing favorite recipes: $e");
    }
  }

  Future<void> updateFavRecipes(Recipe recipe, {Recipe? outdatedRecipe}) async {
    List<Recipe> myFavRecipes = await getFavRecipes();

    if (outdatedRecipe != null) {
      myFavRecipes.removeWhere((re) => re.nombre == outdatedRecipe.nombre);
    }

    if (!myFavRecipes.any((re) => re.nombre == recipe.nombre)) {
      myFavRecipes.add(recipe);
    }

    await setFavRecipes(myFavRecipes);
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final cartItemsString = prefs.getString('shopping_list');
        if (cartItemsString != null) {
          List<dynamic> jsonList = jsonDecode(cartItemsString);
          return jsonList.map((item) => CartItem.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
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
      }
    } catch (e) {
      print("Error reading cart items: $e");
      return [];
    }
  }

  Future<void> setCartItems(List<CartItem> cartItems) async {
    try {
      final documentPath = await getApplicationDocumentsDirectory();
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final cartItemsString = jsonEncode(cartItems);
        await prefs.setString('shopping_list', cartItemsString);
      } else {
        final filePath = '${documentPath.path}$shoppingListFilePath';
        final file = File(filePath);
        String cartItemsString = jsonEncode(cartItems);
        await file.writeAsString(cartItemsString);
      }
    } catch (e) {
      print("Error writing cart items: $e");
    }
  }

  Future<void> updateCartItems(List<String> cartItems) async {
    List<CartItem> myCartItems = await getCartItems();
    for (String item in cartItems) {
      if (!myCartItems.any((cartItem) => cartItem.name == item)) {
        myCartItems.add(CartItem(name: item));
      }
    }
    await setCartItems(myCartItems);
  }

  Future<Map<String, List<Recipe>>> loadWeeklyMenu() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final menuString = prefs.getString('weekly_menu');
        if (menuString != null) {
          final Map<String, dynamic> jsonMap = jsonDecode(menuString);
          return jsonMap.map((key, value) {
            final List<dynamic> recipesList = value;
            return MapEntry(
              key,
              recipesList.map((json) => Recipe.fromJson(json)).toList(),
            );
          });
        }
      } else {
        final documentPath = await getApplicationDocumentsDirectory();
        final filePath = '${documentPath.path}$weeklyMenuFilePath';
        final file = File(filePath);
        if (await file.exists()) {
          final menuString = await file.readAsString();
          final Map<String, dynamic> jsonMap = jsonDecode(menuString);
          return jsonMap.map((key, value) {
            final List<dynamic> recipesList = value;
            return MapEntry(
              key,
              recipesList.map((json) => Recipe.fromJson(json)).toList(),
            );
          });
        }
      }
      return {};
    } catch (e) {
      print("Error reading weekly menu: $e");
      return {};
    }
  }

  Future<void> saveWeeklyMenu(Map<String, List<Recipe>> menu) async {
    try {
      final menuJson = menu.map((key, value) {
        return MapEntry(key, value.map((recipe) => recipe.toJson()).toList());
      });

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('weekly_menu', jsonEncode(menuJson));
      } else {
        final documentPath = await getApplicationDocumentsDirectory();
        final filePath = '${documentPath.path}$weeklyMenuFilePath';
        final file = File(filePath);
        await file.writeAsString(jsonEncode(menuJson));
      }
    } catch (e) {
      print("Error writing weekly menu: $e");
    }
  }
}
