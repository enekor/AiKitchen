import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/screens/create_recipe.dart';
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
      HapticFeedback.lightImpact();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      ingredientes.remove(ingredient);
    });
    Toaster.showWarning('$ingredient eliminado');
    HapticFeedback.lightImpact();
  }

  void _clearAllIngredients() {
    setState(() {
      ingredientes.clear();
    });
    Toaster.showWarning('Lista de ingredientes limpiada');
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response;
    cleaned = cleaned.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*```$', multiLine: true), '');
    cleaned = cleaned.replaceAll('```', '');
    cleaned = cleaned.trim();
    return cleaned;
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
        Toaster.showSuccess('¡${recetas!.length} recetas encontradas!');
      } else {
        _handleError(response);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() => _searching = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error al generar recetas'),
        content: Text('Ha ocurrido un error: ${error.split(":").last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _sugerirRecetasSinIngredientes() async {
    Toaster.showToast('Generando recetas de sugerencia...');
    await _generateResponse(sugerir: true);
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

  void _onFavRecipe(Recipe recipe) {
    if (AppSingleton().recetasFavoritas.contains(recipe)) {
      AppSingleton().recetasFavoritas.remove(recipe);
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }
    JsonDocumentsService().updateFavRecipes(recipe);
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ingredientController,
                decoration: InputDecoration(
                  hintText: 'Añade un ingrediente...',
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.restaurant_menu,
                    color: theme.colorScheme.primary,
                  ),
                ),
                onSubmitted: (_) => _addIngredient(),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
              ),
              onPressed: _addIngredient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientList() {
    if (ingredientes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ingredientes
              .map(
                (ingredient) => Chip(
                  label: Text(ingredient),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeIngredient(ingredient),
                ),
              )
              .toList(),
        ),
        if (ingredientes.length > 1) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _clearAllIngredients,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar todo'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton.icon(
      onPressed: _searching
          ? null
          : ingredientes.isEmpty
          ? _sugerirRecetasSinIngredientes
          : _generateResponse,
      icon: Icon(
        ingredientes.isEmpty ? Icons.auto_awesome : Icons.search,
        size: 20,
      ),
      label: Text(
        ingredientes.isEmpty
            ? 'Sugerir recetas'
            : 'Buscar recetas con ${ingredientes.length} ingrediente${ingredientes.length == 1 ? '' : 's'}',
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (recetas == null) return const SizedBox.shrink();
    if (recetas!.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron recetas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recetas encontradas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recetas!.map(
          (receta) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                receta.nombre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                receta.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              onTap: () => _onClickRecipe(receta),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      AppSingleton().recetasFavoritas.contains(receta)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => _onFavRecipe(receta),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareRecipe(receta),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return const Scaffold(
        body: Center(
          child: LottieAnimationWidget(type: LottieAnimationType.loading),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(),
              _buildIngredientList(),
              const SizedBox(height: 24),
              _buildSearchButton(),
              if (recetas != null) ...[
                const SizedBox(height: 32),
                _buildRecipeList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
