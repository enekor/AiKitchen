import 'package:aikitchen/services/kitchen_timers.dart';
import 'package:aikitchen/utils/ingredient_scaler.dart';
import 'package:aikitchen/utils/pantry_matcher.dart';
import 'package:aikitchen/utils/step_durations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lógica local del modo cocina, las raciones y la despensa. Todo funciona sin
/// IA, así que si algo de esto falla el usuario ve cantidades o avisos
/// equivocados sin ninguna pista de por qué.
void main() {
  group('IngredientScaler', () {
    test('lee las raciones de partida', () {
      expect(IngredientScaler.baseServings('4'), 4);
      expect(IngredientScaler.baseServings('4 personas'), 4);
      expect(IngredientScaler.baseServings('al gusto'), isNull);
      expect(IngredientScaler.baseServings('0'), isNull);
    });

    test('multiplica la primera cantidad de la línea', () {
      expect(IngredientScaler.scale('200 g de harina', 2), '400 g de harina');
      expect(IngredientScaler.scale('200g de harina', 1.5), '300g de harina');
      expect(IngredientScaler.scale('2 huevos', 0.5), '1 huevos');
      expect(IngredientScaler.scale('Harina (300 g)', 2), 'Harina (600 g)');
    });

    test('entiende fracciones, decimales y rangos', () {
      expect(IngredientScaler.scale('1/2 cucharadita de sal', 2), '1 cucharadita de sal');
      expect(IngredientScaler.scale('1 1/2 tazas de leche', 2), '3 tazas de leche');
      expect(IngredientScaler.scale('½ cebolla', 3), '1 1/2 cebolla');
      expect(IngredientScaler.scale('1,5 l de caldo', 2), '3 l de caldo');
      expect(IngredientScaler.scale('2-3 dientes de ajo', 2), '4-6 dientes de ajo');
      expect(IngredientScaler.scale('2 a 3 cucharadas', 2), '4 a 6 cucharadas');
      expect(IngredientScaler.scale('1.000 g de patatas', 0.5), '500 g de patatas');
    });

    test('no toca lo que no es una cantidad', () {
      expect(IngredientScaler.scale('Sal al gusto', 2), 'Sal al gusto');
      expect(IngredientScaler.scale('una cebolla', 2), 'una cebolla');
      expect(IngredientScaler.scale('Chocolate 70 %', 2), 'Chocolate 70 %');
      expect(IngredientScaler.scale('Harina T45', 2), 'Harina T45');
      expect(IngredientScaler.scale('200 g de harina', 1), '200 g de harina');
    });

    test('escribe las cantidades como en una receta', () {
      expect(IngredientScaler.format(0.5), '1/2');
      expect(IngredientScaler.format(0.25), '1/4');
      expect(IngredientScaler.format(1.333), '1 1/3');
      expect(IngredientScaler.format(2.0), '2');
      expect(IngredientScaler.format(1.4), '1,4');
      expect(IngredientScaler.format(166.67), '167');
    });
  });

  group('StepDurations', () {
    List<Duration> durations(String text) =>
        StepDurations.find(text).map((d) => d.duration).toList();

    test('encuentra minutos, horas y segundos', () {
      expect(durations('Hornea 20 minutos a 180 grados.'), [const Duration(minutes: 20)]);
      expect(durations('Cuece 1 h 30 min.'), [const Duration(hours: 1, minutes: 30)]);
      expect(durations('Deja reposar 2 horas y 15 minutos'), [const Duration(hours: 2, minutes: 15)]);
      expect(durations('Bate 30 segundos'), [const Duration(seconds: 30)]);
      expect(durations('Cocina 1,5 horas'), [const Duration(minutes: 90)]);
    });

    test('entiende expresiones con palabras', () {
      expect(durations('Deja reposar media hora'), [const Duration(minutes: 30)]);
      expect(durations('Cuece una hora y media'), [const Duration(minutes: 90)]);
      expect(durations('Espera un cuarto de hora'), [const Duration(minutes: 15)]);
      expect(durations('Fríe dos minutos por cada lado'), [const Duration(minutes: 2)]);
    });

    test('toma el menor de un rango y no repite', () {
      expect(durations('Hornea 15-20 minutos'), [const Duration(minutes: 15)]);
      expect(durations('Cuece de 10 a 12 minutos'), [const Duration(minutes: 10)]);
      expect(
        durations('Dora 5 minutos, añade el arroz y cuece 18 minutos. Reposa 5 minutos.'),
        [const Duration(minutes: 5), const Duration(minutes: 18)],
      );
    });

    test('no confunde cantidades con tiempos', () {
      expect(durations('Añade 2 huevos y 200 g de harina'), isEmpty);
      expect(durations('Corta 4 manzanas'), isEmpty);
      expect(durations('Añade 2 más'), isEmpty);
    });

    test('formatea duraciones y cuentas atrás', () {
      expect(formatDuration(const Duration(minutes: 90)), '1 h 30 min');
      expect(formatDuration(const Duration(seconds: 45)), '45 s');
      expect(formatCountdown(const Duration(minutes: 4, seconds: 59)), '04:59');
      expect(formatCountdown(const Duration(hours: 1, seconds: 5)), '1:00:05');
    });
  });

  group('PantryMatcher', () {
    test('cubre ingredientes con cantidades, plurales y tildes', () {
      const pantry = ['Aceite de oliva', 'Huevos', 'Limón', 'Tomate'];
      expect(PantryMatcher.isCovered('3 cucharadas de aceite de oliva virgen', pantry), isTrue);
      expect(PantryMatcher.isCovered('2 huevo', pantry), isTrue);
      expect(PantryMatcher.isCovered('El zumo de 2 limones', pantry), isTrue);
      expect(PantryMatcher.isCovered('4 tomates maduros', pantry), isTrue);
    });

    test('no confunde palabras parecidas', () {
      expect(PantryMatcher.isCovered('200 g de salmón', ['Sal']), isFalse);
      expect(PantryMatcher.isCovered('Aceite de girasol', ['Aceite de oliva']), isFalse);
      expect(PantryMatcher.isCovered('Salsa de soja', ['Sal']), isFalse);
      expect(PantryMatcher.isCovered('Sal', const []), isFalse);
    });

    test('reconoce el mismo producto escrito distinto', () {
      expect(PantryMatcher.sameProduct('Huevos', 'huevo'), isTrue);
      expect(PantryMatcher.sameProduct('Limón', 'limones'), isTrue);
      expect(PantryMatcher.sameProduct('Sal', 'Salsa'), isFalse);
    });

    test('limpia una línea de compra para la despensa', () {
      expect(PantryMatcher.cleanName('2 kg de patatas'), 'Patatas');
      expect(PantryMatcher.cleanName('3 dientes de ajo, picados'), 'Ajo');
      expect(PantryMatcher.cleanName('1/2 l de leche (entera)'), 'Leche');
      expect(PantryMatcher.cleanName('Arroz'), 'Arroz');
      expect(PantryMatcher.cleanName('huevos'), 'Huevos');
    });
  });

  group('KitchenTimers', () {
    late DateTime now;
    late KitchenTimers timers;
    late List<String> finished;

    setUp(() {
      now = DateTime(2026, 1, 1, 12);
      finished = [];
      timers = KitchenTimers(
        now: () => now,
        autoTick: false,
        onFinished: (t) => finished.add(t.label),
      );
    });

    tearDown(() => timers.dispose());

    test('cuenta atrás y avisa una sola vez al terminar', () {
      final timer = timers.start('Pasta', const Duration(minutes: 10));
      now = now.add(const Duration(minutes: 4));
      expect(timers.remaining(timer), const Duration(minutes: 6));

      now = now.add(const Duration(minutes: 6));
      timers.tick();
      timers.tick();
      expect(timer.isFinished, isTrue);
      expect(timers.remaining(timer), Duration.zero);
      expect(finished, ['Pasta']);
    });

    test('la pausa congela el tiempo restante', () {
      final timer = timers.start('Horno', const Duration(minutes: 20));
      now = now.add(const Duration(minutes: 5));
      timers.pause(timer);

      now = now.add(const Duration(hours: 1));
      timers.tick();
      expect(timer.isFinished, isFalse);
      expect(timers.remaining(timer), const Duration(minutes: 15));

      timers.resume(timer);
      now = now.add(const Duration(minutes: 15));
      timers.tick();
      expect(finished, ['Horno']);
    });

    test('quitar un temporizador lo saca de la lista', () {
      final a = timers.start('A', const Duration(minutes: 1));
      timers.start('B', const Duration(minutes: 2));
      timers.cancel(a);
      expect(timers.timers.map((t) => t.label), ['B']);
    });
  });
}
