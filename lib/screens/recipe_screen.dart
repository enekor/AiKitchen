import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/recipe/ai_edit_sheet.dart';
import 'package:aikitchen/services/external_link_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Detalle de una receta. Sigue de cerca el diseño de referencia: cabecera
/// destacada, distintivos de tiempo/calorías/raciones, fila de acciones,
/// aviso de lectura en voz alta y las dos secciones en pestañas o en columnas
/// según el ancho disponible.
///
/// El diseño de referencia usa una fotografía de la receta; aquí no hay
/// ninguna, porque las recetas generadas por IA no tienen imagen y el modelo
/// no la guarda. Se sustituye por un bloque de color con el mismo peso visual
/// en vez de dejar un hueco o forzar una imagen que no existe.
class RecipeScreen extends StatefulWidget {
  static const String routeName = '/recipe';

  const RecipeScreen({super.key, required this.recipe, this.url});
  final Recipe recipe;
  final String? url;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late Recipe showingRecipe;
  late TabController _tabController;
  late IngredientsController _ingredientsController;
  late StepsController _stepsController;

  /// Marca dónde empieza la sección de ingredientes y pasos, para poder
  /// desplazar la vista hasta ahí al iniciar la lectura guiada.
  final GlobalKey _stepsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    showingRecipe = widget.recipe;
    _tabController = TabController(length: 2, vsync: this);
    _initControllers();
    _checkIfFavorite();
  }

  void _initControllers() {
    _ingredientsController = IngredientsController(showingRecipe.ingredientes.length);
    _stepsController = StepsController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
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

  void _shareRecipe() {
    ShareRecipeService().shareRecipe([showingRecipe]);
  }

  void _showAiEditOptions() {
    AiEditSheet.show(
      context,
      recipe: showingRecipe,
      onRecipeUpdated: (newRecipe) {
        setState(() {
          showingRecipe = newRecipe;
          // Al modificarla, dejamos de considerarla la misma para favoritos
          // hasta que la guarde, y los marcados dejan de tener sentido porque
          // los ingredientes y pasos pueden haber cambiado.
          _isFavorite = false;
          _ingredientsController.dispose();
          _stepsController.dispose();
          _initControllers();
        });
      },
    );
  }

  /// Inicia la lectura guiada y salta a la pestaña de preparación, tal como
  /// hace el botón "Iniciar" del diseño de referencia.
  ///
  /// También desplaza la vista hasta los pasos: el cambio ocurre más abajo de
  /// la franja, fuera de la pantalla, y sin este desplazamiento parecía que
  /// pulsar "Iniciar" no hacía nada.
  void _startGuidedReading() {
    _stepsController.start();
    _tabController.animateTo(1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _stepsSectionKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    // Con ancho de sobra no tiene sentido esconder la mitad de la receta tras
    // una pestaña: se cocina mirando ingredientes y pasos a la vez.
    final sideBySide = viewport.width >= Breakpoints.expanded;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de receta')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        children: [
          ContentShell.wide(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(recipe: showingRecipe),
                const SizedBox(height: Spacing.lg),
                _MetricsRow(recipe: showingRecipe),
                const SizedBox(height: Spacing.lg),
                _ActionsRow(
                  isFavorite: _isFavorite,
                  hasUrl: widget.url != null,
                  onToggleFavorite: _toggleFavorite,
                  onShare: _shareRecipe,
                  onOpenUrl: _launchUrl,
                  onModifyWithAi: _showAiEditOptions,
                ),
                const SizedBox(height: Spacing.lg),
                _VoiceReadingBanner(onStart: _startGuidedReading),
                const SizedBox(height: Spacing.xl),
                sideBySide
                    ? _SideBySideContent(
                        key: _stepsSectionKey,
                        recipe: showingRecipe,
                        ingredientsController: _ingredientsController,
                        stepsController: _stepsController,
                      )
                    : _TabbedContent(
                        key: _stepsSectionKey,
                        recipe: showingRecipe,
                        tabController: _tabController,
                        ingredientsController: _ingredientsController,
                        stepsController: _stepsController,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera destacada. Sustituye a la fotografía del diseño de referencia por
/// un bloque de color con el mismo peso visual: título y descripción sobre un
/// fondo de color en vez de sobre una imagen que no existe.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.nombre,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          if (recipe.descripcion.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              recipe.descripcion,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de tres tarjetas: tiempo, calorías y raciones. El diseño de
/// referencia incluye una cuarta con la dificultad, que no forma parte del
/// modelo de datos y por eso no está aquí.
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.timer_outlined,
            label: 'Tiempo',
            value: recipe.tiempoEstimado,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Calorías',
            value: '${recipe.calorias} kcal',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.people_alt_outlined,
            label: 'Raciones',
            value: '${recipe.raciones} pers.',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.sm),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Favorito, compartir, abrir la web original y modificar con IA, en el mismo
/// orden que el diseño de referencia.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isFavorite,
    required this.hasUrl,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onOpenUrl,
    required this.onModifyWithAi,
  });

  final bool isFavorite;
  final bool hasUrl;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onOpenUrl;
  final VoidCallback onModifyWithAi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onToggleFavorite,
          tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar',
          icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        IconButton.filledTonal(
          onPressed: onShare,
          tooltip: 'Compartir',
          icon: const Icon(Icons.share_outlined),
        ),
        if (hasUrl) ...[
          const SizedBox(width: Spacing.sm),
          IconButton.filledTonal(
            onPressed: onOpenUrl,
            tooltip: 'Abrir en la web',
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: AiButton(
            label: 'Modificar con IA',
            onPressed: onModifyWithAi,
            expand: true,
          ),
        ),
      ],
    );
  }
}

