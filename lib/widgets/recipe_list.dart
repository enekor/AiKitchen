import 'package:flutter/material.dart';
import 'package:aikitchen/models/recipe.dart';

class RecipesList extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe) onFavRecipe;
  final Function(Recipe) onEdit;
  final Function(List<Recipe>) onShareRecipe;

  const RecipesList({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
    required this.onEdit,
    required this.onShareRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recipes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text(
                recipe.nombre.isNotEmpty ? recipe.nombre[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            title: Text(recipe.nombre, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(recipe.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => onClickRecipe(recipe),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Favorito',
                  icon: const Icon(Icons.favorite_outline),
                  onPressed: () => onFavRecipe(recipe),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onEdit(recipe),
                ),
                IconButton(
                  tooltip: 'Compartir',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => onShareRecipe([recipe]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
