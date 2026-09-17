import 'dart:convert';

import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementación para navegador: `shared_preferences` sobre `localStorage`.
///
/// Guarda cada colección como un documento JSON bajo una clave propia y
/// mantiene un contador para emular el `AUTOINCREMENT` de SQLite.
AppStorage createStorage() => WebStorage();

class WebStorage implements AppStorage {
  static const String _prefPrefix = 'aik.pref.';
  static const String _favKey = 'aik.fav_recipes';
  static const String _cartKey = 'aik.shopping_list';
  static const String _menuKey = 'aik.menu';
  static const String _seqKey = 'aik.seq';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Devuelve el siguiente id libre. Es global a todas las colecciones, lo que
  /// es más simple y sigue cumpliendo el contrato: ids únicos dentro de cada una.
  Future<int> _nextId() async {
    final prefs = await _prefs;
    final next = (prefs.getInt(_seqKey) ?? 0) + 1;
    await prefs.setInt(_seqKey, next);
    return next;
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      // Documento corrupto: es preferible empezar limpio a dejar la app muerta.
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(items));
  }

  // --- Preferencias ---

  @override
  Future<String?> getPreference(String key) async {
    final prefs = await _prefs;
    return prefs.getString('$_prefPrefix$key');
  }

  @override
  Future<void> setPreference(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString('$_prefPrefix$key', value);
  }

  @override
  Future<void> deletePreference(String key) async {
    final prefs = await _prefs;
    await prefs.remove('$_prefPrefix$key');
  }

  @override
  Future<void> clearPreferences() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // --- Lista de la compra ---

  @override
  Future<List<CartItem>> getCartItems() async {
    final items = await _readList(_cartKey);
    return items.map(CartItem.fromJson).toList();
  }

  @override
  Future<int> insertCartItem(CartItem item) async {
    final items = await _readList(_cartKey);
    final id = item.id ?? await _nextId();
    item.id = id;
    items.add(item.toJson());
    await _writeList(_cartKey, items);
    return id;
  }

  @override
  Future<void> updateCartItem(CartItem item) async {
    final items = await _readList(_cartKey);
    final index = items.indexWhere((e) => e['id'] == item.id);
    if (index == -1) return;
    items[index] = item.toJson();
    await _writeList(_cartKey, items);
  }

  @override
  Future<void> deleteCartItem(int id) async {
    final items = await _readList(_cartKey);
    items.removeWhere((e) => e['id'] == id);
    await _writeList(_cartKey, items);
  }

  // --- Recetas favoritas ---

  @override
  Future<List<Recipe>> getFavRecipes() async {
    final items = await _readList(_favKey);
    return items.map(Recipe.fromJson).toList();
  }

  @override
  Future<int> insertFavRecipe(Recipe recipe) async {
    final items = await _readList(_favKey);
    final id = recipe.id ?? await _nextId();
    final json = recipe.toJson();
    json['id'] = id;
    items.add(json);
    await _writeList(_favKey, items);
    return id;
  }

  @override
  Future<void> updateFavRecipe(Recipe recipe) async {
    final items = await _readList(_favKey);
    final index = items.indexWhere((e) => e['id'] == recipe.id);
    if (index == -1) return;
    final json = recipe.toJson();
    json['id'] = recipe.id;
    items[index] = json;
    await _writeList(_favKey, items);
  }

  @override
  Future<void> deleteFavRecipe(int id) async {
    final items = await _readList(_favKey);
    items.removeWhere((e) => e['id'] == id);
    await _writeList(_favKey, items);
  }

  // --- Menú semanal ---

  @override
  Future<Map<String, List<Recipe>>> getWeeklyMenu() async {
    final entries = await _readList(_menuKey);
    final Map<String, List<Recipe>> menu = {};
    for (final entry in entries) {
      final dia = entry['dia'] as String?;
      final recipeJson = entry['recipe'];
      if (dia == null || recipeJson is! Map) continue;
      menu
          .putIfAbsent(dia, () => [])
          .add(Recipe.fromJson(Map<String, dynamic>.from(recipeJson)));
    }
    return menu;
  }

  @override
  Future<void> insertMenuRecipe(
    Recipe recipe,
    String dia,
    String tipoComida,
  ) async {
    final entries = await _readList(_menuKey);
    final json = recipe.toJson();
    json['id'] = recipe.id ?? await _nextId();
    entries.add({'dia': dia, 'tipo_comida': tipoComida, 'recipe': json});
    await _writeList(_menuKey, entries);
  }

  @override
  Future<void> clearMenu() async {
    await _writeList(_menuKey, []);
  }
}
