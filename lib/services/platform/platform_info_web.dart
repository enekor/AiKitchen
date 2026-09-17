/// Implementación para navegador. No hay `dart:io` ni sistema operativo local.
bool get isAndroid => false;

bool get isIOS => false;

bool get supportsFileSystem => false;

bool get supportsHomeWidgets => false;

bool get supportsShareIntents => false;

/// En un navegador no se puede cerrar la pestaña por código de forma fiable,
/// así que no se hace nada. Quien llama debe mostrar una pantalla de salida.
void closeApp() {}