/// Aviso de lectura en voz alta, con su propio interruptor para activar o
/// desactivar la voz sin tener que ir a Ajustes. "Iniciar" arranca la
/// preparación guiada y salta a esa sección, igual que en el diseño.
///
/// Los colores salen de `tertiaryContainer`, que vale igual en claro y en
/// oscuro. Antes usaba `inverseSurface`, que por definición se invierte con el
/// brillo del tema: en modo oscuro la franja salía casi blanca y el contenido
/// se perdía contra el fondo.
class _VoiceReadingBanner extends StatefulWidget {
  const _VoiceReadingBanner({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_VoiceReadingBanner> createState() => _VoiceReadingBannerState();
}

class _VoiceReadingBannerState extends State<_VoiceReadingBanner> {
  late bool _ttsEnabled = AppSingleton().useTTS;

  void _setTts(bool value) {
    // Es el mismo ajuste que hay en la pantalla de Ajustes: se guarda en el
    // mismo sitio, así que el cambio hecho aquí se ve allí y al revés.
    setState(() {
      _ttsEnabled = value;
      AppSingleton().setUseTTS = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.tertiaryContainer;
    final foreground = theme.colorScheme.onTertiaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, color: foreground),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'Lectura en voz alta',
                  style: theme.textTheme.titleSmall?.copyWith(color: foreground),
                ),
              ),
              Text(
                _ttsEnabled ? 'Activada' : 'Desactivada',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.85),
                ),
              ),
              Switch(
                value: _ttsEnabled,
                onChanged: _setTts,
                activeThumbColor: foreground,
                activeTrackColor: foreground.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  _ttsEnabled
                      ? 'Los pasos se leerán solos mientras cocinas.'
                      : 'Actívala para escuchar los pasos con las manos libres.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton.icon(
                onPressed: widget.onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Iniciar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cabecera de la sección de ingredientes: contador de marcados y acción de
/// desmarcar todos, como en el diseño de referencia.
class _IngredientsSectionHeader extends StatelessWidget {
  const _IngredientsSectionHeader({required this.controller});

  final IngredientsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${controller.markedCount} de ${controller.total} marcados',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: controller.markedCount == 0 ? null : controller.clearAll,
              child: const Text('Desmarcar todos'),
            ),
          ],
        );
      },
    );
  }
}

/// Disposición estrecha: pestañas en forma de píldora, con el recuento de
/// cada sección en la etiqueta.
class _TabbedContent extends StatelessWidget {
  const _TabbedContent({
    super.key,
    required this.recipe,
    required this.tabController,
    required this.ingredientsController,
    required this.stepsController,
  });

  final Recipe recipe;
  final TabController tabController;
  final IngredientsController ingredientsController;
  final StepsController stepsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: AppRadius.large,
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.large,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.labelLarge,
            tabs: [
              Tab(text: 'Ingredientes (${recipe.ingredientes.length})'),
              Tab(text: 'Preparación (${recipe.preparacion.length})'),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            return tabController.index == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IngredientsSectionHeader(controller: ingredientsController),
                      const SizedBox(height: Spacing.md),
                      IngredientsList(
                        ingredients: recipe.ingredientes,
                        controller: ingredientsController,
                      ),
                    ],
                  )
                : StepsList(steps: recipe.preparacion, controller: stepsController);
          },
        ),
      ],
    );
  }
}

/// Disposición ancha: las dos columnas a la vez, sin pestañas.
class _SideBySideContent extends StatelessWidget {
  const _SideBySideContent({
    super.key,
    required this.recipe,
    required this.ingredientsController,
    required this.stepsController,
  });

  final Recipe recipe;
  final IngredientsController ingredientsController;
  final StepsController stepsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredientes (${recipe.ingredientes.length})',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Spacing.sm),
              _IngredientsSectionHeader(controller: ingredientsController),
              const SizedBox(height: Spacing.md),
              IngredientsList(
                ingredients: recipe.ingredientes,
                controller: ingredientsController,
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
              Text(
                'Preparación (${recipe.preparacion.length})',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Spacing.lg),
              StepsList(steps: recipe.preparacion, controller: stepsController),
            ],
          ),
        ),
      ],
    );
  }
}
