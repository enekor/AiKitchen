import 'dart:async';
import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/recetario_screen.dart';
import 'package:aikitchen/services/recetario/recetario_cache.dart';
import 'package:aikitchen/services/recetario_service.dart';
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
    test('trae fija la URL del recetario de la app', () {
      expect(
        RecetarioService.url,
        'https://raw.githubusercontent.com/enekor/AiKitchen/feat/cocina-asistida/data/recetas/recetas.json',
      );
    });

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

  group('Descarga y copia guardada', () {
    const url = 'https://raw.githubusercontent.com/u/r/main/recetas.json';
    late MemoryRecetarioCache cache;
    late DateTime now;
    late int downloads;
    late String body;
    Completer<void>? gate;

    RecetarioService crear() => RecetarioService(
          cache: cache,
          now: () => now,
          fetch: (uri) async {
            downloads++;
            if (gate != null) await gate!.future;
            if (body == 'ERROR') throw const RecetarioException('Sin conexión');
            return body;
          },
        );

    setUp(() {
      cache = MemoryRecetarioCache();
      now = DateTime(2026, 11, 5, 12);
      downloads = 0;
      body = jsonEncode([receta()]);
      gate = null;
    });

    test('sin copia guardada, descarga y la guarda', () async {
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      await service.refresh(); // se une a la descarga lanzada en segundo plano
      expect(downloads, 1);
      expect(service.recipes, hasLength(1));
      expect(cache.data?.url, url);
      expect(cache.data?.savedAt, now);
    });

    test('con copia reciente, la usa y no descarga', () async {
      cache.data = CachedRecetario(url: url, body: body, savedAt: now.subtract(const Duration(days: 2)));
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      expect(service.recipes, hasLength(1));
      expect(service.isDownloading, isFalse);
      expect(downloads, 0);
    });

    test('con copia vieja, la muestra mientras descarga la nueva', () async {
      cache.data = CachedRecetario(url: url, body: body, savedAt: now.subtract(const Duration(days: 8)));
      body = jsonEncode([receta(), receta(nombre: 'Lentejas')]);
      gate = Completer();
      final service = crear();
      await service.configure(url, const Duration(days: 7));

      // La descarga va en segundo plano: ya se ve la lista guardada.
      expect(service.recipes, hasLength(1));
      expect(service.isDownloading, isTrue);
      expect(service.isManualRefresh, isFalse);

      gate!.complete();
      await service.refresh();
      expect(service.recipes, hasLength(2));
      expect(downloads, 1);
    });

    test('la copia de otra URL no se usa', () async {
      cache.data = CachedRecetario(url: 'https://otra/url.json', body: body, savedAt: now);
      gate = Completer();
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      expect(service.recipes, isNull);
      expect(service.isDownloading, isTrue);
      gate!.complete();
      await service.refresh();
      expect(service.recipes, hasLength(1));
    });

    test('al actualizar a mano se marca como manual hasta que termina', () async {
      cache.data = CachedRecetario(url: url, body: body, savedAt: now);
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      gate = Completer();
      final future = service.refresh(manual: true);
      expect(service.isManualRefresh, isTrue);
      gate!.complete();
      await future;
      expect(service.isManualRefresh, isFalse);
      expect(downloads, 1);
    });

    test('si falla la descarga, se queda la lista que había', () async {
      final viejo = now.subtract(const Duration(days: 30));
      cache.data = CachedRecetario(url: url, body: body, savedAt: viejo);
      body = 'ERROR';
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      await service.refresh(manual: true);
      expect(service.recipes, hasLength(1));
      expect(service.error, 'Sin conexión');
      expect(cache.data!.savedAt, viejo);
    });

    test('un fichero roto no sustituye a la lista buena', () async {
      cache.data = CachedRecetario(url: url, body: body, savedAt: now);
      body = '<html>no es json</html>';
      final service = crear();
      await service.configure(url, const Duration(days: 7));
      await service.refresh(manual: true);
      expect(service.recipes, hasLength(1));
      expect(service.error, isNotNull);
      expect(cache.data!.body, isNot(contains('html')));
    });
  });

  group('RecetarioScreen', () {
    final recetas = [
      for (var i = 0; i < 9; i++)
        receta(
          nombre: 'Receta del recetario número $i con un nombre largo',
          origen: i.isEven ? 'una vasca en la cocina' : 'Otro canal',
          etiquetas: [i.isEven ? 'Legumbres' : 'Pescado'],
        ),
    ];
    const url = 'https://raw.githubusercontent.com/u/r/main/recetas.json';

    Future<RecetarioService> pintar(
      WidgetTester tester,
      Size size, {
      Completer<void>? gate,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cache = MemoryRecetarioCache()
        ..data = CachedRecetario(url: url, body: jsonEncode(recetas), savedAt: DateTime.now());
      final service = RecetarioService(
        cache: cache,
        fetch: (uri) async {
          if (gate != null) await gate.future;
          return jsonEncode([...recetas, receta(nombre: 'Receta nueva')]);
        },
      );
      await service.configure(url, const Duration(days: 7));
      await tester.pumpWidget(MaterialApp(
        theme: CookingTheme.lightTheme(),
        home: Scaffold(body: RecetarioScreen(service: service)),
      ));
      await tester.pumpAndSettle();
      return service;
    }

    for (final size in const [Size(1280, 800), Size(800, 1280), Size(390, 844)]) {
      testWidgets('se pinta sin desbordarse a ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pintar(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('9 recetas'), findsOneWidget);
        expect(find.textContaining('actualizado hoy'), findsOneWidget);
      });
    }

    testWidgets('filtra por canal y por texto', (tester) async {
      await pintar(tester, const Size(1280, 800));
      await tester.tap(find.text('Otro canal').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('4 recetas'), findsOneWidget);

      await tester.tap(find.text('Todas'));
      await tester.enterText(find.byType(TextField), 'número 3');
      await tester.pumpAndSettle();
      expect(find.textContaining('1 receta'), findsOneWidget);
    });

    testWidgets('Actualizar muestra un spinner y luego la lista nueva', (tester) async {
      final gate = Completer<void>();
      await pintar(tester, const Size(1280, 800), gate: gate);

      await tester.tap(find.text('Actualizar'));
      await tester.pump();
      expect(find.text('Actualizando...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Mientras tanto se sigue viendo la lista anterior.
      expect(find.textContaining('9 recetas'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('10 recetas'), findsOneWidget);
      expect(find.text('Receta nueva'), findsOneWidget);
    });

  });
}
