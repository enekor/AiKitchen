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

        // Actualizar historial
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
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Buscar receta...',
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.restaurant_menu,
                    color: theme.colorScheme.primary,
                  ),
                ),
                onSubmitted: _searchByName,
              ),
            ),
            IconButton(
              icon: Icon(Icons.history, color: theme.colorScheme.primary),
              onPressed: _toggleHistory,
            ),
            IconButton(
              icon: Icon(Icons.search, color: theme.colorScheme.primary),
              onPressed: () => _searchByName(_nameController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (!_showHistory || _historial.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _historial.length,
        itemBuilder: (context, index) {
          final query = _historial[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(query),
            onTap: () {
              _nameController.text = query;
              _searchByName(query);
            },
            trailing: IconButton(
              icon: const Icon(Icons.north_west),
              onPressed: () {
                _nameController.text = query;
                setState(() => _showHistory = false);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_showHistory) return const SizedBox.shrink();

    final sugerencias = [
      'Pizza casera',
      'Pasta carbonara',
      'Hamburguesa',
      'Tortilla española',
      'Arroz con pollo',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: sugerencias
            .map(
              (sugerencia) => ActionChip(
                label: Text(sugerencia),
                onPressed: () {
                  _nameController.text = sugerencia;
                  _searchByName(sugerencia);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showQuickPreview(Recipe recipe) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text(
                      recipe.nombre,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recipe.descripcion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(
                          Icons.timer,
                          recipe.tiempoEstimado,
                          theme.colorScheme.secondary,
                        ),
                        _buildInfoChip(
                          Icons.local_fire_department,
                          '${recipe.calorias.toInt()} cal',
                          theme.colorScheme.tertiary,
                        ),
                        _buildInfoChip(
                          Icons.restaurant,
                          '${recipe.raciones} raciones',
                          theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ingredientes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredientes.map(
                      (ingrediente) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ingrediente,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Preparación',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.preparacion.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_recetas == null) return const SizedBox.shrink();
    if (_recetas!.isEmpty) {
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
        ...(_recetas ?? []).map(
          (receta) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onLongPress: () => _showQuickPreview(receta),
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
              const SizedBox(height: 8),
              _buildHistoryList(),
              _buildSuggestions(),
              if (_recetas != null) ...[
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
