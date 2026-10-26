import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/ui/app_card.dart';
import 'package:flutter/material.dart';

/// Tarjeta de un resultado de receta raspado de internet.
///
/// Es el único componente de tarjeta que muestra fotografía: el raspador de
/// Lidl y Cookpad sí trae una dirección de imagen, y aquí ayuda a decidir qué
/// resultado abrir. `RecipeCard`, en cambio, nunca la muestra.
class WebRecipeCard extends StatelessWidget {
  const WebRecipeCard({
    super.key,
    required this.result,
    required this.onImport,
    required this.onOpenWeb,
  });

  final WebRecipeResult result;
  final VoidCallback onImport;
  final VoidCallback onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onImport,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: result.imageUrl.isEmpty
                  ? Container(color: theme.colorScheme.surfaceContainerHigh)
                  : Image.network(
                      result.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: theme.colorScheme.surfaceContainerHigh),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    if (result.sourceName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          result.sourceName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      result.time,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onImport,
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('Ver receta'),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    IconButton.outlined(
                      onPressed: onOpenWeb,
                      icon: const Icon(Icons.open_in_new_rounded),
                      tooltip: 'Abrir en el navegador',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
