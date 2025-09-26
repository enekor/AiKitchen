import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final recipes = await JsonDocumentsService().getFavRecipes();
    setState(() {
      AppSingleton().recetasFavoritas = recipes;
    });
  }

  void _shareRecipe(Recipe receta) async {
    await ShareRecipeService().shareRecipe([receta]);
  }

  void _onClickRecipe(Recipe receta) {
    Navigator.pushNamed(
      context,
      '/recipe',
      arguments: RecipeScreenArguments(recipe: receta),
    );
  }

  void _onEditRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      '/recipe/edit',
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  void _removeFavorite(Recipe recipe) {
    setState(() {
      AppSingleton().recetasFavoritas.remove(recipe);
    });
    JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
    Toaster.showSuccess('Receta eliminada de favoritos');
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes recetas favoritas',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las recetas que marques como favoritas aparecerán aquí',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    final theme = Theme.of(context);
    final recipes = AppSingleton().recetasFavoritas;

    if (recipes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              recipe.nombre,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              recipe.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            onTap: () => _onClickRecipe(recipe),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _onEditRecipe(recipe),
                  tooltip: 'Editar receta',
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: theme.colorScheme.primary),
                  onPressed: () => _removeFavorite(recipe),
                  tooltip: 'Eliminar de favoritos',
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareRecipe(recipe),
                  tooltip: 'Compartir receta',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshFavorites() {
    _loadFavorites();
    Toaster.showSuccess('Lista actualizada');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeCount = AppSingleton().recetasFavoritas.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Recetas Favoritas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recipeCount.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFavorites,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: _buildRecipeList(),
    );
  }
}
