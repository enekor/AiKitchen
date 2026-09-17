import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Fila de tiempo, calorías y raciones con iconos técnicos de 16 px.
///
/// Es el mismo trío de datos en todas las tarjetas y en el detalle, así que se
/// construye una sola vez en lugar de repetir tres `Row` distintos.
class RecipeMetaRow extends StatelessWidget {
  const RecipeMetaRow({super.key, required this.recipe, this.compact = false});

  final Recipe recipe;

  /// Reduce el tamaño de letra para usarse dentro de una tarjeta densa.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final iconSize = compact ? 14.0 : 16.0;
    final iconColor = theme.colorScheme.onSurfaceVariant;

    Widget item(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: Spacing.xs),
          Text(text, style: style),
        ],
      );
    }

    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.xs,
      children: [
        item(Icons.timer_outlined, recipe.tiempoEstimado),
        item(Icons.local_fire_department_outlined, '${recipe.calorias} kcal'),
        item(Icons.people_alt_outlined, '${recipe.raciones} pers.'),
      ],
    );
  }
}
