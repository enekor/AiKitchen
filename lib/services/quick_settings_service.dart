import 'package:aikitchen/services/platform/platform_info.dart' as platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Botón de la lista de la compra en el panel de ajustes rápidos, junto al wifi
/// y el bluetooth.
class QuickSettingsService {
  static const MethodChannel _channel = MethodChannel(
    'aikitchen/quick_settings',
  );

  /// El panel de ajustes rápidos solo existe en Android.
  static bool get isAvailable => platform.isAndroid;

  /// Abre el diálogo del sistema para colocar el botón: Android no permite
  /// añadirlo sin que el usuario lo confirme.
  ///
  /// Devuelve `true` si al terminar el botón está en el panel, tanto si se
  /// acaba de añadir como si ya estaba.
  static Future<bool> requestAddTile() async {
    if (!isAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('requestAddTile') ?? false;
    } on PlatformException catch (e) {
      debugPrint('No se pudo pedir el botón de ajustes rápidos: $e');
      return false;
    }
  }
}
