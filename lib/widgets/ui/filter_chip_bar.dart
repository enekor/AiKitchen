import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Fila desplazable de fichas de filtro, con una única seleccionada a la vez.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(labelOf(option)),
            selected: isSelected,
            onSelected: (_) => onChanged(option),
            showCheckmark: false,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}
