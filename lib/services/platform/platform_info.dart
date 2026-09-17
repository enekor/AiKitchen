/// Información de plataforma sin importar `dart:io`.
///
/// Importar `dart:io` directamente desde `lib/` rompe la compilación web,
/// aunque el código esté protegido en tiempo de ejecución por `kIsWeb`.
/// El compilador rechaza el import antes de mirar las guardas.
library;

export 'platform_info_web.dart'
    if (dart.library.io) 'platform_info_io.dart';
