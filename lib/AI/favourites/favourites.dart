import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/screens/preview_shared_recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  bool _isSelectionMode = false;
  final Set<Recipe> _selectedRecipes = {};
  List<Recipe> _filteredReipes = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final recipes = await JsonDocumentsService().getFavRecipes();
    setState(() {
      AppSingleton().recetasFavoritas = recipes;
    });

    _filteredReipes = recipes;
  }

  void _filterRecipes(String query) {
    setState(() {
      _filteredReipes = AppSingleton().recetasFavoritas
          .where((r) => r.nombre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecipeScreen(recipe: receta)),
      );
    }
  }

  void _toggleSelection(Recipe receta) {
    setState(() {
      if (_selectedRecipes.contains(receta)) {
        _selectedRecipes.remove(receta);
        if (_selectedRecipes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedRecipes.add(receta);
      }
    });
  }

  void _onEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRecipe(recipe: recipe)),
    );
  }

  void _removeFavorite(Recipe recipe) {
    setState(() {
      AppSingleton().recetasFavoritas.removeWhere(
        (r) => r.nombre == recipe.nombre,
      );
      _selectedRecipes.remove(recipe);
      if (_selectedRecipes.isEmpty) _isSelectionMode = false;
    });
    JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
    Toaster.showWarning('Receta eliminada');
  }

  Future<void> _openSharedRecipe() async {
    try {
      if (Platform.isAndroid) {
        final plugin = DeviceInfoPlugin();
        final androidInfo = await plugin.androidInfo;
        
        PermissionStatus status;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ requires photos/videos/audio permissions instead of storage
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }

        if (!status.isGranted) {
          Toaster.showWarning('Se requiere permiso para leer archivos');
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Usamos any para evitar problemas de filtrado por extensión en Android
      );
      
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.toLowerCase().endsWith('.aikr')) {
          Toaster.showWarning('Por favor, selecciona un archivo .aikr');
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewSharedFiles(recipeUri: path),
            ),
          ).then((_) {
            _loadFavorites();
          });
        }
      }
    } catch (e) {
      debugPrint('Error al abrir el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipes = _filteredReipes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar recetas...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _filterRecipes,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.file_open_rounded, color: theme.colorScheme.onPrimaryContainer),
                    onPressed: _openSharedRecipe,
                    tooltip: 'Abrir receta compartida (.aikr)',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: recipes.isEmpty
                ? _buildEmptyState(theme)
                : _buildRecipeList(theme, recipes),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _shareRecipes,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              label: const Text(
                'COMPARTIR',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              icon: const Icon(Icons.share_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Nada por aquí!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las recetas que guardes aparecerán aquí.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(ThemeData theme, List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final isSelected = _selectedRecipes.contains(recipe);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _toggleSelection(recipe);
              });
            },
            onTap: () => _onClickRecipe(recipe),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          recipe.nombre,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (!_isSelectionMode) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _onEditRecipe(recipe),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _removeFavorite(recipe),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () =>
                              ShareRecipeService().shareRecipe([recipe]),
                          icon: const Icon(Icons.share_rounded, size: 20),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
