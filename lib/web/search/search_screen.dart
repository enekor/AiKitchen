import 'package:aikitchen/web/search/search_service.dart';
import 'package:aikitchen/web/search/search_widgets.dart';
import 'package:aikitchen/web/search/web_recipe_result.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _service = SearchService();
  List<WebRecipeResult> _results = [];
  bool _isSearching = false;

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
      Toaster.showError('No se pudo abrir el enlace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
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
                'Internet',
                style: GoogleFonts.robotoFlex(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          
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
                    final recipe = _results[index];
                    return WebRecipeCard(
                      result: recipe,
                      onTap: () => _launchUrl(recipe.url),
                    );
                  },
                  childCount: _results.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
