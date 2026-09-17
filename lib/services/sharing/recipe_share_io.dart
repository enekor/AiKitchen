import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Escribe la receta en un fichero temporal y lanza el diálogo del sistema.
Future<void> shareRecipeFile(
  String fileName,
  String contents,
  String text,
) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsString(contents);

  // El MIME propio hace que el sistema vincule el fichero con la app.
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/vnd.aikitchen.recipe')],
      subject: 'Recetas de AiKitchen',
      text: text,
    ),
  );
}
