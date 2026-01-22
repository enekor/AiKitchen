import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:aikitchen/screens/settings.dart' show TipoReceta;

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    showingRecipe.nombre,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _toggleFavorite,
                  icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  color: _isFavorite ? Colors.redAccent : null,
                  style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              showingRecipe.descripcion,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildInfoRow(theme),
            
            const SizedBox(height: 40),
            _sectionTitle(theme, 'Ingredientes', Icons.shopping_basket_rounded),
            const SizedBox(height: 16),
            IngredientsList(ingredients: showingRecipe.ingredientes),
            
            const SizedBox(height: 40),
            _sectionTitle(theme, 'Preparación', Icons.auto_fix_high_rounded),
            const SizedBox(height: 16),
            StepsList(steps: showingRecipe.preparacion),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _infoChip(theme, Icons.timer_rounded, showingRecipe.tiempoEstimado, theme.colorScheme.secondaryContainer),
        _infoChip(theme, Icons.local_fire_department_rounded, '${showingRecipe.calorias.toInt()} cal', theme.colorScheme.tertiaryContainer),
        _infoChip(theme, Icons.group_rounded, '${showingRecipe.raciones} raciones', theme.colorScheme.surfaceVariant),
      ],
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
