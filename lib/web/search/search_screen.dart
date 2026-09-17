import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/web/search/search_service.dart';
import 'package:aikitchen/web/search/search_widgets.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aikitchen/services/external_link_service.dart';

class LidSearchScreen extends StatefulWidget {
  final String? initialUrl;
  final String title;

  const LidSearchScreen({super.key, this.initialUrl, this.title = 'Internet'});

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
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _fetchInitialResults();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialResults() async {
    setState(() => _isSearching = true);
    final results = await _service.fetchRecipesFromUrl(widget.initialUrl!);
    setState(() {
      _isSearching = false;
      _results = results;
    });
  }

  void _onSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _results = [];
    });
    final results = await _service.searchRecipes(query, source: _selectedSource);
    setState(() {
      _isSearching = false;
      _results = results;
    });
    if (results.isEmpty) {
      // Distinguir "no hay resultados" de "la peticion fallo" evita que un
      // bloqueo del navegador parezca una busqueda sin coincidencias.
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
      final Recipe? recipe = await _service.getFullRecipe(result.url);

      if (recipe != null) {
        if (!mounted) return;
        
        // Fallback: Si no hay pasos, abrimos web. Si hay, mostramos pantalla nativa.
        if (recipe.preparacion.isEmpty) {
          await _launchUrl(result.url);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeScreen(
                recipe: recipe,
                url: result.url,
              ),
            ),
          );
        }
      } else {
        await _launchUrl(result.url);
      }
    } catch (e) {
      await _launchUrl(result.url);
    } finally {
      if (mounted) setState(() => _isFetchingRecipe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (widget.initialUrl == null)
                SliverContentShell(
                  sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                      children: [
                        SearchInput(
                          controller: _searchController,
                          onSearch: _onSearch,
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<RecipeSource>(
                          segments: const [
                            ButtonSegment(
                              value: RecipeSource.lidl,
                              label: Text('Lidl'),
                              icon: Icon(Icons.shopping_basket_rounded),
                            ),
                            ButtonSegment(
                              value: RecipeSource.cookpad,
                              label: Text('Cookpad'),
                              icon: Icon(Icons.restaurant_rounded),
                            ),
                          ],
                          selected: {_selectedSource},
                          onSelectionChanged: (Set<RecipeSource> newSelection) {
                            setState(() {
                              _selectedSource = newSelection.first;
                              if (_searchController.text.isNotEmpty) {
                                _onSearch(_searchController.text);
                              }
                            });
                          },
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.comfortable,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),

              if (_isSearching)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Welcome(),
                )
              else
                SliverContentShell(
                  maxWidth: ContentWidth.wide,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisSpacing: Spacing.md,
                            crossAxisSpacing: Spacing.md,
                            // Altura fija en lugar de proporción: la tarjeta
                            // lleva una imagen de 200 px más texto, así que con
                            // una proporción la celda se queda corta en cuanto
                            // la columna se estrecha.
                            mainAxisExtent: 400,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recipeResult = _results[index];
                          return WebRecipeCard(
                            result: recipeResult,
                            onTap: () => _handleRecipeTap(recipeResult),
                          );
                        },
                        childCount: _results.length,
                      ),
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          if (_isFetchingRecipe)
            Container(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Descargando receta...',
                      style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
