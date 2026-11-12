import 'package:shared_preferences/shared_preferences.dart';

import 'recetario_cache.dart';

RecetarioCache createCache() => _WebRecetarioCache();

/// Guarda el recetario en el almacenamiento del navegador. Tiene unos 5 MB
/// compartidos con los favoritos; si no cabe, la escritura falla y la app
/// sigue con la lista en memoria.
class _WebRecetarioCache implements RecetarioCache {
  static const _url = 'aik.recetario.url';
  static const _body = 'aik.recetario.body';
  static const _savedAt = 'aik.recetario.savedAt';

  @override
  Future<CachedRecetario?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_url);
    final body = prefs.getString(_body);
    final savedAt = prefs.getInt(_savedAt);
    if (url == null || body == null || savedAt == null) return null;
    return CachedRecetario(
      url: url,
      body: body,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
  }

  @override
  Future<void> write(CachedRecetario value) async {
    final prefs = await SharedPreferences.getInstance();
    // Primero se borra la copia anterior para dejar sitio a la nueva.
    await prefs.remove(_body);
    await prefs.setString(_url, value.url);
    await prefs.setString(_body, value.body);
    await prefs.setInt(_savedAt, value.savedAt.millisecondsSinceEpoch);
  }
}
