import 'recetario_cache_web.dart' if (dart.library.io) 'recetario_cache_io.dart' as impl;

/// Última descarga del recetario guardada en el dispositivo.
class CachedRecetario {
  const CachedRecetario({
    required this.url,
    required this.body,
    required this.savedAt,
  });

  final String url;
  final String body;
  final DateTime savedAt;
}

/// Dónde se guarda la última descarga: un fichero en móvil y escritorio, el
/// almacenamiento del navegador en web.
abstract class RecetarioCache {
  Future<CachedRecetario?> read();
  Future<void> write(CachedRecetario data);
}

RecetarioCache createRecetarioCache() => impl.createCache();

/// Caché en memoria, para pruebas.
class MemoryRecetarioCache implements RecetarioCache {
  CachedRecetario? data;

  @override
  Future<CachedRecetario?> read() async => data;

  @override
  Future<void> write(CachedRecetario value) async => data = value;
}
