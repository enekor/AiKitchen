import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'recetario_cache.dart';

RecetarioCache createCache() => _FileRecetarioCache();

/// Guarda el recetario en un fichero de la app. Con fotos ocupa casi un mega,
/// demasiado para la base de datos de preferencias.
class _FileRecetarioCache implements RecetarioCache {
  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/recetario_cache.json');
  }

  @override
  Future<CachedRecetario?> read() async {
    final file = await _file;
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return CachedRecetario(
      url: data['url'] as String,
      body: data['body'] as String,
      savedAt: DateTime.fromMillisecondsSinceEpoch(data['savedAt'] as int),
    );
  }

  @override
  Future<void> write(CachedRecetario value) async {
    final file = await _file;
    // Se escribe en un temporal y se renombra: si la app se cierra a mitad,
    // la copia anterior sigue intacta.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode({
      'url': value.url,
      'body': value.body,
      'savedAt': value.savedAt.millisecondsSinceEpoch,
    }));
    await tmp.rename(file.path);
  }
}
