import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/ai_json.dart';
import 'package:aikitchen/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Todas las pantallas de IA leen la respuesta como JSON. Si este extractor
/// deja pasar texto de más, o da por buena una respuesta cortada, el usuario
/// ve "error en el JSON" o, peor, una receta a medias sin aviso.
void main() {
  const receta =
      '{"recetas":[{"nombre":"Tortilla","descripcion":"Clásica","tiempoEstimado":"30 min",'
      '"calorias":400,"raciones":4,"ingredientes":["huevos","patatas"],'
      '"preparacion":["Freír","Cuajar"]}]}';

  group('AiJson.extract', () {
    test('deja tal cual un JSON limpio', () {
      expect(jsonDecode(AiJson.extract(receta)), jsonDecode(receta));
    });

    test('quita texto alrededor y bloques de código', () {
      final raw = 'Claro, aquí tienes la receta:\n```json\n$receta\n```\n¡Que aproveche!';
      final recipes = Recipe.fromJsonList(AiJson.extract(raw));
      expect(recipes.single.nombre, 'Tortilla');
    });

    test('ignora el razonamiento entre etiquetas think', () {
      final raw = '<think>Voy a pensar {"nombre": "no"} un poco</think>$receta';
      expect(Recipe.fromJsonList(AiJson.extract(raw)).single.nombre, 'Tortilla');
    });

    test('se queda con el primero si el JSON viene repetido', () {
      final otra = receta.replaceAll('Tortilla', 'Gazpacho');
      final raw = '$receta\n$otra';
      expect(Recipe.fromJsonList(AiJson.extract(raw)).single.nombre, 'Tortilla');
    });

    test('respeta llaves y comillas dentro de las cadenas', () {
      const raw = '{"recetas":[{"nombre":"Salsa {secreta} \\"de la casa\\"",'
          '"descripcion":"]","tiempoEstimado":"5 min","calorias":1,"raciones":1,'
          '"ingredientes":["a"],"preparacion":["b"]}]}';
      expect(
        Recipe.fromJsonList(AiJson.extract(raw)).single.nombre,
        'Salsa {secreta} "de la casa"',
      );
    });

    test('detecta una respuesta cortada en vez de devolver un trozo', () {
      final cortada = receta.substring(0, receta.length - 20);
      expect(
        () => AiJson.extract(cortada),
        throwsA(isA<AiJsonException>().having((e) => e.truncated, 'truncated', isTrue)),
      );
    });

    test('distingue basura de un JSON cortado', () {
      expect(
        () => AiJson.extract('Lo siento, no puedo ayudarte con eso.'),
        throwsA(isA<AiJsonException>().having((e) => e.truncated, 'truncated', isFalse)),
      );
    });

    test('no confunde un [1] del texto con la respuesta', () {
      final raw = 'Paso [1] completado. $receta';
      expect(Recipe.fromJsonList(AiJson.extract(raw)).single.nombre, 'Tortilla');
    });

    test('salta un bloque mal formado y encuentra el bueno', () {
      final raw = '{esto no es json} $receta';
      expect(Recipe.fromJsonList(AiJson.extract(raw)).single.nombre, 'Tortilla');
    });

    test('acepta una lista de objetos', () {
      const raw = 'Resultado: [{"nombre":"a"},{"nombre":"b"}] fin';
      expect(jsonDecode(AiJson.extract(raw)), hasLength(2));
    });
  });

  group('AiService', () {
    test('usa siempre el modelo más barato de cada proveedor', () {
      expect(AiService.effectiveModel('groq'), 'openai/gpt-oss-20b');
      expect(AiService.effectiveModel('gemini'), 'gemini-2.5-flash-lite');
      expect(AiService.effectiveModel('openai'), 'gpt-6-luna');
      expect(AiService.effectiveModel('anthropic'), 'claude-haiku-5-5');
      expect(AiService.effectiveModel('Gemini'), 'gemini-2.5-flash-lite');
    });

    test('deja sitio para cinco recetas', () {
      // Cinco recetas son unos 3.000-4.000 tokens de salida.
      for (final provider in AiService.providerModel.keys) {
        expect(AiService.maxOutputTokens(provider), greaterThanOrEqualTo(6000));
      }
      // Groq cuenta la salida pedida contra su límite de tokens por minuto.
      expect(AiService.maxOutputTokens('groq'), lessThanOrEqualTo(6144));
    });

    test('prefiere los proveedores con cuota gratuita', () {
      expect(AiService.freeTierProviders, ['gemini', 'groq']);
      expect(AiService.hasFreeTier('Gemini'), isTrue);
      expect(AiService.hasFreeTier('openai'), isFalse);
      expect(AiService.hasFreeTier('anthropic'), isFalse);
    });
  });
}
