import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:flutter/material.dart';

class EmptyWeeklyMenu extends StatelessWidget {
  final VoidCallback onGenerate;

  const EmptyWeeklyMenu({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay un menú semanal generado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genera un menú semanal personalizado\nbasado en tus preferencias',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar Menú Semanal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyMenuList extends StatelessWidget {
  final List<String> diasSemana;
  final Map<String, List<Recipe>> weeklyMenu;
  final VoidCallback onRegenerate;

  const WeeklyMenuList({
    super.key,
    required this.diasSemana,
    required this.weeklyMenu,
    required this.onRegenerate,
  });

  Future<bool> _showRegenerateConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Regenerar Menú'),
            content: const Text(
              '¿Estás seguro de que quieres generar un nuevo menú semanal? El menú actual se perderá.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Regenerar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            child: InkWell(
              onTap: () async {
                if (await _showRegenerateConfirmation(context)) {
                  onRegenerate();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Volver a generar menú',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: diasSemana.length,
            itemBuilder: (context, index) {
              final dia = diasSemana[index];
              final recetas = weeklyMenu[dia] ?? [];
              return _DayCard(dia: dia, recetas: recetas);
            },
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dia;
  final List<Recipe> recetas;

  const _DayCard({required this.dia, required this.recetas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              dia,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recetas.length,
            itemBuilder: (context, index) {
              final receta = recetas[index];
              final mealType = _getMealType(index);
              return ListTile(
                title: Text(receta.nombre),
                subtitle: Text(mealType),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/recipe',
                    arguments: RecipeScreenArguments(recipe: receta),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMealType(int index) {
    switch (index) {
      case 0:
        return 'Desayuno';
      case 1:
        return 'Comida';
      case 2:
        return 'Cena';
      default:
        return '';
    }
  }
}
