import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/recipe_from_file_service.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PreviewSharedFiles extends StatefulWidget {
  const PreviewSharedFiles({Key? key, required this.recipeUri}) : super(key: key);

  final String recipeUri;

  @override
  State<PreviewSharedFiles> createState() => _PreviewSharedFilesState();
}

class _PreviewSharedFilesState extends State<PreviewSharedFiles> {
  List<Recipe>? _recipe;
  late Future<List<Recipe>?> _recipeFuture;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipe();
  }

  Future<List<Recipe>?> _loadRecipe() async {
    try {
      final recipes = await RecipeFromFileService().loadRecipes(widget.recipeUri);
      if (mounted) {
        setState(() => _recipe = recipes);
      }
      return recipes;
    } catch (e) {
      debugPrint('Error loading recipe: $e');
      return null;
    }
  }

  int _showingRecipe = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          FutureBuilder<List<Recipe>?>(
            future: _recipeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error al cargar la receta', style: theme.textTheme.titleLarge),
                    ],
                  ),
                );
              }

              final recipes = snapshot.data!;
              return CarouselSlider(
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height,
                  initialPage: _showingRecipe,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, _) => setState(() => _showingRecipe = index),
                ),
                items: recipes.map((r) => _recipePreview(r, theme)).toList(),
              );
            },
          ),
          
          // Back Button Floating (Material Expressive style)
          Positioned(
            top: 45,
            left: 20,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.close_rounded, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          // Save FAB
          if (_recipe != null && _recipe!.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await JsonDocumentsService().addFavRecipe(_recipe![_showingRecipe]);
                  Toaster.showSuccess('¡${_recipe![_showingRecipe].nombre} guardada!');
                },
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                label: const Text('GUARDAR RECETA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                icon: const Icon(Icons.favorite_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recipePreview(Recipe recipe, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'RECETA COMPARTIDA',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onPrimaryContainer,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recipe.nombre,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recipe.descripcion,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          
          // Modern Info Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildExpressiveChip(theme, Icons.timer_rounded, recipe.tiempoEstimado, theme.colorScheme.secondaryContainer),
                const SizedBox(width: 8),
                _buildExpressiveChip(theme, Icons.local_fire_department_rounded, '${recipe.calorias.toInt()} cal', theme.colorScheme.tertiaryContainer),
                const SizedBox(width: 8),
                _buildExpressiveChip(theme, Icons.group_rounded, '${recipe.raciones}', theme.colorScheme.surfaceVariant),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          _sectionHeader(theme, 'Ingredientes', Icons.shopping_basket_rounded),
          const SizedBox(height: 16),
          ...recipe.ingredientes.map((ing) => _ingredientBubble(theme, ing)),
          
          const SizedBox(height: 40),
          _sectionHeader(theme, 'Pasos a seguir', Icons.auto_fix_high_rounded),
          const SizedBox(height: 16),
          ...recipe.preparacion.asMap().entries.map((entry) => _stepBubble(theme, entry.key + 1, entry.value)),
        ],
      ),
    );
  }

  Widget _buildExpressiveChip(ThemeData theme, IconData icon, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _ingredientBubble(ThemeData theme, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _stepBubble(ThemeData theme, int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
