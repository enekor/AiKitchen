import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../singleton/app_singleton.dart';

/// Modo "por ingredientes" del centro de búsqueda. Sin `Scaffold` propio.
class FindByIngredients extends StatefulWidget {
  const FindByIngredients({super.key});

  @override
  State<FindByIngredients> createState() => _FindByIngredientsState();
}

class _FindByIngredientsState extends State<FindByIngredients> {
  List<String> ingredientes = [];
  List<Recipe>? recetas;
  bool _searching = false;
  final TextEditingController _ingredientController = TextEditingController();

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty && !ingredientes.contains(ingredient)) {
      setState(() {
        ingredientes.add(ingredient);
        _ingredientController.clear();
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() => ingredientes.remove(ingredient));
  }

  String _cleanJsonResponse(String response) {
    return response
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
        .trim();
  }

  Future<void> _generateResponse({bool sugerir = false}) async {
    if (ingredientes.isEmpty && !sugerir) {
      Toaster.showWarning('Añade al menos un ingrediente');
      return;
    }

    setState(() {
      recetas = [];
      _searching = true;
    });

    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePrompt(
          ingredientes,
          AppSingleton().numRecetas,
          AppSingleton().personality,
          AppSingleton().idioma,
          AppSingleton().tipoReceta,
        ),
        context,
      );

      if (response.isNotEmpty && !response.contains('error')) {
        final cleanedResponse = _cleanJsonResponse(response);
        setState(() {
          recetas = Recipe.fromJsonList(cleanedResponse);
          _searching = false;
        });
        Toaster.showSuccess('¡He encontrado ${recetas!.length} recetas!');
      } else {
        _handleError(response);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() => _searching = false);
    Toaster.showError('Algo ha fallado: ${error.split(":").last}');
  }

  void _onFavRecipe(Recipe recipe) {
    final isFav = AppSingleton().recetasFavoritas.any(
      (r) => r.nombre == recipe.nombre,
    );
    if (isFav) {
      AppSingleton().recetasFavoritas.removeWhere((r) => r.nombre == recipe.nombre);
      Toaster.showWarning('Eliminado de favoritos');
      if (recipe.id != null) JsonDocumentsService().removeFavRecipe(recipe.id!);
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
      Toaster.showSuccess('¡Guardado!');
      JsonDocumentsService().addFavRecipe(recipe);
    }
    setState(() {});
  }

  void _openRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      AppRoutes.recipe,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ingredientController,
                decoration: const InputDecoration(
                  hintText: 'Añade un ingrediente...',
                  prefixIcon: Icon(Icons.kitchen_outlined),
                ),
                onSubmitted: (_) => _addIngredient(),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton.filledTonal(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (ingredientes.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final ing in ingredientes)
                RemovableChip(label: ing, onRemove: () => _removeIngredient(ing)),
            ],
          ),
        ],
        const SizedBox(height: Spacing.lg),
        PrimaryButton(
          label: ingredientes.isEmpty ? 'Sorpréndeme' : 'Buscar recetas',
          icon: ingredientes.isEmpty
              ? Icons.auto_awesome_rounded
              : Icons.restaurant_menu_rounded,
          expand: true,
          onPressed: () => _generateResponse(sugerir: ingredientes.isEmpty),
        ),
        if (ingredientes.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => ingredientes.clear()),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Limpiar ingredientes'),
            ),
          ),
        if (recetas != null) ...[
          const SizedBox(height: Spacing.xl),
          if (recetas!.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No se han encontrado recetas',
            )
          else
            for (final receta in recetas!) ...[
              RecipeCard(
                recipe: receta,
                onTap: () => _openRecipe(receta),
                isFavorite: AppSingleton().recetasFavoritas.any(
                  (r) => r.nombre == receta.nombre,
                ),
                onToggleFavorite: () => _onFavRecipe(receta),
                trailing: IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Compartir',
                  onPressed: () => ShareRecipeService().shareRecipe([receta]),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
        ],
      ],
    );
  }
}
