import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/ingredient_modal.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide BoxShadow;

class RecipePreview extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onGavRecipe;
  final VoidCallback onClickRecipe;
  final VoidCallback onIngredientsClick;
  final Function()? onShareRecipe;
  final Icon? favIcon;
  final Icon shareIcon;
  final bool? selected;
  final Function(Recipe)? onSelected;
  bool isFavorite;
  final Function(Recipe)? onEdit;

  RecipePreview({
    required this.recipe,
    this.onGavRecipe,
    required this.onClickRecipe,
    required this.onIngredientsClick,
    this.isFavorite = false,
    this.onShareRecipe,
    this.favIcon,
    this.selected,
    this.onSelected,
    this.onEdit,
    this.shareIcon = const Icon(Icons.share),
    super.key,
  });

  @override
  State<RecipePreview> createState() => _RecipePreviewState();
}

class _RecipePreviewState extends State<RecipePreview> {
  void _showRecipeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => IngredientModal(
            recipe: widget.recipe,
            onClickRecipe: widget.onClickRecipe,
          ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(context),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: NeumorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.selected != null)
                      IconButton(
                        icon: Icon(
                          widget.selected!
                              ? Icons.check_circle
                              : Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed:
                            widget.onSelected != null
                                ? widget.onSelected!(widget.recipe)
                                : () {},
                      ),

                    Expanded(
                      child: Text(
                        widget.recipe.nombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.onGavRecipe != null)
                      IconButton(
                        icon: Icon(
                          widget.favIcon != null
                              ? widget.favIcon!.icon
                              : widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          widget.onGavRecipe!();
                          setState(() {
                            widget.isFavorite = !widget.isFavorite;
                          });
                        },
                      ),
                    if (widget.onShareRecipe != null && !kIsWeb)
                      IconButton(
                        icon: widget.shareIcon,
                        onPressed: () {
                          widget.onShareRecipe!();
                        },
                      ),
                    if (widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          widget.onEdit!(widget.recipe);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recipe.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Información adicional con chips temáticos
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      widget.recipe.tiempoEstimado,
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildInfoChip(
                      Icons.local_fire_department,
                      '${widget.recipe.calorias.toInt()} cal',
                      Theme.of(context).colorScheme.tertiary,
                    ),
                    _buildInfoChip(
                      Icons.restaurant,
                      '${widget.recipe.raciones} raciones',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipesList extends StatefulWidget {
  final List<Recipe> recipes;
  final Function(Recipe)? onFavRecipe;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe)? onIngredientsClick;
  final bool isFav;
  final Function(List<Recipe>)? onShareRecipe;
  final Icon? favIcon;
  final Function(Recipe) onEdit;

  const RecipesList({
    required this.recipes,
    this.onFavRecipe,
    required this.onClickRecipe,
    this.onIngredientsClick,
    this.isFav = false,
    this.onShareRecipe,
    this.favIcon,
    required this.onEdit,
    super.key,
  });

  @override
  State<RecipesList> createState() => _RecipesListState();
}

List<Recipe> _selectedRecipes = [];

class _RecipesListState extends State<RecipesList> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              ...widget.recipes.map(
                (recipe) => RecipePreview(
                  favIcon: widget.favIcon,
                  recipe: recipe,
                  onGavRecipe:
                      widget.onFavRecipe != null
                          ? () => widget.onFavRecipe!(recipe)
                          : null,
                  onClickRecipe: () => widget.onClickRecipe(recipe),
                  onIngredientsClick: () => widget.onIngredientsClick!(recipe),
                  isFavorite: widget.isFav,
                  onShareRecipe:
                      () => setState(() {
                        _selectedRecipes.add(recipe);
                      }),
                  onEdit: widget.onEdit,
                  shareIcon:
                      _selectedRecipes.contains(recipe)
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.share),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
        if (_selectedRecipes.isNotEmpty && !kIsWeb)
          Positioned(
            bottom: 16 * 5,
            right: 16,
            child: FloatingActionButton.small(
              elevation: 8,
              onPressed: () {
                widget.onShareRecipe!(_selectedRecipes);
                setState(() {
                  _selectedRecipes.clear();
                });
              },
              child: const Icon(kIsWeb ? Icons.download : Icons.share),
            ),
          ),
      ],
    );
  }
}
