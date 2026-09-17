import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Comparte la receta en navegador sin tocar el disco.
///
/// Se intenta primero la Web Share API con fichero adjunto, que solo soportan
/// algunos navegadores. Si falla, se comparte el contenido como texto, que es
/// universal y sigue siendo útil para el usuario.
Future<void> shareRecipeFile(
  String fileName,
  String contents,
  String text,
) async {
  final bytes = utf8.encode(contents);

  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: 'application/vnd.aikitchen.recipe',
          ),
        ],
        subject: 'Recetas de AiKitchen',
        text: text,
      ),
    );
  } catch (_) {
    await SharePlus.instance.share(
      ShareParams(subject: 'Recetas de AiKitchen', text: '$text\n\n$contents'),
    );
  }
}
