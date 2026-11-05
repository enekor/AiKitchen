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
///
/// Muestra siempre la última descarga guardada; las descargas automáticas
/// ocurren en segundo plano sin bloquear la lista. Solo "Actualizar" muestra
/// un indicador de carga.
class RecetarioScreen extends StatefulWidget {
  const RecetarioScreen({super.key, this.service});

  /// Para pruebas: otro servicio en vez del de toda la app.
  @visibleForTesting
  final RecetarioService? service;

  @override
  State<RecetarioScreen> createState() => _RecetarioScreenState();
}

class _RecetarioScreenState extends State<RecetarioScreen> {
  final _searchController = TextEditingController();

  /// Filtro elegido en la fila de chips: `c:` + canal o `e:` + etiqueta.
  String? _filter;

  RecetarioService get _service => widget.service ?? RecetarioService.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final before = _service.updatedAt;
    await _service.refresh(manual: true);
    if (!mounted) return;
    if (_service.updatedAt != before) {
      final count = _service.recipes?.length ?? 0;
      Toaster.showSuccess(
        count == 1 ? 'Recetario actualizado: 1 receta' : 'Recetario actualizado: $count recetas',
      );
    } else if (_service.error != null) {
      Toaster.showError(_service.error!);
    }
  }

  List<String> _canales(List<Recipe> recipes) =>
      _sortedUnique([for (final r in recipes) ?r.canal]);

  List<String> _etiquetas(List<Recipe> recipes) =>
      _sortedUnique([for (final r in recipes) ...r.etiquetas]);

  static List<String> _sortedUnique(Iterable<String> values) {
    final byKey = <String, String>{};
    for (final v in values) {
      if (v.trim().isNotEmpty) byKey.putIfAbsent(PantryMatcher.normalize(v), () => v);
    }
    return byKey.values.toList()
      ..sort((a, b) => PantryMatcher.normalize(a).compareTo(PantryMatcher.normalize(b)));
  }

  List<Recipe> _visible(List<Recipe> all) {
    final query = PantryMatcher.normalize(_searchController.text.trim());
    final filter = _filter;
    return all.where((r) {
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
    return ListenableBuilder(
      listenable: Listenable.merge([AppSingleton().recetarioUrl, _service]),
      builder: (context, _) {
        if (AppSingleton().recetarioUrl.value.isEmpty) {
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

        final recipes = _service.recipes;
        if (recipes == null) {
          // Sin copia guardada: hay que esperar a la primera descarga.
          if (_service.isDownloading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: Spacing.lg),
                  Text('Descargando el recetario...'),
                ],
              ),
            );
          }
          return EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'No se ha podido cargar el recetario',
            description: _service.error,
            actionLabel: 'Reintentar',
            onAction: _refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: _content(recipes),
        );
      },
    );
  }

  Widget _content(List<Recipe> all) {
    final theme = Theme.of(context);
    final recipes = _visible(all);
    final canales = _canales(all);
    final filters = <String?>[
      null,
      // Por canal solo si hay más de uno: con uno no filtra nada.
      if (canales.length > 1) for (final c in canales) 'c:$c',
      for (final e in _etiquetas(all)) 'e:$e',
    ];
    final refreshing = _service.isManualRefresh;

    return ListView(
      // Necesario para que el gesto de deslizar actualice aunque la lista
      // sea corta.
      physics: const AlwaysScrollableScrollPhysics(),
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
            FilledButton.tonalIcon(
              onPressed: refreshing ? null : _refresh,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(refreshing ? 'Actualizando...' : 'Actualizar'),
            ),
          ],
        ),
        if (refreshing) ...[
          const SizedBox(height: Spacing.md),
          const LinearProgressIndicator(),
        ],
        if (filters.length > 1) ...[
          const SizedBox(height: Spacing.md),
          FilterChipBar<String?>(
            options: filters,
            labelOf: (f) => f == null ? 'Todas' : f.substring(2),
            selected: filters.contains(_filter) ? _filter : null,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ],
        const SizedBox(height: Spacing.md),
        Text(
          '${recipes.length == 1 ? '1 receta' : '${recipes.length} recetas'}'
          '${_updatedLabel()}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        // Mientras se actualiza a mano, la lista se atenúa: lo que se ve va a
        // cambiar en cuanto termine.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: refreshing ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: refreshing,
            child: recipes.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No hay recetas con esa búsqueda',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Columnas de unos 280 px: una en móvil, tres o cuatro
                      // en tableta.
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
          ),
        ),
      ],
    );
  }

  /// " · actualizado hoy", " · actualizado hace 3 días"...
  String _updatedLabel() {
    final updated = _service.updatedAt;
    if (updated == null) return '';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(updated.year, updated.month, updated.day))
        .inDays;
    final when = switch (days) {
      <= 0 => 'hoy',
      1 => 'ayer',
      _ => 'hace $days días',
    };
    return ' · actualizado $when';
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
