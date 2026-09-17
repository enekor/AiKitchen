import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre un enlace fuera de la aplicación.
///
/// En navegador, `LaunchMode.externalApplication` se ignora y el enlace se
/// abre en la misma pestaña, lo que echa al usuario de la aplicación. Se
/// fuerza una pestaña nueva para que no pierda lo que estaba haciendo.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  if (kIsWeb) {
    return launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
