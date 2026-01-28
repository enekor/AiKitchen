import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/web/search/search_service.dart';
import 'package:aikitchen/web/search/search_widgets.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
    setState(() {
      _isSearching = true;
    });
    
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
    
    final results = await _service.searchRecipes(query);
    
    setState(() {
      _isSearching = false;
      _results = results;
    });

    if (results.isEmpty) {
      Toaster.showWarning('No se han encontrado recetas para "$query"');
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      Toaster.showError('No se pudo abrir la web original');
    }
  }

  Future<void> _handleRecipeTap(WebRecipeResult result) async {
    setState(() {
      _isFetchingRecipe = true;
    });

    try {
      Recipe? recipe = await _service.getFullRecipe(result.url);

      if (recipe != null) {
        if (!mounted) return;
        
        if (recipe.preparacion.isEmpty) {
          Toaster.showWarning('Volviendo a intentar...');
          recipe = await _service.getFullRecipe(result.url);
          if (recipe!.preparacion.isEmpty){await _launchUrl(result.url);}

        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeScreen(
                recipe: recipe!,
                url: result.url,
              ),
            ),
          );
        }
      } else {
        await _launchUrl(result.url);
      }
    } catch (e) {
      Toaster.showError('Error al obtener la receta: $e');
      await _launchUrl(result.url);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRecipe = false;
        });
      }
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
              /*SliverAppBar.large(
                backgroundColor: theme.colorScheme.surface,
                expandedHeight: 180,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  title: Text(
                    widget.title,
                    style: GoogleFonts.robotoFlex(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),*/
              
              if (widget.initialUrl == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SearchInput(
                      controller: _searchController,
                      onSearch: _onSearch,
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
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          if (_isFetchingRecipe)
            Container(
              color: theme.colorScheme.surface.withOpacity(0.8),
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
