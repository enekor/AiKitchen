import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/recetario_screen.dart';
import 'package:aikitchen/services/recetario_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El recetario llega de un fichero que la app no controla. Si se lee mal, el
/// usuario pierde el vídeo, el canal o directamente las recetas.
void main() {
  Map<String, dynamic> receta({
    String nombre = 'Garbanzos a la carbonara',
    String descripcion =
        'Garbanzos suaves con bacon y mozzarella. - https://www.youtube.com/watch?v=2gsx0TXT0jk',
    String? origen = 'una vasca en la cocina',
    List<String> etiquetas = const ['Legumbres'],
  }) =>
      {
        'nombre': nombre,
        'descripcion': descripcion,
        'tiempoEstimado': '30 min',
        'ingredientes': ['300 g de garbanzos', '100 g de bacon'],
        'preparacion': ['Sofreír', 'Mezclar'],
        'calorias': '320',
        'raciones': '4',
        'origen': ?origen,
        'etiquetas': etiquetas,
      };

  group('Recipe con vídeo y canal', () {
    test('saca el enlace de YouTube y lo quita de la descripción visible', () {
      final r = Recipe.fromJson(receta());
      expect(r.videoUrl, 'https://www.youtube.com/watch?v=2gsx0TXT0jk');
      expect(r.descripcionVisible, 'Garbanzos suaves con bacon y mozzarella.');
      // La original conserva el enlace para favoritos y al compartir.
      expect(r.descripcion, contains('youtube.com'));
    });

    test('reconoce enlaces cortos y de shorts', () {
      Recipe con(String d) => Recipe.fromJson(receta(descripcion: d));
      expect(con('Rico: https://youtu.be/abc123').videoUrl, 'https://youtu.be/abc123');
      expect(
        con('Ver https://youtube.com/shorts/xyz789.').videoUrl,
        'https://youtube.com/shorts/xyz789',
      );
      expect(con('Sin vídeo, ver https://example.com').videoUrl, isNull);
      expect(con('Sin vídeo').descripcionVisible, 'Sin vídeo');
    });

    test('el origen del recetario es el canal y cuenta como web', () {
      final r = Recipe.fromJson(receta());
      expect(r.canal, 'una vasca en la cocina');
      expect(r.origen, RecipeOrigin.web);

      final propia = Recipe.fromJson(receta(origen: 'manual'));
      expect(propia.canal, isNull);
      expect(propia.origen, RecipeOrigin.manual);
    });

    test('conserva el canal al guardar y al compartir', () {
      final r = Recipe.fromJson(receta());
      final porJson = Recipe.fromJson(jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
      expect(porJson.canal, 'una vasca en la cocina');
      expect(porJson.origen, RecipeOrigin.web);
      expect(Recipe.fromMap(r.toMap()).canal, 'una vasca en la cocina');
      expect(r.copyWith(etiquetas: ['x']).canal, 'una vasca en la cocina');
    });
  });

  group('RecetarioService', () {
    test('convierte el enlace normal de GitHub en el descargable', () {
      expect(
        RecetarioService.toRawUrl('https://github.com/enekor/recetas/blob/main/datos/recetas.json'),
        'https://raw.githubusercontent.com/enekor/recetas/main/datos/recetas.json',
      );
      const raw = 'https://raw.githubusercontent.com/enekor/recetas/main/recetas.json';
      expect(RecetarioService.toRawUrl('  $raw '), raw);
    });

    test('lee una lista o un objeto con "recetas", y salta las rotas', () {
      final lista = jsonEncode([receta(), {'nombre': 'rota'}, receta(nombre: 'Lentejas')]);
      final recipes = RecetarioService.parse(lista);
      expect(recipes.map((r) => r.nombre), ['Garbanzos a la carbonara', 'Lentejas']);
      expect(recipes.every((r) => r.id == null && r.origen == RecipeOrigin.web), isTrue);

      final objeto = jsonEncode({'recetas': [receta()]});
      expect(RecetarioService.parse(objeto), hasLength(1));
    });

    test('marca como web aunque falte el origen', () {
      final r = RecetarioService.parse(jsonEncode([receta(origen: null)])).single;
      expect(r.origen, RecipeOrigin.web);
      expect(r.canal, isNull);
    });

    test('da un error claro si el fichero no vale', () {
      expect(
        () => RecetarioService.parse('<html>404</html>'),
        throwsA(isA<RecetarioException>()),
      );
      expect(() => RecetarioService.parse('{"a": 1}'), throwsA(isA<RecetarioException>()));
      expect(
        () => RecetarioService.parse(jsonEncode([{'x': 1}])),
        throwsA(isA<RecetarioException>()),
      );
    });
  });

  group('RecetarioScreen', () {
    final recetas = [
      for (var i = 0; i < 9; i++)
        Recipe.fromJson(receta(
          nombre: 'Receta del recetario número $i con un nombre largo',
          origen: i.isEven ? 'una vasca en la cocina' : 'Otro canal',
          etiquetas: [i.isEven ? 'Legumbres' : 'Pescado'],
        )),
    ];

    Future<void> pintar(WidgetTester tester, Size size, {String url = 'https://x/r.json'}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppSingleton().recetarioUrl.value = url;
      addTearDown(() => AppSingleton().recetarioUrl.value = '');
      await tester.pumpWidget(MaterialApp(
        theme: CookingTheme.lightTheme(),
        home: Scaffold(
          body: RecetarioScreen(loader: (url, {bool refresh = false}) async => recetas),
        ),
      ));
      await tester.pumpAndSettle();
    }

    for (final size in const [Size(1280, 800), Size(800, 1280), Size(390, 844)]) {
      testWidgets('se pinta sin desbordarse a ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pintar(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('9 recetas'), findsOneWidget);
      });
    }

    testWidgets('filtra por canal y por texto', (tester) async {
      await pintar(tester, const Size(1280, 800));
      await tester.tap(find.text('Otro canal').first);
      await tester.pumpAndSettle();
      expect(find.text('4 recetas'), findsOneWidget);

      await tester.tap(find.text('Todas'));
      await tester.enterText(find.byType(TextField), 'número 3');
      await tester.pumpAndSettle();
      expect(find.text('1 receta'), findsOneWidget);
    });

    testWidgets('sin URL invita a configurarla en Ajustes', (tester) async {
      await pintar(tester, const Size(1280, 800), url: '');
      expect(find.text('Sin recetario configurado'), findsOneWidget);
      expect(find.text('Ir a Ajustes'), findsOneWidget);
    });
  });
}
