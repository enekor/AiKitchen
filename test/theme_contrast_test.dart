import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/terminos_y_condiciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dos regresiones que dejaron la aplicación inservible en el navegador.
void main() {
  setUpAll(() {
    // El tema se construye sin la tipografía de Google: descargarla por red no
    // funciona en un test y no influye en los tamaños ni en los colores, que
    // es lo que aquí se comprueba.
    CookingTheme.useGoogleFonts = false;
  });

  tearDownAll(() {
    CookingTheme.useGoogleFonts = true;
  });

  group('Colores del tema', () {
    /// Un TextStyle sin color se pinta negro. Al pasar los estilos crudos a los
    /// subtemas, en modo oscuro salía texto negro sobre fondo oscuro.
    void expectStylesHaveColour(ThemeData theme, String label) {
      expect(
        theme.dialogTheme.titleTextStyle?.color,
        isNotNull,
        reason: 'título de diálogo sin color en $label',
      );
      expect(
        theme.dialogTheme.contentTextStyle?.color,
        isNotNull,
        reason: 'contenido de diálogo sin color en $label',
      );
      expect(
        theme.appBarTheme.titleTextStyle?.color,
        isNotNull,
        reason: 'título de barra sin color en $label',
      );
      expect(
        theme.listTileTheme.titleTextStyle?.color,
        isNotNull,
        reason: 'título de lista sin color en $label',
      );
      expect(
        theme.chipTheme.labelStyle?.color,
        isNotNull,
        reason: 'etiqueta de chip sin color en $label',
      );
    }

    test('el tema claro define color en todos los subtemas', () {
      expectStylesHaveColour(CookingTheme.lightTheme(), 'claro');
    });

    test('el tema oscuro define color en todos los subtemas', () {
      expectStylesHaveColour(CookingTheme.darkTheme(), 'oscuro');
    });

    test('la escala tipográfica lleva color en ambos modos', () {
      for (final theme in [CookingTheme.lightTheme(), CookingTheme.darkTheme()]) {
        expect(theme.textTheme.bodyMedium?.color, isNotNull);
        expect(theme.textTheme.headlineSmall?.color, isNotNull);
        expect(theme.textTheme.labelSmall?.color, isNotNull);
      }
    });

    test('el texto contrasta con el fondo sobre el que se pinta', () {
      for (final theme in [CookingTheme.lightTheme(), CookingTheme.darkTheme()]) {
        final surface = theme.colorScheme.surface.computeLuminance();
        final body = theme.textTheme.bodyMedium!.color!.computeLuminance();
        // No es el cálculo formal de contraste, pero basta para detectar el
        // caso que se dio: texto y fondo casi igual de oscuros.
        expect(
          (surface - body).abs(),
          greaterThan(0.3),
          reason: 'el cuerpo de texto apenas se distingue del fondo',
        );
      }
    });
  });

  group('Términos y condiciones', () {
    testWidgets('aceptar no cierra la pantalla que lo muestra', (tester) async {
      var accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminosYCondicionesModal(
              onAccept: () => accepted = true,
              onReject: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      // Si el widget cerrara la ruta por su cuenta, aquí no quedaría nada:
      // ese era el motivo de la pantalla en negro tras aceptar.
      expect(find.text('Términos y Condiciones'), findsOneWidget);
    });

    testWidgets('rechazar tampoco cierra la ruta', (tester) async {
      var rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminosYCondicionesModal(
              onAccept: () {},
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();

      expect(rejected, isTrue);
      expect(find.text('Términos y Condiciones'), findsOneWidget);
    });
  });
}
