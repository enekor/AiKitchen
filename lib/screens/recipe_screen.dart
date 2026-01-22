import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool _isFavorite = false;
  late Recipe showingRecipe;

  @override
  void initState() {
    super.initState();
    showingRecipe = widget.recipe;
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    setState(() {
      _isFavorite = AppSingleton().recetasFavoritas.any(
        (r) => r.nombre == showingRecipe.nombre && r.descripcion == showingRecipe.descripcion,
      );
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      AppSingleton().recetasFavoritas.removeWhere(
        (r) => r.nombre == showingRecipe.nombre && r.descripcion == showingRecipe.descripcion,
      );
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(showingRecipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }

    await JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
    if (Platform.isAndroid) await WidgetService.updateFavoritesWidget();
    _checkIfFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar.large(
              backgroundColor: theme.colorScheme.surface,
              expandedHeight: 240,
              collapsedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
              pinned: true,
              stretch: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton.filledTonal(
                    onPressed: _toggleFavorite,
                    icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                    color: _isFavorite ? Colors.redAccent : null,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                centerTitle: false,
                title: Text(
                  showingRecipe.nombre,
                  style: GoogleFonts.robotoFlex(
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildInfoBadges(theme),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.primary,
                      labelStyle: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                      tabs: const [
                        Tab(text: 'INGREDIENTES'),
                        Tab(text: 'PREPARACIÓN'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              // Slide 1: Ingredientes
              _ScrollableSlide(
                child: _IngredientsSlideContent(),
              ),
              // Slide 2: Preparación
              _ScrollableSlide(
                child: _StepsSlideContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadges(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _expressiveBadge(theme, Icons.timer_rounded, showingRecipe.tiempoEstimado, theme.colorScheme.primaryContainer),
          const SizedBox(width: 12),
          _expressiveBadge(theme, Icons.local_fire_department_rounded, '${showingRecipe.calorias.toInt()} cal', theme.colorScheme.secondaryContainer),
          const SizedBox(width: 12),
          _expressiveBadge(theme, Icons.group_rounded, '${showingRecipe.raciones} pers.', theme.colorScheme.tertiaryContainer),
        ],
      ),
    );
  }

  Widget _expressiveBadge(ThemeData theme, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _ScrollableSlide extends StatelessWidget {
  final Widget child;
  const _ScrollableSlide({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      child: child,
    );
  }
}

class _IngredientsSlideContent extends StatelessWidget {
  const _IngredientsSlideContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RecipeScreenState>()!;
    return IngredientsList(ingredients: state.showingRecipe.ingredientes);
  }
}

class _StepsSlideContent extends StatelessWidget {
  const _StepsSlideContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RecipeScreenState>()!;
    return StepsList(steps: state.showingRecipe.preparacion);
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 88;
  @override
  double get maxExtent => 88;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
