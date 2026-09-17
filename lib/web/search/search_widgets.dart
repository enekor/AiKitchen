import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Estado inicial del modo de búsqueda de internet, antes de buscar nada.
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.lg),
            Text('Recetas de internet', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Busca en Lidl y Cookpad para encontrar inspiración externa.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
