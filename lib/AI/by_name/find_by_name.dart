import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Modo "por nombre" del centro de búsqueda. No lleva `Scaffold` propio:
/// vive embebido en `SearchHub`.
class FindByName extends StatefulWidget {
  const FindByName({super.key});

  @override
  State<FindByName> createState() => _FindByNameState();
}

class _FindByNameState extends State<FindByName> {
  List<Recipe>? _recetas;
  List<String> _historial = [];
  bool _searching = false;
  final TextEditingController _nameController = TextEditingController();

  static const _suggestions = ['Pizza', 'Tacos', 'Ensalada César', 'Lasaña'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await SharedPreferencesService.getStringListValue(
      SharedPreferencesKeys.historialBusquedaNombres,
    );
    if (mounted) setState(() => _historial = history);
  }

  String _cleanJsonResponse(String response) {
    return response
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'\s*```'), '')
        .trim();
  }

  Future<void> _searchByName(String name) async {
    if (name.trim().isEmpty) {
      Toaster.showWarning('Ingresa un nombre de receta');
      return;
    }

    setState(() {
      _recetas = [];
      _searching = true;
    });

    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePrompt(
          [name],
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
          _recetas = Recipe.fromJsonList(cleanedResponse);
          _searching = false;
        });

        if (!_historial.contains(name)) {
          _historial.insert(0, name);
          if (_historial.length > 10) _historial.removeLast();
          await SharedPreferencesService.setStringListValue(
            SharedPreferencesKeys.historialBusquedaNombres,
            _historial,
          );
        }

        Toaster.showSuccess('¡${_recetas!.length} recetas encontradas!');
      } else {
        _handleError(response);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() => _searching = false);
    Toaster.showError('Error al generar recetas: ${error.split(":").last}');
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
      Toaster.showSuccess('¡Añadido a favoritos!');
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
        AppSearchField(
          controller: _nameController,
          hintText: '¿Qué te apetece hoy?',
          onSubmitted: _searchByName,
        ),
        const SizedBox(height: Spacing.md),
        if (_historial.isNotEmpty) ...[
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final item in _historial)
                RemovableChip(
                  label: item,
                  onRemove: () {
                    setState(() => _historial.remove(item));
                    SharedPreferencesService.setStringListValue(
                      SharedPreferencesKeys.historialBusquedaNombres,
                      _historial,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
        ],
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final s in _suggestions)
              ActionChip(
                label: Text(s),
                onPressed: () {
                  _nameController.text = s;
                  _searchByName(s);
                },
              ),
          ],
        ),
        if (_recetas != null) ...[
          const SizedBox(height: Spacing.xl),
          if (_recetas!.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No se han encontrado recetas',
            )
          else
            for (final receta in _recetas!) ...[
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
