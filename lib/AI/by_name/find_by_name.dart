import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class FindByName extends StatefulWidget {
  const FindByName({super.key});

  @override
  State<FindByName> createState() => _FindByNameState();
}

class _FindByNameState extends State<FindByName> {
  List<Recipe>? _recetas;
  List<String> _historial = [];
  bool _searching = false;
  bool _showHistory = false;
  final TextEditingController _nameController = TextEditingController();

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

  void _loadHistory() async {
    final history = await SharedPreferencesService.getStringListValue(
      SharedPreferencesKeys.historialBusquedaNombres,
    );
    setState(() {
      _historial = history;
    });
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
  }

  String _cleanJsonResponse(String response) {
    response = response.replaceAll(RegExp(r'```json\s*'), '');
    response = response.replaceAll(RegExp(r'\s*```'), '');
    return response.trim();
  }

  Future<void> _searchByName(String name) async {
    if (name.trim().isEmpty) {
      Toaster.showWarning('Ingresa un nombre de receta');
      return;
    }

    setState(() {
      _recetas = [];
      _searching = true;
      _showHistory = false;
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

  void _shareRecipe(Recipe receta) async {
    await ShareRecipeService().shareRecipe([receta]);
  }

  void _onFavRecipe(Recipe recipe) {
    bool isFav = AppSingleton().recetasFavoritas.any((r) => r.nombre == recipe.nombre);
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
            _buildSearchField(theme),
            const SizedBox(height: 12),
            _buildHistoryAndSuggestions(theme),
            
            if (_recetas != null) ...[
              const SizedBox(height: 40),
              _buildRecipeResults(theme),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '¿Qué te apetece hoy?',
                border: InputBorder.none,
              ),
              onSubmitted: _searchByName,
            ),
          ),
          IconButton(
            icon: Icon(
              _showHistory ? Icons.expand_less_rounded : Icons.history_rounded,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            onPressed: _toggleHistory,
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => _searchByName(_nameController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAndSuggestions(ThemeData theme) {
    if (_showHistory && _historial.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historial.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.history_rounded, size: 18),
              title: Text(_historial[index]),
              onTap: () {
                _nameController.text = _historial[index];
                _searchByName(_historial[index]);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          },
        ),
      );
    }

    final suggestions = ['Pizza', 'Tacos', 'Ensalada Cesar', 'Lasaña'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(s),
            onPressed: () {
              _nameController.text = s;
              _searchByName(s);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
            side: BorderSide.none,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRecipeResults(ThemeData theme) {
    if (_recetas!.isEmpty) {
      return Center(
        child: Text('No se han encontrado recetas.', style: theme.textTheme.bodyLarge),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESULTADOS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        ..._recetas!.map((receta) => _recipeCard(theme, receta)),
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
                        Text(
                          receta.nombre,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
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
                    onPressed: () => _shareRecipe(receta),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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
