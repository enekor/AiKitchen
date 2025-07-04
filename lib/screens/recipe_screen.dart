import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/cooking_card.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _showSummary = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    _isFavorite = AppSingleton().recetasFavoritas.any(
      (recipe) =>
          recipe.nombre == widget.recipe.nombre &&
          recipe.descripcion == widget.recipe.descripcion,
    );
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      AppSingleton().recetasFavoritas.removeWhere(
        (recipe) =>
            recipe.nombre == widget.recipe.nombre &&
            recipe.descripcion == widget.recipe.descripcion,
      );
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(widget.recipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }

    await JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.nombre),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Favorite button
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: _isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
          ),
          // Recipe info chips in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RecipeInfoChip(
                  icon: Icons.timer,
                  label: widget.recipe.tiempoEstimado,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                RecipeInfoChip(
                  icon: Icons.restaurant,
                  label: '${widget.recipe.raciones}',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recipe info header
          if (_showSummary)
            CookingCard(
              onTap:
                  () => setState(() {
                    _showSummary = !_showSummary;
                  }),
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.descripcion,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        Icons.local_fire_department,
                        '${widget.recipe.calorias.toInt()} cal',
                        theme.colorScheme.tertiary,
                      ),
                      _buildInfoItem(
                        Icons.timer,
                        widget.recipe.tiempoEstimado,
                        theme.colorScheme.secondary,
                      ),
                      _buildInfoItem(
                        Icons.restaurant,
                        '${widget.recipe.raciones} porciones',
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_showSummary)
            CookingCard(
              onTap:
                  () => setState(() {
                    _showSummary = !_showSummary;
                  }),
              margin: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Mostrar resumen',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Navigation tabs
          CookingCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = 0);
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _currentPage == 0
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            _currentPage == 0
                                ? Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                )
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color:
                                _currentPage == 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preparación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  _currentPage == 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                              fontWeight:
                                  _currentPage == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = 1);
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _currentPage == 1
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            _currentPage == 1
                                ? Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                )
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket,
                            color:
                                _currentPage == 1
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingredientes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  _currentPage == 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                              fontWeight:
                                  _currentPage == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                // Página 1: StepsList
                StepsList(steps: widget.recipe.preparacion),
                // Página 2: IngredientsList
                IngredientsList(ingredients: widget.recipe.ingredientes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
