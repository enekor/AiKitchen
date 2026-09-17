import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';

// Selecciona la implementación en tiempo de compilación.
// En web no existe `dart:io`, así que se usa `storage_web.dart`, que nunca
// importa `sqflite` (ese paquete depende de `dart:io` y rompería el build web).
import 'storage_web.dart' if (dart.library.io) 'storage_native.dart' as impl;

/// Contrato único de persistencia de la aplicación.
///
/// En móvil/escritorio lo implementa SQLite; en navegador, `shared_preferences`
/// sobre `localStorage`. El resto del código no debe saber cuál está activa.
abstract class AppStorage {
  // --- Preferencias ---
  Future<String?> getPreference(String key);
  Future<void> setPreference(String key, String value);
  Future<void> deletePreference(String key);
  Future<void> clearPreferences();

  // --- Lista de la compra ---
  Future<List<CartItem>> getCartItems();
  Future<int> insertCartItem(CartItem item);
  Future<void> updateCartItem(CartItem item);
  Future<void> deleteCartItem(int id);

  // --- Recetas favoritas ---
  Future<List<Recipe>> getFavRecipes();
  Future<int> insertFavRecipe(Recipe recipe);
  Future<void> updateFavRecipe(Recipe recipe);
  Future<void> deleteFavRecipe(int id);

  // --- Menú semanal ---
  Future<Map<String, List<Recipe>>> getWeeklyMenu();
  Future<void> insertMenuRecipe(Recipe recipe, String dia, String tipoComida);
  Future<void> clearMenu();
}

final AppStorage _storage = impl.createStorage();

/// Instancia única de almacenamiento para toda la app.
AppStorage get appStorage => _storage;
