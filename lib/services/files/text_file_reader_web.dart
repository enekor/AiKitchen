/// En navegador no hay rutas de fichero: el selector devuelve los bytes
/// directamente, así que esta vía no debe usarse.
Future<String> readTextFile(String path) async {
  throw UnsupportedError(
    'En navegador no se puede leer por ruta. Usa el contenido en memoria.',
  );
}
