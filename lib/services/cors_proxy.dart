import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:flutter/foundation.dart';

/// Reenvío de peticiones a través de un proxy para saltar CORS en navegador.
///
/// Un navegador bloquea cualquier lectura de `recetas.lidl.es`, `cookpad.com`
/// o de la URL que teclee el usuario, porque esos servidores no envían
/// `Access-Control-Allow-Origin`. No es un fallo de la app y no se puede
/// arreglar desde el cliente: hace falta un intermediario que sí lo envíe.
///
/// En móvil no aplica ninguna restricción, así que el proxy se ignora.
class CorsProxy {
  /// Proxy público usado por defecto. Sirve para que la app funcione nada más
  /// abrirla, pero es un servicio de terceros: puede tener cortes o límites de
  /// uso. Para algo estable conviene poner uno propio desde Ajustes.
  static const String defaultTemplate =
      'https://api.allorigins.win/raw?url={url}';

  static String _template = defaultTemplate;
  static bool _enabled = true;

  static String get template => _template;
  static bool get enabled => _enabled;

  /// Indica si las peticiones a dominios externos necesitan pasar por proxy.
  static bool get isRequired => kIsWeb;

  /// Carga la configuración guardada por el usuario.
  static Future<void> load() async {
    final stored = await SharedPreferencesService.getStringValue(
      SharedPreferencesKeys.corsProxy,
    );
    if (stored == null) return;

    if (stored.isEmpty) {
      // Cadena vacía guardada a propósito: el usuario ha desactivado el proxy.
      _enabled = false;
      return;
    }
    _enabled = true;
    _template = stored;
  }

  /// Guarda una plantilla de proxy. Debe contener el marcador `{url}`.
  ///
  /// Una plantilla vacía desactiva el proxy.
  static Future<void> save(String value) async {
    final trimmed = value.trim();
    _enabled = trimmed.isNotEmpty;
    _template = trimmed.isEmpty ? defaultTemplate : trimmed;
    await SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.corsProxy,
      trimmed,
    );
  }

  /// Devuelve la URL por la que hay que pedir realmente [target].
  ///
  /// En móvil, o con el proxy desactivado, devuelve la original sin tocarla.
  static Uri wrap(Uri target) {
    if (!isRequired || !_enabled) return target;
    if (!_template.contains('{url}')) return target;

    final encoded = Uri.encodeComponent(target.toString());
    return Uri.parse(_template.replaceAll('{url}', encoded));
  }

  /// Mensaje para el usuario cuando una petición externa falla en navegador.
  static String get failureHint => kIsWeb
      ? 'El navegador bloquea las peticiones a webs externas. '
            'Revisa el proxy configurado en Ajustes.'
      : 'No se ha podido conectar con la web de recetas.';
}
