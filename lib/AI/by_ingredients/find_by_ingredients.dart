import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../singleton/app_singleton.dart';

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
      Toaster.showSuccess('¡$ingredient añadido!');
      HapticFeedback.mediumImpact();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      ingredientes.remove(ingredient);
    });
    Toaster.showWarning('$ingredient eliminado');
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response;
    cleaned = cleaned.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*```$', multiLine: true), '');
    return cleaned.trim();
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
    bool isFav = AppSingleton().recetasFavoritas.any((r) => r.nombre == recipe.nombre);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_searching) {
      return const Scaffold(
        body: Center(
          child: LottieAnimationWidget(type: LottieAnimationType.loading),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildInputSection(theme),
            const SizedBox(height: 16),
            _buildIngredientChips(theme),
            
            const SizedBox(height: 32),
            _buildActionButtons(theme),
            
            if (recetas != null) ...[
              const SizedBox(height: 40),
              _buildResults(theme),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.kitchen_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ingredientController,
              decoration: const InputDecoration(
                hintText: 'Añade un ingrediente...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
          ),
          IconButton.filledTonal(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChips(ThemeData theme) {
    if (ingredientes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ingredientes.map((ing) => Chip(
        label: Text(ing, style: const TextStyle(fontWeight: FontWeight.bold)),
        onDeleted: () => _removeIngredient(ing),
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () => _generateResponse(sugerir: ingredientes.isEmpty),
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            label: Text(
              ingredientes.isEmpty ? '¡SORPRÉNDEME!' : 'BUSCAR RECETAS',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            icon: Icon(ingredientes.isEmpty ? Icons.auto_awesome_rounded : Icons.restaurant_menu_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        if (ingredientes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: () => setState(() => ingredientes.clear()),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Limpiar todos los ingredientes'),
            ),
          ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (recetas!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECETAS ENCONTRADAS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        ...recetas!.map((r) => _recipeCard(theme, r)),
      ],
    );
  }

  Widget _recipeCard(ThemeData theme, Recipe receta) {
    bool isFav = AppSingleton().recetasFavoritas.any((r) => r.nombre == receta.nombre);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => Navigator.pushNamed(context, '/recipe', arguments: RecipeScreenArguments(recipe: receta)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(receta.nombre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          receta.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                    color: isFav ? Colors.redAccent : null,
                    onPressed: () => _onFavRecipe(receta),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBadge(theme, Icons.timer_rounded, receta.tiempoEstimado),
                  _infoBadge(theme, Icons.local_fire_department_rounded, '${receta.calorias.toInt()} cal'),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () => ShareRecipeService().shareRecipe([receta]),
                    style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
