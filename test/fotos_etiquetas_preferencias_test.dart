import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/tipo_receta.dart';
import 'package:aikitchen/services/recipe_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// La foto y las etiquetas viajan dentro del JSON de la receta (almacén web y
/// ficheros .aikr) y en columnas nuevas de SQLite. Si algo de esto se rompe,
/// se pierden en silencio al guardar o al compartir.
void main() {
  // 1x1 píxel en JPEG, en base64: basta para comprobar el viaje de ida y vuelta.
  final fotoMinima = RecipePhotoService.compressToBase64(
    img.encodePng(img.Image(width: 1, height: 1)),
  )!;

  Recipe receta({String? foto, List<String> etiquetas = const []}) => Recipe(
    id: 3,
    nombre: 'Tortilla',
    descripcion: 'De patatas',
    tiempoEstimado: '30 min',
    ingredientes: const ['huevos', 'patatas'],
    preparacion: const ['Freír', 'Cuajar'],
    calorias: '400',
    raciones: '4',
    foto: foto,
    etiquetas: etiquetas,
  );

  group('Recipe con foto y etiquetas', () {
    test('conserva foto y etiquetas al pasar por JSON', () {
      final original = receta(foto: fotoMinima, etiquetas: ['Táper', 'Cenas rápidas']);
      final copia = Recipe.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(copia.foto, fotoMinima);
      expect(copia.etiquetas, ['Táper', 'Cenas rápidas']);
      expect(copia.fotoBytes, isNotNull);
    });

    test('conserva foto y etiquetas al pasar por SQLite', () {
      final original = receta(foto: fotoMinima, etiquetas: ['Fiestas']);
      final copia = Recipe.fromMap(original.toMap());
      expect(copia.foto, fotoMinima);
      expect(copia.etiquetas, ['Fiestas']);
    });

    test('lee recetas antiguas sin foto ni etiquetas', () {
      final antigua = Recipe.fromJson({
        'nombre': 'Gazpacho',
        'descripcion': '',
        'tiempoEstimado': '10 min',
        'ingredientes': ['tomate'],
        'preparacion': ['Triturar'],
        'calorias': 100,
        'raciones': 2,
      });
      expect(antigua.tieneFoto, isFalse);
      expect(antigua.fotoBytes, isNull);
      expect(antigua.etiquetas, isEmpty);

      final map = receta().toMap()
        ..remove('foto')
        ..remove('etiquetas');
      expect(Recipe.fromMap(map).etiquetas, isEmpty);
    });

    test('no manda la foto a la IA', () {
      final json = receta(foto: fotoMinima).toJson(includeFoto: false);
      expect(json.containsKey('foto'), isFalse);
    });

    test('omite los campos vacíos en el JSON compartido', () {
      final json = receta().toJson();
      expect(json.containsKey('foto'), isFalse);
      expect(json.containsKey('etiquetas'), isFalse);
    });

    test('copyWith cambia o quita la foto sin tocar lo demás', () {
      final conFoto = receta(etiquetas: ['Postres']).copyWith(foto: fotoMinima);
      expect(conFoto.foto, fotoMinima);
      expect(conFoto.etiquetas, ['Postres']);
      expect(conFoto.id, 3);

      final sinFoto = conFoto.copyWith(sinFoto: true);
      expect(sinFoto.tieneFoto, isFalse);
      expect(sinFoto.etiquetas, ['Postres']);
    });

    test('una foto dañada no rompe la tarjeta', () {
      expect(receta(foto: '%%no es base64%%').fotoBytes, isNull);
    });
  });

  group('Preferencias de cocina', () {
    test('lee el valor único de versiones anteriores', () {
      expect(TipoReceta.parseList('vegana'), [TipoReceta.vegana]);
      expect(
        TipoReceta.parseList('sin_gluten'),
        [TipoReceta.omnivora, TipoReceta.sin_gluten],
      );
      expect(TipoReceta.parseList(''), [TipoReceta.omnivora]);
      expect(TipoReceta.parseList('inventada'), [TipoReceta.omnivora]);
    });

    test('combina una dieta con varias restricciones', () {
      final tipos = TipoReceta.parseList('sin_lactosa, vegetariana ,sin_gluten');
      expect(tipos, [
        TipoReceta.vegetariana,
        TipoReceta.sin_gluten,
        TipoReceta.sin_lactosa,
      ]);
      expect(TipoReceta.parseList(TipoReceta.toStored(tipos)), tipos);
    });

    test('genera texto legible para los prompts', () {
      expect(
        TipoReceta.promptText('vegetariana,sin_gluten,sin_frutosSecos'),
        'Vegetariana, Sin gluten, Sin frutos secos',
      );
      expect(TipoReceta.promptText('omnivora'), 'Omnívora');
    });

    test('sabe si el usuario ha personalizado algo', () {
      expect(TipoReceta.isCustomized('omnivora'), isFalse);
      expect(TipoReceta.isCustomized(''), isFalse);
      expect(TipoReceta.isCustomized('vegana'), isTrue);
      expect(TipoReceta.isCustomized('omnivora,sin_huevo'), isTrue);
    });

    test('separa dietas de restricciones', () {
      expect(TipoReceta.dietas.every((t) => t.isDiet), isTrue);
      expect(TipoReceta.restricciones.any((t) => t.isDiet), isFalse);
      expect(
        TipoReceta.dietas.length + TipoReceta.restricciones.length,
        TipoReceta.values.length,
      );
    });
  });

  group('RecipePhotoService', () {
    test('reduce las fotos grandes y las guarda como JPEG', () {
      final grande = img.Image(width: 2400, height: 1200);
      final encoded = RecipePhotoService.compressToBase64(img.encodePng(grande));
      expect(encoded, isNotNull);

      final decoded = img.decodeJpg(base64Decode(encoded!));
      expect(decoded, isNotNull);
      expect(decoded!.width, RecipePhotoService.maxSide);
      expect(decoded.height, RecipePhotoService.maxSide ~/ 2);
    });

    test('no amplía las fotos pequeñas', () {
      final pequena = img.Image(width: 300, height: 400);
      final encoded = RecipePhotoService.compressToBase64(img.encodePng(pequena))!;
      final decoded = img.decodeJpg(base64Decode(encoded))!;
      expect(decoded.width, 300);
      expect(decoded.height, 400);
    });

    test('rechaza lo que no es una imagen', () {
      expect(
        RecipePhotoService.compressToBase64(utf8.encode('no soy una foto')),
        isNull,
      );
    });
  });
}
