import 'dart:io';

/// Plataformas con `dart:io` disponible (Android, iOS, escritorio).
bool get isAndroid => Platform.isAndroid;

bool get isIOS => Platform.isIOS;

/// En móvil las funciones que dependen de ficheros y de widgets de sistema
/// están disponibles.
bool get supportsFileSystem => true;

bool get supportsHomeWidgets => Platform.isAndroid;

bool get supportsShareIntents => Platform.isAndroid || Platform.isIOS;

/// Cierra la aplicación. En móvil termina el proceso.
void closeApp() => exit(0);
