import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/preview_shared_recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/platform/platform_info.dart' as platform;
import 'package:aikitchen/services/recipe_from_file_service.dart';
import 'package:aikitchen/services/recipe_photo_service.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/responsive_card_list.dart';
import 'package:aikitchen/widgets/tag_editor_sheet.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum _OriginFilter { todas, manual, ia, web }

/// Destino "Favoritos" del armazón de navegación.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<Recipe> _selectedRecipes = {};
  List<Recipe> _allRecipes = [];
  _OriginFilter _filter = _OriginFilter.todas;

  /// Etiqueta por la que se filtra; `null` para no filtrar.
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final recipes = await JsonDocumentsService().getFavRecipes();
    if (!mounted) return;
    setState(() {
      AppSingleton().recetasFavoritas = recipes;
      _allRecipes = recipes;
    });
  }

  /// Todas las etiquetas usadas en favoritos, sin repetir y ordenadas.
  List<String> get _allTags {
    final byKey = <String, String>{};
    for (final r in _allRecipes) {
      for (final t in r.etiquetas) {
        byKey.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    return byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<Recipe> get _visibleRecipes {
    final query = _searchController.text.toLowerCase();
    final tag = _tagFilter?.toLowerCase();
    return _allRecipes.where((r) {
      final matchesQuery = query.isEmpty ||
          r.nombre.toLowerCase().contains(query) ||
          r.etiquetas.any((t) => t.toLowerCase().contains(query));
      final matchesTag = tag == null ||
          r.etiquetas.any((t) => t.toLowerCase() == tag);
      final matchesFilter = switch (_filter) {
        _OriginFilter.todas => true,
        _OriginFilter.manual => r.origenEfectivo == RecipeOrigin.manual,
        _OriginFilter.ia => r.origenEfectivo == RecipeOrigin.ia,
        _OriginFilter.web => r.origenEfectivo == RecipeOrigin.web,
      };
      return matchesQuery && matchesFilter && matchesTag;
    }).toList();
  }

  void _shareRecipes() async {
    if (_selectedRecipes.isEmpty) return;
    await ShareRecipeService().shareRecipe(_selectedRecipes.toList());
    setState(() {
      _isSelectionMode = false;
      _selectedRecipes.clear();
    });
  }

  void _onClickRecipe(Recipe receta) {
    if (_isSelectionMode) {
      _toggleSelection(receta);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.recipe,
        arguments: RecipeScreenArguments(recipe: receta),
      );
    }
  }

  void _toggleSelectAll(List<Recipe> visibleRecipes) {
    setState(() {
      final allVisibleSelected = visibleRecipes.every((r) => _selectedRecipes.contains(r));

      if (allVisibleSelected) {
        for (final r in visibleRecipes) {
          _selectedRecipes.remove(r);
        }
        if (_selectedRecipes.isEmpty) _isSelectionMode = false;
      } else {
        _selectedRecipes.addAll(visibleRecipes);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelection(Recipe receta) {
    setState(() {
      if (_selectedRecipes.contains(receta)) {
        _selectedRecipes.remove(receta);
        if (_selectedRecipes.isEmpty) _isSelectionMode = false;
      } else {
        _selectedRecipes.add(receta);
        _isSelectionMode = true;
      }
    });
  }

  void _onEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRecipe(recipe: recipe)),
    ).then((_) => _loadFavorites());
  }

  void _removeFavorite(Recipe recipe) {
    setState(() {
      AppSingleton().recetasFavoritas.removeWhere((r) => _sameRecipe(r, recipe));
      _allRecipes.removeWhere((r) => _sameRecipe(r, recipe));
      _selectedRecipes.remove(recipe);
      if (_selectedRecipes.isEmpty) _isSelectionMode = false;
    });
    // Se borra solo esta receta. Reescribir la lista entera, como antes, es
    // muy costoso ahora que las recetas pueden llevar foto.
    if (recipe.id != null) {
      JsonDocumentsService().removeFavRecipe(recipe.id!);
    } else {
      JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
    }
    Toaster.showWarning('Receta eliminada');
  }

  bool _sameRecipe(Recipe a, Recipe b) =>
      a.id != null && b.id != null ? a.id == b.id : a.nombre == b.nombre;

  /// Guarda una receta modificada (foto o etiquetas) y la sustituye en las
  /// listas en memoria.
  Future<bool> _saveRecipe(Recipe updated) async {
    try {
      await JsonDocumentsService().updateFavRecipe(updated);
    } catch (e) {
      debugPrint('Error guardando la receta: $e');
      // En navegador el almacenamiento es limitado y una foto puede no caber.
      Toaster.showError('No se ha podido guardar. Puede que no quede espacio.');
      return false;
    }
    if (!mounted) return true;
    setState(() {
      void replace(List<Recipe> list) {
        final i = list.indexWhere((r) => _sameRecipe(r, updated));
        if (i != -1) list[i] = updated;
      }

      replace(_allRecipes);
      replace(AppSingleton().recetasFavoritas);
    });
    return true;
  }

  Future<void> _pickPhoto(Recipe recipe) async {
    final foto = await RecipePhotoService.pickPhoto();
    if (foto == null) return;
    if (await _saveRecipe(recipe.copyWith(foto: foto))) {
      Toaster.showSuccess('Foto guardada');
    }
  }

  Future<void> _onPhoto(Recipe recipe) async {
    if (!recipe.tieneFoto) {
      await _pickPhoto(recipe);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Cambiar foto'),
              onTap: () => Navigator.pop(context, 'cambiar'),
            ),
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: const Text('Quitar foto'),
              onTap: () => Navigator.pop(context, 'quitar'),
            ),
          ],
        ),
      ),
    );
    if (action == 'cambiar') {
      await _pickPhoto(recipe);
    } else if (action == 'quitar') {
      if (await _saveRecipe(recipe.copyWith(sinFoto: true))) {
        Toaster.showWarning('Foto quitada');
      }
    }
  }

  Future<void> _onTags(Recipe recipe) async {
    final tags = await TagEditorSheet.show(
      context,
      initialTags: recipe.etiquetas,
      knownTags: _allTags,
    );
    if (tags == null) return;
    await _saveRecipe(recipe.copyWith(etiquetas: tags));
    // Si se quita la etiqueta por la que se filtraba, se deja de filtrar.
    if (_tagFilter != null && !_allTags.contains(_tagFilter)) {
      setState(() => _tagFilter = null);
    }
  }

  Future<void> _openSharedRecipe() async {
    try {
      if (platform.isAndroid) {
        final plugin = DeviceInfoPlugin();
        final androidInfo = await plugin.androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            Toaster.showWarning(
              'Se requiere permiso para leer archivos en esta versión de Android',
            );
            return;
          }
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (!picked.name.toLowerCase().endsWith('.aikr')) {
        Toaster.showWarning('Por favor, selecciona un archivo .aikr');
        return;
      }

      Widget preview;
      if (picked.path != null) {
        preview = PreviewSharedFiles(recipeUri: picked.path!);
      } else if (picked.bytes != null) {
        preview = PreviewSharedFiles(
          recipes: RecipeFromFileService().loadRecipesFromBytes(picked.bytes!),
        );
      } else {
        Toaster.showError('No se ha podido leer el archivo');
        return;
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => preview))
            .then((_) => _loadFavorites());
      }
    } catch (e) {
      debugPrint('Error al abrir el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _visibleRecipes;
    final allVisibleSelected = recipes.isNotEmpty && recipes.every((r) => _selectedRecipes.contains(r));

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedRecipes.clear();
                }),
              ),
              title: Text('${_selectedRecipes.length} seleccionadas'),
              actions: [
                TextButton(
                  onPressed: () => _toggleSelectAll(recipes),
                  child: Text(allVisibleSelected ? 'Deseleccionar' : 'Seleccionar todas'),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _shareRecipes,
                  tooltip: 'Compartir seleccionadas',
                ),
                const SizedBox(width: Spacing.sm),
              ],
            )
          : AppBar(
              title: Text('Favoritos (${_allRecipes.length})'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: 'Importar receta (.aikr)',
                  onPressed: _openSharedRecipe,
                ),
                const SizedBox(width: Spacing.sm),
              ],
            ),
      body: ContentShell.wide(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Buscar entre tus favoritas...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            FilterChipBar<_OriginFilter>(
              options: _OriginFilter.values,
              labelOf: (f) => switch (f) {
                _OriginFilter.todas => 'Todas',
                _OriginFilter.manual => 'Creadas por mí',
                _OriginFilter.ia => 'Generadas con IA',
                _OriginFilter.web => 'Importadas de web',
              },
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            if (_allTags.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              FilterChipBar<String?>(
                options: [null, ..._allTags],
                labelOf: (t) => t ?? 'Todas las etiquetas',
                selected: _tagFilter,
                onChanged: (t) => setState(() => _tagFilter = t),
              ),
            ],
            const SizedBox(height: Spacing.md),
            Expanded(
              child: recipes.isEmpty
                  ? EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: _allRecipes.isEmpty
                          ? 'Aún no tienes recetas guardadas'
                          : 'No hay recetas con ese filtro',
                      description: _allRecipes.isEmpty
                          ? 'Las recetas que guardes aparecerán aquí.'
                          : null,
                    )
                  : ResponsiveCardList(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final recipe in recipes)
                          _FavouriteCard(
                            recipe: recipe,
                            isSelected: _selectedRecipes.contains(recipe),
                            isSelectionMode: _isSelectionMode,
                            onTap: () => _onClickRecipe(recipe),
                            onLongPress: () => setState(() {
                              _isSelectionMode = true;
                              _toggleSelection(recipe);
                            }),
                            onEdit: () => _onEditRecipe(recipe),
                            onDelete: () => _removeFavorite(recipe),
                            onShare: () => ShareRecipeService().shareRecipe([recipe]),
                            onPhoto: () => _onPhoto(recipe),
                            onTags: () => _onTags(recipe),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard({
    required this.recipe,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onPhoto,
    required this.onTags,
  });

  final Recipe recipe;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onPhoto;
  final VoidCallback onTags;

  String get _originLabel => switch (recipe.origenEfectivo) {
    RecipeOrigin.manual => 'Manual',
    RecipeOrigin.ia => 'IA',
    RecipeOrigin.web => 'Web',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        color: isSelected ? theme.colorScheme.primaryContainer : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sin foto no se reserva hueco: la tarjeta queda como siempre.
            if (recipe.tieneFoto) ...[
              RecipePhoto(recipe: recipe, borderRadius: AppRadius.small),
              const SizedBox(height: Spacing.md),
            ],
            Row(
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: AppRadius.capsule,
                  ),
                  child: Text(
                    _originLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              recipe.nombre,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.xs),
            RecipeMetaRow(recipe: recipe),
            if (recipe.etiquetas.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.xs,
                runSpacing: Spacing.xs,
                children: [
                  for (final tag in recipe.etiquetas)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: AppRadius.capsule,
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!isSelectionMode) ...[
              const SizedBox(height: Spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onTags,
                    icon: const Icon(Icons.label_outline_rounded, size: 20),
                    tooltip: 'Etiquetas',
                  ),
                  IconButton(
                    onPressed: onPhoto,
                    icon: Icon(
                      recipe.tieneFoto
                          ? Icons.photo_camera_back_outlined
                          : Icons.add_a_photo_outlined,
                      size: 20,
                    ),
                    tooltip: recipe.tieneFoto ? 'Foto del plato' : 'Añadir foto',
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: 'Eliminar',
                  ),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: 'Compartir',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
