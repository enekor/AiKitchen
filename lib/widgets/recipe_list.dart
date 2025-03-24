import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class RecipePreview extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onGavRecipe;
  final VoidCallback onClickRecipe;
  final bool isFavorite;

  const RecipePreview({
    required this.recipe,
    this.onGavRecipe,
    required this.onClickRecipe,
    this.isFavorite = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClickRecipe,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              // Sombras neumórficas (mantenemos el efecto)
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(5, 5),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(-4, -4),
                inset: true,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con nombre y botón de favoritos
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.nombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (onGavRecipe != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onGavRecipe,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.9),
                                blurRadius: 5,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Descripción
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  recipe.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // Detalles (se muestran al interactuar)
              MouseRegion(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiempo: ${recipe.tiempoEstimado}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Ingredientes: ${recipe.ingredientes.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Pasos: ${recipe.preparacion.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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

class RecipesList extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe)? onFavRecipe;
  final Function(Recipe) onClickRecipe;
  bool isFav = false;

  RecipesList({
    required this.recipes,
    this.onFavRecipe,
    required this.onClickRecipe,
    this.isFav = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipePreview(
          recipe: recipe,
          onGavRecipe: onFavRecipe != null ? () => onFavRecipe!(recipe) : null,
          onClickRecipe: () => onClickRecipe(recipe),
          isFavorite: isFav,
        );
      },
    );
  }
}

class RecipesGrid extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe)? onFavRecipe;
  final Function(Recipe) onClickRecipe;
  bool isFav = false;

  RecipesGrid({
    required this.recipes,
    this.onFavRecipe,
    required this.onClickRecipe,
    this.isFav = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300, // Ancho máximo de cada item
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Relación más cuadrada
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipePreview(
          recipe: recipe,
          onGavRecipe: onFavRecipe != null ? () => onFavRecipe!(recipe) : null,
          onClickRecipe: () => onClickRecipe(recipe),
          isFavorite: isFav,
        );
      },
    );
  }
}
