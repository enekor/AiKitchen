import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/sqlite_service.dart';
import 'package:aikitchen/services/storage/app_storage.dart';

/// Implementación para móvil y escritorio: delega en SQLite.
///
/// Este fichero solo se compila cuando `dart:io` está disponible, por lo que
/// `sqflite` nunca llega al bundle web.
AppStorage createStorage() => NativeStorage();

class NativeStorage implements AppStorage {
  final SqliteService _db = SqliteService();

  @override
  Future<String?> getPreference(String key) => _db.getByPreference(key);

  @override
  Future<void> setPreference(String key, String value) =>
      _db.editPreference(key, value);

  @override
  Future<void> deletePreference(String key) => _db.deleteByPreference(key);

  @override
  Future<void> clearPreferences() => _db.deletePreference();

  @override
  Future<List<CartItem>> getCartItems() => _db.getCartItems();

  @override
  Future<int> insertCartItem(CartItem item) => _db.insertCartItem(item);

  @override
  Future<void> updateCartItem(CartItem item) => _db.updateCartItem(item);

  @override
  Future<void> deleteCartItem(int id) => _db.deleteCartItem(id);

  @override
  Future<List<Recipe>> getFavRecipes() => _db.getFavRecipes();

  @override
  Future<int> insertFavRecipe(Recipe recipe) => _db.insertFavRecipe(recipe);

  @override
  Future<void> updateFavRecipe(Recipe recipe) => _db.updateFavRecipe(recipe);

  @override
  Future<void> deleteFavRecipe(int id) => _db.deleteFavRecipe(id);

  @override
  Future<Map<String, List<Recipe>>> getWeeklyMenu() => _db.getWeeklyMenu();

  @override
  Future<void> insertMenuRecipe(Recipe recipe, String dia, String tipoComida) =>
      _db.insertMenuRecipe(recipe, dia, tipoComida);

  @override
  Future<void> clearMenu() => _db.clearMenu();
}
