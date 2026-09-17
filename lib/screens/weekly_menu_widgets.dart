import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/responsive_card_list.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

class EmptyWeeklyMenu extends StatelessWidget {
  final VoidCallback onGenerate;

  const EmptyWeeklyMenu({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'Tu semana culinaria empieza aquí',
      description:
          'Genera un menú semanal inteligente basado en tus gustos y preferencias configuradas.',
      actionLabel: 'Generar mi menú',
      onAction: onGenerate,
    );
  }
}

typedef RegenerateMealCallback = void Function(String dia, int mealIndex);

class WeeklyMenuList extends StatelessWidget {
  final List<String> diasSemana;
  final Map<String, List<Recipe>> weeklyMenu;
  final RegenerateMealCallback onRegenerateMeal;

  const WeeklyMenuList({
    super.key,
    required this.diasSemana,
    required this.weeklyMenu,
    required this.onRegenerateMeal,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCardList(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      minColumnWidth: 320,
      children: [
        for (final dia in diasSemana)
          _DayCard(
            dia: dia,
            recetas: weeklyMenu[dia] ?? [],
            onRegenerateMeal: (index) => onRegenerateMeal(dia, index),
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dia;
  final List<Recipe> recetas;
  final ValueChanged<int> onRegenerateMeal;

  const _DayCard({
    required this.dia,
    required this.recetas,
    required this.onRegenerateMeal,
  });

  int get _totalKcal {
    var total = 0;
    for (final r in recetas) {
      total += int.tryParse(r.calorias.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dia,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (_totalKcal > 0)
                  Text(
                    '$_totalKcal kcal',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          for (var index = 0; index < recetas.length; index++)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.md,
              ),
              child: _MealRow(
                mealType: index == 0 ? 'Comida' : 'Cena',
                recipe: recetas[index],
                onRegenerate: () => onRegenerateMeal(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.mealType,
    required this.recipe,
    required this.onRegenerate,
  });

  final String mealType;
  final Recipe recipe;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.recipe,
          arguments: RecipeScreenArguments(recipe: recipe),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Icon(
                mealType == 'Comida' ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      recipe.nombre,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Regenerar esta comida',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
