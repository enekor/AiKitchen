import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/recetario_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/utils/pantry_matcher.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Modo "Recetario" del centro de búsqueda: las recetas del fichero JSON
/// configurado en Ajustes, con foto, canal y vídeo. No usa la IA. Sin
/// `Scaffold` propio.
class RecetarioScreen extends StatefulWidget {
  const RecetarioScreen({super.key, this.loader});

  /// Para pruebas: sustituye la descarga del recetario.
  @visibleForTesting
  final Future<List<Recipe>> Function(String url, {bool refresh})? loader;

  @override
  State<RecetarioScreen> createState() => _RecetarioScreenState();
}

class _RecetarioScreenState extends State<RecetarioScreen> {
  final _searchController = TextEditingController();
  List<Recipe>? _recipes;
  String? _error;
  bool _loading = false;

  /// Filtro elegido en la fila de chips: `c:` + canal o `e:` + etiqueta.
  String? _filter;

  @override
  void initState() {
    super.initState();
    AppSingleton().recetarioUrl.addListener(_onUrlChanged);
    _load();
  }

  @override
  void dispose() {
    AppSingleton().recetarioUrl.removeListener(_onUrlChanged);
    _searchController.dispose();
    super.dispose();
  }

  String get _url => AppSingleton().recetarioUrl.value;

  void _onUrlChanged() {
    setState(() {
      _recipes = null;
      _filter = null;
    });
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final url = _url;
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final load = widget.loader ?? RecetarioService.instance.load;
      final recipes = await load(url, refresh: refresh);
      if (!mounted || url != _url) return;
      setState(() => _recipes = recipes);
    } on RecetarioException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se ha podido cargar el recetario.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _canales =>
      _sortedUnique([for (final r in _recipes ?? <Recipe>[]) ?r.canal]);

  List<String> get _etiquetas =>
      _sortedUnique([for (final r in _recipes ?? <Recipe>[]) ...r.etiquetas]);

  static List<String> _sortedUnique(Iterable<String> values) {
    final byKey = <String, String>{};
    for (final v in values) {
      if (v.trim().isNotEmpty) byKey.putIfAbsent(PantryMatcher.normalize(v), () => v);
    }
    return byKey.values.toList()
      ..sort((a, b) => PantryMatcher.normalize(a).compareTo(PantryMatcher.normalize(b)));
  }

  List<Recipe> get _visible {
    final query = PantryMatcher.normalize(_searchController.text.trim());
    return (_recipes ?? const <Recipe>[]).where((r) {
      final filter = _filter;
      if (filter != null) {
        final value = filter.substring(2);
        if (filter.startsWith('c:') && r.canal != value) return false;
        if (filter.startsWith('e:') && !r.etiquetas.contains(value)) return false;
      }
      if (query.isEmpty) return true;
      // Busca en el nombre, los ingredientes, las etiquetas y el canal.
      return [r.nombre, ...r.ingredientes, ...r.etiquetas, ?r.canal]
          .any((text) => PantryMatcher.normalize(text).contains(query));
    }).toList()
      ..sort((a, b) => PantryMatcher.normalize(a.nombre).compareTo(PantryMatcher.normalize(b.nombre)));
  }

  bool _isFavorite(Recipe recipe) =>
      AppSingleton().recetasFavoritas.any((r) => r.nombre == recipe.nombre);

  Future<void> _toggleFavorite(Recipe recipe) async {
    final favs = AppSingleton().recetasFavoritas;
    if (_isFavorite(recipe)) {
      final existing = favs.where((r) => r.nombre == recipe.nombre).toList();
      favs.removeWhere((r) => r.nombre == recipe.nombre);
      for (final r in existing) {
        if (r.id != null) await JsonDocumentsService().removeFavRecipe(r.id!);
      }
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      // Se guarda una copia: el id que asigna el almacén no debe acabar en la
      // receta del recetario, que se comparte entre pantallas.
      final copy = recipe.copyWith();
      favs.add(copy);
      await JsonDocumentsService().addFavRecipe(copy);
      Toaster.showSuccess('¡Guardada en favoritos!');
    }
    if (mounted) setState(() {});
  }

  Future<void> _open(Recipe recipe) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.recipe,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
    // Al volver, el marcador de favorito puede haber cambiado.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSingleton().recetarioUrl,
      builder: (context, url, _) {
        if (url.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Sin recetario configurado',
            description:
                'Pon en Ajustes la dirección del fichero JSON de recetas '
                '(por ejemplo, uno publicado en GitHub) para verlas aquí.',
            actionLabel: 'Ir a Ajustes',
            onAction: () => Navigator.pushNamed(context, AppRoutes.settings),
          );
        }
        if (_recipes == null) {
          if (_error != null) return _errorState();
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: _content(),
        );
      },
    );
  }

  Widget _errorState() {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'No se ha podido cargar el recetario',
      description: _error,
      actionLabel: 'Reintentar',
      onAction: () => _load(refresh: true),
    );
  }

  Widget _content() {
    final theme = Theme.of(context);
    final recipes = _visible;
    final filters = <String?>[
      null,
      // Por canal solo si hay más de uno: con uno no filtra nada.
      if (_canales.length > 1) for (final c in _canales) 'c:$c',
      for (final e in _etiquetas) 'e:$e',
    ];

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Busca por nombre, ingrediente o canal...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton.filledTonal(
              onPressed: _loading ? null : () => _load(refresh: true),
              tooltip: 'Actualizar el recetario',
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (filters.length > 1) ...[
          const SizedBox(height: Spacing.md),
          FilterChipBar<String?>(
            options: filters,
            labelOf: (f) => f == null ? 'Todas' : f.substring(2),
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ],
        const SizedBox(height: Spacing.md),
        Text(
          recipes.length == 1 ? '1 receta' : '${recipes.length} recetas',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (recipes.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No hay recetas con esa búsqueda',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Columnas de unos 280 px: una en móvil, tres o cuatro en tableta.
              final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
              final width =
                  (constraints.maxWidth - Spacing.md * (columns - 1)) / columns;
              return Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.md,
                children: [
                  for (final recipe in recipes)
                    SizedBox(
                      width: width,
                      child: _RecetarioCard(
                        recipe: recipe,
                        isFavorite: _isFavorite(recipe),
                        onTap: () => _open(recipe),
                        onToggleFavorite: () => _toggleFavorite(recipe),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Tarjeta con la foto del plato, el canal y los datos básicos.
class _RecetarioCard extends StatelessWidget {
  const _RecetarioCard({
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.restaurant_rounded, size: 40, color: theme.colorScheme.primary),
      ),
    );

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecipePhoto(recipe: recipe, aspectRatio: 16 / 10, fallback: fallback),
                  if (recipe.videoUrl != null)
                    Positioned(
                      left: Spacing.sm,
                      bottom: Spacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_display_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Vídeo',
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: Spacing.xs,
                    top: Spacing.xs,
                    child: IconButton.filledTonal(
                      onPressed: onToggleFavorite,
                      tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      icon: Icon(
                        isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (recipe.canal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    recipe.canal!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.sm),
                RecipeMetaRow(recipe: recipe),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
