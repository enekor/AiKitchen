import 'dart:io';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeScreen extends StatefulWidget {
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
    if (Platform.isAndroid) await WidgetService.updateFavoritesWidget();
    _checkIfFavorite();
  }

  Future<void> _launchUrl() async {
    if (widget.url != null) {
      if (!await launchUrl(
        Uri.parse(widget.url!),
        mode: LaunchMode.externalApplication,
      )) {
        Toaster.showError('No se pudo abrir la web original');
      }
    }
  }

  void _showAiEditOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AiEditBottomSheet(
        recipe: showingRecipe,
        onRecipeUpdated: (newRecipe) {
          setState(() {
            showingRecipe = newRecipe;
            // Al modificarla, dejamos de considerarla la misma para favoritos hasta que la guarde
            _isFavorite = false;
          });
        },
      ),
    );
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
              collapsedHeight:
                  kToolbarHeight + MediaQuery.of(context).padding.top,
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
                  horizontal: 24,
                  vertical: 16,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: _buildInfoBadges(theme),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
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
                      labelStyle: GoogleFonts.robotoFlex(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 12,
                      ),
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
          body: TabBarView(
            children: [
              _ScrollableSlide(
                child: _IngredientsSlideContent(
                  key: ValueKey(
                    'ingredients_${showingRecipe.nombre}_${showingRecipe.calorias}',
                  ),
                ),
              ),
              _ScrollableSlide(
                child: _StepsSlideContent(
                  key: ValueKey(
                    'steps_${showingRecipe.nombre}_${showingRecipe.calorias}',
                  ),
                ),
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
          _expressiveBadge(
            theme,
            Icons.timer_rounded,
            showingRecipe.tiempoEstimado,
            theme.colorScheme.primaryContainer,
          ),
          const SizedBox(width: 12),
          _expressiveBadge(
            theme,
            Icons.local_fire_department_rounded,
            '${showingRecipe.calorias.toInt()} cal',
            theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 12),
          _expressiveBadge(
            theme,
            Icons.group_rounded,
            '${showingRecipe.raciones} pers.',
            theme.colorScheme.tertiaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _expressiveBadge(
    ThemeData theme,
    IconData icon,
    String text,
    Color color,
  ) {
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
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
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

class _AiEditBottomSheet extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onRecipeUpdated;

  const _AiEditBottomSheet({
    required this.recipe,
    required this.onRecipeUpdated,
  });

  @override
  State<_AiEditBottomSheet> createState() => _AiEditBottomSheetState();
}

class _AiEditBottomSheetState extends State<_AiEditBottomSheet> {
  bool _isProcessing = false;

  void _processAiRequest(String prompt) async {
    setState(() => _isProcessing = true);

    try {
      final response = await AppSingleton().generateContent(prompt, context);

      if (response.isNotEmpty && !response.contains('error')) {
        String cleanedResponse = response;
        cleanedResponse = cleanedResponse.replaceAll(
          RegExp(r'^```json\s*', multiLine: true),
          '',
        );
        cleanedResponse = cleanedResponse.replaceAll(
          RegExp(r'\s*```$', multiLine: true),
          '',
        );

        final newRecipeList = Recipe.fromJsonList(cleanedResponse);
        if (newRecipeList.isNotEmpty) {
          widget.onRecipeUpdated(newRecipeList.first);
          if (mounted) Navigator.pop(context); // Cerrar bottom sheet
          Toaster.showSuccess('¡Receta modificada mágicamente!');
        } else {
          Toaster.showError('La IA no devolvió una receta válida');
        }
      } else {
        Toaster.showError('Algo ha fallado: ${response.split(":").last}');
      }
    } catch (e) {
      Toaster.showError('Error al modificar la receta: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeJsonStr = '[${widget.recipe.toJson().toString()}]';

    if (_isProcessing) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LottieAnimationWidget(type: LottieAnimationType.loading),
              SizedBox(height: 16),
              Text(
                'Cocinando modificaciones...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(width: 12),
              Text(
                'EDICIÓN MÁGICA',
                style: GoogleFonts.robotoFlex(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _EditOption(
            icon: Icons.timer_rounded,
            title: 'Versión Exprés',
            subtitle: 'Haz que sea más rápida de cocinar',
            color: Colors.orange,
            onTap: () => _processAiRequest(
              Prompt.UpdateRecipePromptExpress(recipeJsonStr),
            ),
          ),
          _EditOption(
            icon: Icons.favorite_outline_rounded,
            title: 'Más Saludable',
            subtitle: 'Reduce grasas y calorías',
            color: Colors.green,
            onTap: () => _processAiRequest(
              Prompt.UpdateRecipePromptSaludable(recipeJsonStr),
            ),
          ),
          _EditOption(
            icon: Icons.eco_rounded,
            title: 'Hacer Vegana',
            subtitle: 'Sustituye ingredientes de origen animal',
            color: Colors.lightGreen,
            onTap: () => _processAiRequest(
              Prompt.UpdateRecipePromptDieta(recipeJsonStr, "Vegana"),
            ),
          ),
          _EditOption(
            icon: Icons.scale_rounded,
            title: 'Cambiar Unidades',
            subtitle: 'A tazas, cucharadas, pizcas...',
            color: Colors.blueAccent,
            onTap: () => _processAiRequest(
              Prompt.UpdateRecipePromptUnidades(recipeJsonStr),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EditOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
