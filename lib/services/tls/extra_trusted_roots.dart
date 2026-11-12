/// Certificados raíz que la app añade a los del sistema.
///
/// En web no hay nada que hacer (el navegador gestiona TLS) y `dart:io` no
/// existe, así que la implementación se elige en tiempo de compilación.
library;

export 'extra_trusted_roots_web.dart'
    if (dart.library.io) 'extra_trusted_roots_io.dart';
