import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/services/external_link_service.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/web/search/search_service.dart';
import 'package:aikitchen/web/search/search_widgets.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Modo "de internet" del centro de búsqueda. Sin `Scaffold` propio: es el
/// único de los cuatro modos cuyas tarjetas muestran fotografía, porque el
/// raspado de Lidl y Cookpad sí la trae.
class LidSearchScreen extends StatefulWidget {
  const LidSearchScreen({super.key});

  @override
  State<LidSearchScreen> createState() => _LidSearchScreenState();
}

class _LidSearchScreenState extends State<LidSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _service = SearchService();
  List<WebRecipeResult> _results = [];
  bool _isSearching = false;
  bool _isFetchingRecipe = false;
  RecipeSource _selectedSource = RecipeSource.lidl;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _results = [];
    });
    final results = await _service.searchRecipes(query, source: _selectedSource);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _results = results;
    });
    if (results.isEmpty) {
      final error = _service.lastError;
      if (error != null) {
        Toaster.showError(error);
      } else {
        Toaster.showWarning('No se han encontrado recetas para "$query"');
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await openExternalUrl(url)) {
      Toaster.showError('No se pudo abrir la web original');
    }
  }

  Future<void> _handleRecipeTap(WebRecipeResult result) async {
    setState(() => _isFetchingRecipe = true);
    try {
      final recipe = await _service.getFullRecipe(result.url);
      if (recipe != null) {
        if (!mounted) return;
        if (recipe.preparacion.isEmpty) {
          await _launchUrl(result.url);
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.recipe,
            arguments: RecipeScreenArguments(
              recipe: Recipe(
                nombre: recipe.nombre,
                descripcion: recipe.descripcion,
                tiempoEstimado: recipe.tiempoEstimado,
                ingredientes: recipe.ingredientes,
                preparacion: recipe.preparacion,
                calorias: recipe.calorias,
                raciones: recipe.raciones,
                origen: RecipeOrigin.web,
              ),
            ),
          );
        }
      } else {
        await _launchUrl(result.url);
      }
    } catch (_) {
      await _launchUrl(result.url);
    } finally {
      if (mounted) setState(() => _isFetchingRecipe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(Spacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      hintText: 'Arroz, curry, merluza...',
                      onSubmitted: _onSearch,
                    ),
                    const SizedBox(height: Spacing.md),
                    SegmentedButton<RecipeSource>(
                      segments: const [
                        ButtonSegment(
                          value: RecipeSource.lidl,
                          label: Text('Lidl'),
                          icon: Icon(Icons.shopping_basket_outlined),
                        ),
                        ButtonSegment(
                          value: RecipeSource.cookpad,
                          label: Text('Cookpad'),
                          icon: Icon(Icons.restaurant_outlined),
                        ),
                      ],
                      selected: {_selectedSource},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedSource = selection.first);
                        if (_searchController.text.isNotEmpty) {
                          _onSearch(_searchController.text);
                        }
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
            ),
            if (_isSearching)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_results.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Welcome())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisSpacing: Spacing.md,
                    crossAxisSpacing: Spacing.md,
                    // Altura fija en lugar de proporción: la tarjeta lleva una
                    // imagen de proporción fija más texto de longitud
                    // variable, y con una proporción la celda se queda corta
                    // en cuanto la columna se estrecha.
                    mainAxisExtent: 320,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final result = _results[index];
                      return WebRecipeCard(
                        result: result,
                        onImport: () => _handleRecipeTap(result),
                        onOpenWeb: () => _launchUrl(result.url),
                      );
                    },
                    childCount: _results.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
          ],
        ),
        if (_isFetchingRecipe)
          Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: Spacing.lg),
                  Text('Descargando receta...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
