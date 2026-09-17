/// Lectura de ficheros de texto dependiente de plataforma.
///
/// Debe exponer `readTextFile(String path)`.
library;

export 'text_file_reader_web.dart' if (dart.library.io) 'text_file_reader_io.dart';
