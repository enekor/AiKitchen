/// Almacén de registros dependiente de plataforma.
///
/// Debe exponer `LogStore` con `initialize`, `append`, `read` y `clear`.
library;

export 'log_store_web.dart' if (dart.library.io) 'log_store_io.dart';
