import 'dart:convert';

import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

/// El almacenamiento en navegador guarda las recetas como JSON, así que el
/// viaje de ida y vuelta por `toJson`/`fromJson` tiene que conservarlo todo.
/// Si se rompe, se pierden los favoritos del usuario en silencio.
void main() {
  final receta = Recipe(
    id: 7,
    nombre: 'Tortilla de patatas',
    descripcion: 'La de siempre',
    tiempoEstimado: '30 min',
    ingredientes: const ['patatas', 'huevos', 'cebolla'],
    preparacion: const ['Pelar', 'Freír', 'Cuajar'],
    calorias: '450',
    raciones: '4',
  );

  group('Recipe', () {
    test('conserva todos los campos al pasar por JSON', () {
      final copia = Recipe.fromJson(
        jsonDecode(jsonEncode(receta.toJson())) as Map<String, dynamic>,
      );

      expect(copia.id, receta.id);
      expect(copia.nombre, receta.nombre);
      expect(copia.descripcion, receta.descripcion);
      expect(copia.tiempoEstimado, receta.tiempoEstimado);
      expect(copia.ingredientes, receta.ingredientes);
      expect(copia.preparacion, receta.preparacion);
      expect(copia.calorias, receta.calorias);
      expect(copia.raciones, receta.raciones);
    });

    test('omite el id cuando la receta aún no se ha guardado', () {
      final sinGuardar = Recipe(
        nombre: 'Nueva',
        descripcion: '',
        tiempoEstimado: '5 min',
        ingredientes: const [],
        preparacion: const [],
        calorias: '0',
        raciones: '1',
      );

      expect(sinGuardar.toJson().containsKey('id'), isFalse);
    });

    test('lee una lista suelta de recetas', () {
      final lista = Recipe.fromJsonList(jsonEncode([receta.toJson()]));

      expect(lista, hasLength(1));
      expect(lista.first.nombre, receta.nombre);
    });

    test('lee la respuesta envuelta que devuelve la IA', () {
      final envuelta = jsonEncode({
        'status': 'ok',
        'response': {
          'recetas': [receta.toJson()],
        },
      });

      final lista = Recipe.fromJsonList(envuelta);

      expect(lista, hasLength(1));
      expect(lista.first.ingredientes, receta.ingredientes);
    });

    test('avisa si el JSON no contiene ninguna lista de recetas', () {
      expect(
        () => Recipe.fromJsonList(jsonEncode({'algo': 'otra cosa'})),
        throwsException,
      );
    });
  });

  group('CartItem', () {
    test('conserva el estado de comprado al pasar por JSON', () {
      final item = CartItem(id: 3, name: 'Leche', isPurchased: true);
      final copia = CartItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );

      expect(copia.id, 3);
      expect(copia.name, 'Leche');
      expect(copia.isPurchased, isTrue);
    });

    test('un artículo nuevo empieza sin comprar', () {
      expect(CartItem(name: 'Pan').isPurchased, isFalse);
    });
  });
}
