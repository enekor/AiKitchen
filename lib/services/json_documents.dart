import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/sqlite_service.dart';

class JsonDocumentsService {
  final _sqlite = SqliteService();

  // --- Recetas Favoritas ---
  Future<List<Recipe>> getFavRecipes() async {
    return await _sqlite.getFavRecipes();
  }

  Future<void> addFavRecipe(Recipe recipe) async {
    await _sqlite.insertFavRecipe(recipe);
  }

  Future<void> removeFavRecipe(int id) async {
    await _sqlite.deleteFavRecipe(id);
  }

  Future<void> updateFavRecipe(Recipe recipe) async {
    if (recipe.id != null) {
      await _sqlite.updateFavRecipe(recipe);
    }
  }

  // Método de compatibilidad para cuando se quiere sincronizar una lista completa
  Future<void> setFavRecipes(List<Recipe> recipes) async {
    final currentFavs = await _sqlite.getFavRecipes();
    // En lugar de borrar todo, podríamos sincronizar, pero si la intención es "reemplazar",
    // borramos lo que no esté en la nueva lista o simplemente limpiamos y reinsertamos.
    for (var fav in currentFavs) {
      if (fav.id != null) await _sqlite.deleteFavRecipe(fav.id!);
    }
    for (var recipe in recipes) {
      await _sqlite.insertFavRecipe(recipe);
    }
  }

  // --- Lista de la Compra ---
  Future<List<CartItem>> getCartItems() async {
    return await _sqlite.getCartItems();
  }

  Future<void> addCartItem(CartItem item) async {
    await _sqlite.insertCartItem(item);
  }

  Future<void> updateCartItem(CartItem item) async {
    if (item.id != null) {
      await _sqlite.updateCartItem(item);
    }
  }

  Future<void> removeCartItem(int id) async {
    await _sqlite.deleteCartItem(id);
  }

  // Método de compatibilidad para strings (como se usaba antes)
  Future<void> addCartItemsFromNames(List<String> names) async {
    final currentItems = await _sqlite.getCartItems();
    for (String name in names) {
      if (!currentItems.any((item) => item.name.toLowerCase() == name.toLowerCase())) {
        await _sqlite.insertCartItem(CartItem(name: name));
      }
    }
  }

  // --- Menú Semanal ---
  Future<Map<String, List<Recipe>>> loadWeeklyMenu() async {
    return await _sqlite.getWeeklyMenu();
  }

  Future<void> saveWeeklyMenu(Map<String, List<Recipe>> menu) async {
    await _sqlite.clearMenu();
    menu.forEach((dia, recetas) {
      for (var i = 0; i < recetas.length; i++) {
        // Asignamos tipo según el orden si no viene especificado
        String tipoComida = i == 0 ? 'Comida' : 'Cena';
        _sqlite.insertMenuRecipe(recetas[i], dia, tipoComida);
      }
    });
  }
}
