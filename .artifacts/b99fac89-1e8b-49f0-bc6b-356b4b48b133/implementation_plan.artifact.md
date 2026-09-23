# Corrección de Errores de Renderizado (Infinite Width)

El error "BoxConstraints forces an infinite width" ocurre porque el tema global de la aplicación define que todos los `FilledButton` deben tener un ancho mínimo infinito, lo que rompe los diseños basados en `Row` (como el del banner de voz en la receta o las acciones de la AppBar).

## Causa Raíz
En `CookingTheme`, el estilo de `filledButtonTheme` usa `minimumSize: const Size.fromHeight(44)`.
En Flutter, `Size.fromHeight(44)` equivale a `Size(double.infinity, 44)`. Esto obliga a cada botón a intentar ocupar todo el ancho disponible. Cuando este botón está dentro de un `Row` junto a un `Expanded`, el `Row` no puede calcular el espacio restante y la aplicación falla.

## Cambios Propuestos

### [MODIFY] [cooking_theme.dart](file:///D:/repos/aikitchen/lib/theme/cooking_theme.dart)
*   Cambiar `minimumSize: const Size.fromHeight(44)` por `minimumSize: const Size(64, 44)` en `filledButtonTheme` y `outlinedButtonTheme`. Esto asegura una altura mínima de 44px (estándar de accesibilidad) sin forzar un ancho infinito.

### [MODIFY] [create_recipe.dart](file:///D:/repos/aikitchen/lib/screens/create_recipe.dart)
*   Asegurar que el botón de guardado inferior siga siendo ancho completo usando `SizedBox(width: double.infinity, ...)` o `Expanded`, ya que ahora el botón por defecto solo ocupará lo que necesite su texto.

### [MODIFY] [recipe_screen.dart](file:///D:/repos/aikitchen/lib/screens/recipe_screen.dart)
*   No se requieren cambios estructurales si corregimos el tema, ya que el botón "Iniciar" simplemente se ajustará a su contenido dentro del `Row`.

## Plan de Verificación
1.  Navegar a la pantalla de detalle de receta.
2.  Verificar que el banner de "Lectura en voz alta" se renderiza correctamente y no hay errores de "Infinite width".
3.  Ir a la pantalla de creación de receta.
4.  Verificar que el botón "Guardar" de la AppBar se ve bien y que el botón "Guardar Receta" al final sigue ocupando todo el ancho.
