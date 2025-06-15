import 'package:flutter/material.dart';

enum LottieAnimationType { loading, notfound }

class LottieAnimationWidget extends StatelessWidget {
  const LottieAnimationWidget({
    super.key,
    this.type = LottieAnimationType.loading,
  });
  final LottieAnimationType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          switch (type) {
            LottieAnimationType.loading => Column(
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Generando recetas...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            LottieAnimationType.notfound => Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron recetas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros ingredientes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
