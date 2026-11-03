import 'dart:convert';

import 'package:aikitchen/services/platform/platform_info.dart' as platform;
import 'package:aikitchen/widgets/toaster.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

/// Fotos de platos para las recetas favoritas.
///
/// La foto va dentro del JSON de la receta, para que viaje con ella al
/// compartirla, así que se reduce y se recomprime antes de guardarla: una foto
/// de móvil de varios megas no cabría en el almacenamiento del navegador ni
/// en un fichero .aikr razonable.
class RecipePhotoService {
  const RecipePhotoService._();

  /// Lado mayor de la foto guardada, en píxeles. Suficiente para la cabecera
  /// de la receta y las tarjetas, con un peso de unas decenas de KB.
  static const int maxSide = 900;
  static const int jpegQuality = 72;

  /// Abre el selector de imágenes y devuelve la foto lista para guardar, o
  /// `null` si el usuario cancela o la imagen no se puede leer.
  static Future<String?> pickPhoto() async {
    if (!await _ensurePermission()) return null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      Toaster.showError('No se ha podido leer la imagen');
      return null;
    }

    // En móvil se procesa fuera del hilo de la interfaz; en web `compute`
    // corre en el mismo hilo, pero la imagen ya llega reducida a menudo.
    final encoded = await compute(compressToBase64, bytes);
    if (encoded == null) {
      Toaster.showError('Ese archivo no parece una imagen válida');
    }
    return encoded;
  }

  /// Reduce la imagen a [maxSide] por su lado mayor, respeta la orientación
  /// de la cámara y la guarda como JPEG en base64.
  static String? compressToBase64(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average)
          : img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
    }

    final jpeg = img.encodeJpg(image, quality: jpegQuality);
    return base64Encode(jpeg);
  }

  /// En Android anterior a la 13 hace falta permiso de almacenamiento para
  /// abrir la galería con el selector de archivos.
  static Future<bool> _ensurePermission() async {
    if (!platform.isAndroid) return true;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt >= 33) return true;
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Toaster.showWarning('Hace falta permiso para leer tus fotos');
        return false;
      }
    } catch (e) {
      debugPrint('No se pudo comprobar el permiso de fotos: $e');
    }
    return true;
  }
}
