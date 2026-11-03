import 'dart:convert';

import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/utils/pantry_matcher.dart';
import 'package:flutter/foundation.dart';

/// Productos que el usuario tiene en casa. Se guarda como una preferencia más
/// (una lista JSON), así funciona igual en móvil y en navegador sin tocar el
/// esquema de la base de datos.
class PantryService extends ChangeNotifier {
  PantryService._();

  static final PantryService instance = PantryService._();

  List<String> _items = [];
  bool _loaded = false;

  List<String> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    if (_loaded) return;
    String? raw;
    try {
      raw = await SharedPreferencesService.getStringValue(
        SharedPreferencesKeys.despensa,
      );
    } catch (e) {
      // Sin almacenamiento disponible, la despensa empieza vacía.
      debugPrint('No se pudo leer la despensa: $e');
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        _items = List<String>.from(jsonDecode(raw) as List);
      } catch (e) {
        debugPrint('Despensa guardada ilegible, se ignora: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  bool contains(String name) =>
      _items.any((item) => PantryMatcher.sameProduct(item, name));

  /// Si la despensa cubre una línea de ingrediente de una receta.
  bool covers(String ingredient) => PantryMatcher.isCovered(ingredient, _items);

  /// Añade un producto. Devuelve `false` si ya estaba.
  Future<bool> add(String name) async {
    return await addAll([name]) > 0;
  }

  /// Añade varios productos sin repetir. Devuelve cuántos eran nuevos.
  Future<int> addAll(Iterable<String> names) async {
    await load();
    var added = 0;
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || contains(name)) continue;
      _items.add(name[0].toUpperCase() + name.substring(1));
      added++;
    }
    if (added > 0) {
      _sort();
      await _save();
    }
    return added;
  }

  Future<void> remove(String name) async {
    _items.remove(name);
    await _save();
  }

  Future<void> clear() async {
    _items = [];
    await _save();
  }

  void _sort() {
    _items.sort(
      (a, b) => PantryMatcher.normalize(a).compareTo(PantryMatcher.normalize(b)),
    );
  }

  Future<void> _save() async {
    notifyListeners();
    await SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.despensa,
      jsonEncode(_items),
    );
  }
}
