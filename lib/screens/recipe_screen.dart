import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/recipe/ai_edit_sheet.dart';
import 'package:aikitchen/services/external_link_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/recipe_meta_row.dart';
import 'package:flutter/material.dart';

class RecipeScreen extends StatefulWidget {
  static const String routeName = '/recipe';

  const RecipeScreen({super.key, required this.recipe, this.url});
  final Recipe recipe;
  final String? url;

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
        (r) =>
            r.nombre == showingRecipe.nombre &&
            r.descripcion == showingRecipe.descripcion,
      );
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      AppSingleton().recetasFavoritas.removeWhere(
        (r) =>
            r.nombre == showingRecipe.nombre &&
            r.descripcion == showingRecipe.descripcion,
      );
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(showingRecipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }

    await JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
    await WidgetService.updateFavoritesWidget();
    _checkIfFavorite();
  }

  Future<void> _launchUrl() async {
    if (widget.url != null) {
      if (!await openExternalUrl(widget.url!)) {
        Toaster.showError('No se pudo abrir la web original');
      }
    }
  }

  void _showAiEditOptions() {
    AiEditSheet.show(
      context,
      recipe: showingRecipe,
      onRecipeUpdated: (newRecipe) {
        setState(() {
          showingRecipe = newRecipe;
          // Al modificarla, dejamos de considerarla la misma para favoritos hasta que la guarde
          _isFavorite = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewport = MediaQuery.sizeOf(context);

    // Con ancho de sobra no tiene sentido esconder la mitad de la receta tras
    // una pestaña: se cocina mirando ingredientes y pasos a la vez.
    final sideBySide = viewport.width >= Breakpoints.expanded;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: sideBySide
          ? _buildSideBySide(theme, viewport)
          : _buildTabbed(theme, viewport),
    );
  }

  /// Cabecera común a las dos disposiciones.
  Widget _buildAppBar(ThemeData theme, Size viewport) {
    // En apaisado la pantalla es baja, y una cabecera de 240 se comería un
    // tercio de la vista antes de mostrar nada útil.
    final expandedHeight = viewport.height < 700 ? 150.0 : 240.0;

    return SliverAppBar.large(
      backgroundColor: theme.colorScheme.surface,
      expandedHeight: expandedHeight,
      collapsedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
      pinned: true,
      stretch: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton.filledTonal(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        if (widget.url != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.filledTonal(
              onPressed: _launchUrl,
              icon: const Icon(Icons.language_rounded),
              tooltip: 'Abrir en la web',
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton.filledTonal(
            onPressed: _showAiEditOptions,
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Modificar con IA',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton.filledTonal(
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Quitar de favoritos' : 'Guardar receta',
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color: _isFavorite ? Colors.redAccent : null,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        titlePadding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        centerTitle: false,
        title: Text(
          showingRecipe.nombre,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// Disposición estrecha: dos pestañas, una para cada mitad.
  Widget _buildTabbed(ThemeData theme, Size viewport) {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(theme, viewport),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: ContentShell(child: _buildInfoBadges(theme)),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: ContentShell(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: AppRadius.large,
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadius.large,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.primary,
                      labelStyle: theme.textTheme.labelLarge,
                      tabs: const [
                        Tab(text: 'INGREDIENTES'),
                        Tab(text: 'PREPARACIÓN'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _ScrollableSlide(
              child: _IngredientsSlideContent(
                key: ValueKey('ingredientes_${showingRecipe.nombre}_${showingRecipe.calorias}'),
              ),
            ),
            _ScrollableSlide(
              child: _StepsSlideContent(
                key: ValueKey('pasos_${showingRecipe.nombre}_${showingRecipe.calorias}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Disposición ancha: las dos columnas a la vez dentro de un único
  /// desplazamiento. Ninguna de las dos listas desplaza por su cuenta, así que
  /// no hay controladores que se estorben.
  Widget _buildSideBySide(ThemeData theme, Size viewport) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(theme, viewport),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: ContentShell.wide(child: _buildInfoBadges(theme)),
          ),
        ),
        SliverToBoxAdapter(
          child: ContentShell.wide(
            child: Padding(
              padding: const EdgeInsets.only(
                top: Spacing.xl,
                bottom: Spacing.xxl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _columnLabel(theme, 'INGREDIENTES'),
                        const SizedBox(height: Spacing.lg),
                        _IngredientsSlideContent(
                          key: ValueKey('ingredientes_${showingRecipe.nombre}_${showingRecipe.calorias}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.xxl),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _columnLabel(theme, 'PREPARACIÓN'),
                        const SizedBox(height: Spacing.lg),
                        _StepsSlideContent(
                          key: ValueKey('pasos_${showingRecipe.nombre}_${showingRecipe.calorias}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _columnLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoBadges(ThemeData theme) {
    return RecipeMetaRow(recipe: showingRecipe);
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
  const _IngredientsSlideContent({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RecipeScreenState>()!;
    return IngredientsList(ingredients: state.showingRecipe.ingredientes);
  }
}

class _StepsSlideContent extends StatelessWidget {
  const _StepsSlideContent({super.key});

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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

