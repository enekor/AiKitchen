import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Ficha de 28 px con cruz de eliminar. Se usa para ingredientes añadidos por
/// el usuario y para el historial de búsquedas recientes.
///
/// Tocar la etiqueta y tocar la cruz son dos acciones distintas: [onTap]
/// reacciona al texto (por ejemplo, repetir una búsqueda del historial) y
/// [onRemove] solo a la cruz. Antes solo existía el segundo, así que tocar el
/// texto no hacía nada.
class RemovableChip extends StatelessWidget {
  const RemovableChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.onTap,
  });

  final String label;
  final VoidCallback onRemove;

  /// Si es nulo, la etiqueta no responde al toque y solo se puede eliminar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: AppRadius.capsule,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.full),
            ),
            child: Container(
              height: 28,
              padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.xs),
              decoration: BoxDecoration(
                borderRadius: AppRadius.capsule,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(label, style: theme.textTheme.labelMedium),
            ),
          ),
          // Zona de toque propia para la cruz, mayor que el icono en sí, para
          // que sea fácil de acertar junto al texto sin ampliar toda la ficha.
          InkWell(
            onTap: onRemove,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(AppRadius.full),
            ),
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                  right: BorderSide(color: theme.colorScheme.outlineVariant),
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.full),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
