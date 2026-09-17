import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Lista de ingredientes con casilla para marcar mientras se cocina.
///
/// El marcado es efímero a propósito: vive solo en este widget y se pierde al
/// salir de la receta. Persistirlo exigiría una tabla por receta y no aporta
/// lo suficiente para el coste.
class IngredientsList extends StatefulWidget {
  const IngredientsList({
    super.key,
    required this.ingredients,
    this.onMarkedCountChanged,
  });

  final List<String> ingredients;

  /// Se avisa cada vez que cambia cuántos están marcados, para que la
  /// pantalla pueda mostrar un contador tipo "3 de 8 marcados".
  final ValueChanged<int>? onMarkedCountChanged;

  @override
  State<IngredientsList> createState() => _IngredientsListState();
}

class _IngredientsListState extends State<IngredientsList> {
  final Set<int> _marked = {};

  void _toggle(int index) {
    setState(() {
      if (!_marked.remove(index)) _marked.add(index);
    });
    widget.onMarkedCountChanged?.call(_marked.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.ingredients.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _IngredientRow(
            text: widget.ingredients[i],
            marked: _marked.contains(i),
            onTap: () => _toggle(i),
          ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.text,
    required this.marked,
    required this.onTap,
  });

  final String text;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Checkbox(value: marked, onChanged: (_) => onTap()),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: marked ? TextDecoration.lineThrough : null,
                    color: marked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
