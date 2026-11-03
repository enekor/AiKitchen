import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/home_screen_modern.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La pantalla de inicio se usa sobre todo en tabletas en horizontal, pero
/// también en móvil. Cualquier desbordamiento (las franjas amarillas y negras
/// de Flutter) hace fallar la prueba, así que esto vigila que el diseño
/// aguante en los tamaños habituales, con datos y sin ellos.
void main() {
  Recipe receta(String nombre, {List<String> etiquetas = const []}) => Recipe(
    id: nombre.length,
    nombre: nombre,
    descripcion: '',
    tiempoEstimado: '45 min',
    ingredientes: const ['a'],
    preparacion: const ['b'],
    calorias: '520',
    raciones: '4',
    etiquetas: etiquetas,
  );

  const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final conDatos = HomeSnapshot(
    menu: {
      for (final d in dias)
        d: [
          receta('Lentejas estofadas con verduras de temporada y chorizo'),
          receta('Merluza al horno con patatas panaderas'),
        ],
    },
    favourites: [
      for (var i = 0; i < 8; i++)
        receta('Receta favorita número $i con un nombre bastante largo', etiquetas: ['Táper']),
    ],
    cart: [CartItem(name: 'Leche'), CartItem(name: 'Pan')],
  );

  const tamanos = {
    'tableta horizontal': Size(1280, 800),
    'tableta vertical': Size(800, 1280),
    'móvil': Size(390, 844),
  };

  for (final dark in [false, true]) {
    for (final entry in tamanos.entries) {
      for (final conMenu in [true, false]) {
        final nombre = '${entry.key}, ${dark ? 'oscuro' : 'claro'}, '
            '${conMenu ? 'con datos' : 'primer uso'}';
        testWidgets('se pinta sin desbordarse: $nombre', (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: CookingTheme.lightTheme(),
              darkTheme: CookingTheme.darkTheme(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: ModernHomeScreen(
                loader: () async => conMenu ? conDatos : const HomeSnapshot(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.textContaining('¿qué cocinamos hoy?'), findsOneWidget);
          if (conMenu) {
            expect(find.text('HOY EN TU MENÚ'), findsOneWidget);
            expect(find.textContaining('Empezar a cocinar'), findsOneWidget);
            expect(find.text('Tus favoritas'), findsOneWidget);
            expect(find.text('2 por comprar'), findsOneWidget);
          } else {
            expect(find.text('Planifica tu semana en un toque'), findsOneWidget);
            // En tableta horizontal se explica el hueco de favoritas; en el
            // resto no se muestra la sección.
            expect(
              find.text('Tus favoritas'),
              entry.key == 'tableta horizontal' ? findsOneWidget : findsNothing,
            );
          }
        });
      }
    }
  }

  testWidgets('en tableta horizontal reparte en dos columnas', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: CookingTheme.lightTheme(),
        home: ModernHomeScreen(loader: () async => conDatos),
      ),
    );
    await tester.pumpAndSettle();

    // El menú de hoy (izquierda) y los accesos (derecha) quedan a la misma
    // altura de la pantalla, no uno debajo del otro.
    final menu = tester.getTopLeft(find.text('HOY EN TU MENÚ'));
    final accesos = tester.getTopLeft(find.text('¿Qué te apetece?'));
    expect(accesos.dx, greaterThan(menu.dx + 300));
    expect(accesos.dy, lessThan(menu.dy));
  });
}
