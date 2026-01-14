import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
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
  bool _isSelectionMode = false;
  final Set<Recipe> _selectedRecipes = {};

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

  void _shareRecipes() async {
    if (_selectedRecipes.isEmpty) return;
    await ShareRecipeService().shareRecipe(_selectedRecipes.toList());
    setState(() {
      _isSelectionMode = false;
      _selectedRecipes.clear();
    });
  }

  void _onClickRecipe(Recipe receta) {
    if (_isSelectionMode) {
      _toggleSelection(receta);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecipeScreen(recipe: receta)),
      );
    }
  }

  void _toggleSelection(Recipe receta) {
    setState(() {
      if (_selectedRecipes.contains(receta)) {
        _selectedRecipes.remove(receta);
        if (_selectedRecipes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedRecipes.add(receta);
      }
    });
  }

  void _onEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRecipe(recipe: recipe)),
    );
  }

  void _removeFavorite(Recipe recipe) {
    setState(() {
      AppSingleton().recetasFavoritas.remove(recipe);
      _selectedRecipes.remove(recipe);
      if (_selectedRecipes.isEmpty) _isSelectionMode = false;
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
        final isSelected = _selectedRecipes.contains(recipe);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 0,
          color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _toggleSelection(recipe);
              });
            },
            onTap: () => _onClickRecipe(recipe),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (val) => _toggleSelection(recipe),
                    )
                  : null,
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
              trailing: _isSelectionMode 
                ? null 
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _onEditRecipe(recipe),
                        tooltip: 'Editar receta',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => _removeFavorite(recipe),
                        tooltip: 'Eliminar de favoritos',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => ShareRecipeService().shareRecipe([recipe]),
                        tooltip: 'Compartir receta',
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeCount = AppSingleton().recetasFavoritas.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedRecipes.length} seleccionadas')
            : Row(
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
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedRecipes.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareRecipes,
              tooltip: 'Compartir seleccionadas',
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadFavorites();
                Toaster.showSuccess('Lista actualizada');
              },
              tooltip: 'Actualizar lista',
            ),
        ],
      ),
      body: _buildRecipeList(),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _shareRecipes,
              label: const Text('Compartir'),
              icon: const Icon(Icons.share),
            )
          : null,
    );
  }
}
