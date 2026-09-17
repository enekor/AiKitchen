import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/storage/app_storage.dart';

/// Fachada de datos de la app. Delega en [appStorage], que resuelve en tiempo
/// de compilación a SQLite (móvil) o a localStorage (web).
class JsonDocumentsService {
  final AppStorage _storage = appStorage;

  // --- Recetas Favoritas ---
  Future<List<Recipe>> getFavRecipes() async {
    return await _storage.getFavRecipes();
  }

  Future<void> addFavRecipe(Recipe recipe) async {
    await _storage.insertFavRecipe(recipe);
  }

  Future<void> removeFavRecipe(int id) async {
    await _storage.deleteFavRecipe(id);
  }

  Future<void> updateFavRecipe(Recipe recipe) async {
    if (recipe.id != null) {
      await _storage.updateFavRecipe(recipe);
    }
  }

  /// Reemplaza la lista completa de favoritos.
  Future<void> setFavRecipes(List<Recipe> recipes) async {
    final currentFavs = await _storage.getFavRecipes();
    for (var fav in currentFavs) {
      if (fav.id != null) await _storage.deleteFavRecipe(fav.id!);
    }
    for (var recipe in recipes) {
      await _storage.insertFavRecipe(recipe);
    }
  }

  // --- Lista de la Compra ---
  Future<List<CartItem>> getCartItems() async {
    return await _storage.getCartItems();
  }

  Future<void> addCartItem(CartItem item) async {
    await _storage.insertCartItem(item);
  }

  Future<void> updateCartItem(CartItem item) async {
    if (item.id != null) {
      await _storage.updateCartItem(item);
    }
  }

  Future<void> removeCartItem(int id) async {
    await _storage.deleteCartItem(id);
  }

  Future<void> addCartItemsFromNames(List<String> names) async {
    final currentItems = await _storage.getCartItems();
    for (String name in names) {
      if (!currentItems.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      )) {
        await _storage.insertCartItem(CartItem(name: name));
      }
    }
  }

  /// Igual que [addCartItemsFromNames], pero conservando la categoría de cada
  /// artículo. Se usa al generar la lista con IA o al exportar el menú
  /// semanal ya clasificado por pasillo.
  Future<void> addCategorizedCartItems(List<CartItem> items) async {
    final currentItems = await _storage.getCartItems();
    for (final item in items) {
      if (!currentItems.any(
        (existing) => existing.name.toLowerCase() == item.name.toLowerCase(),
      )) {
        await _storage.insertCartItem(item);
      }
    }
  }

  // --- Menú Semanal ---
  Future<Map<String, List<Recipe>>> loadWeeklyMenu() async {
    return await _storage.getWeeklyMenu();
  }

  Future<void> saveWeeklyMenu(Map<String, List<Recipe>> menu) async {
    await _storage.clearMenu();
    for (final entry in menu.entries) {
      final recetas = entry.value;
      for (var i = 0; i < recetas.length; i++) {
        // El primer plato del día es la comida; el resto, cena.
        final tipoComida = i == 0 ? 'Comida' : 'Cena';
        await _storage.insertMenuRecipe(recetas[i], entry.key, tipoComida);
      }
    }
  }
}
