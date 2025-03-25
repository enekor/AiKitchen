import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:aikitchen/models/recipe.dart';
import 'package:share_plus/share_plus.dart';

class FileHandler {
  static StreamSubscription? _intentDataStreamSubscription;

  static void initFileHandler(BuildContext context) {
    // Para cuando la app es abierta desde el archivo
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> files) {
            _handleIncomingFiles(context, files);
          },
          onError: (err) {
            debugPrint("Error al recibir archivo: $err");
          },
        );

    // Para cuando la app ya está abierta y recibe un archivo
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> files,
    ) {
      _handleIncomingFiles(context, files);
    });
  }

  static void dispose() {
    _intentDataStreamSubscription?.cancel();
  }

  static Future<void> _handleIncomingFiles(
    BuildContext context,
    List<SharedMediaFile> files,
  ) async {
    if (files.isEmpty) return;

    final file = files.first;
    if (file.type == SharedMediaType.file) {
      try {
        // Copiamos el archivo a nuestro directorio para tener acceso persistente
        final tempDir = await getTemporaryDirectory();
        final fileName = path.basename(file.path);
        final localFile = File('${tempDir.path}/$fileName');

        // Leer el archivo original y escribir en nuestro directorio
        final fileBytes = await File(file.path).readAsBytes();
        await localFile.writeAsBytes(fileBytes);

        // Procesar el archivo
        final content = await localFile.readAsString();
        final recipe = _parseRecipe(content);

        if (recipe != null) {
          _showImportDialog(context, recipe);
        }
      } catch (e) {
        debugPrint('Error procesando archivo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar el archivo')),
        );
      }
    }
  }

  static Recipe? _parseRecipe(String content) {
    try {
      final json = jsonDecode(content);
      return Recipe.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing recipe: $e');
      return null;
    }
  }

  static void _showImportDialog(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Receta Importada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Deseas guardar "${recipe.nombre}" en tus favoritos?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  recipe.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveToFavorites(recipe);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${recipe.nombre}" guardada en favoritos'),
                    ),
                  );
                },
                child: const Text('Guardar en Favoritos'),
              ),
            ],
          ),
    );
  }

  static Future<void> _saveToFavorites(Recipe recipe) async {
    if (AppSingleton().recetasFavoritas.contains(recipe)) {
      AppSingleton().recetasFavoritas.remove(recipe);
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
    }

    AppSingleton().setFavRecipes();
  }

  static Future<void> exportRecipe(Recipe recipe) async {
    try {
      // 1. Convertir la receta a JSON
      final jsonStr = jsonEncode(recipe.toJson());

      // 2. Crear archivo temporal
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${recipe.nombre.replaceAll(' ', '_')}.aikr',
      );
      await file.writeAsString(jsonStr);

      // 3. Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Receta: ${recipe.nombre}',
        subject: 'Compartir receta ${recipe.nombre}',
      );

      // 4. Opcional: Eliminar el archivo después de compartir
      // await file.delete();
    } on PlatformException catch (e) {
      debugPrint('Error al exportar: ${e.message}');
      throw Exception('Error al exportar la receta');
    }
  }
}
