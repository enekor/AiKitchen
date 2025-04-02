import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/ingredient_modal.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class RecipePreview extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onGavRecipe;
  final VoidCallback onClickRecipe;
  final VoidCallback onIngredientsClick;
  bool isFavorite;

  RecipePreview({
    required this.recipe,
    this.onGavRecipe,
    required this.onClickRecipe,
    required this.onIngredientsClick,
    this.isFavorite = false,
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
                          widget.isFavorite
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recipe.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipesList extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe)? onFavRecipe;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe)? onIngredientsClick;
  final bool isFav;

  const RecipesList({
    required this.recipes,
    this.onFavRecipe,
    required this.onClickRecipe,
    this.onIngredientsClick,
    this.isFav = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...recipes.map(
            (recipe) => RecipePreview(
              recipe: recipe,
              onGavRecipe:
                  onFavRecipe != null ? () => onFavRecipe!(recipe) : null,
              onClickRecipe: () => onClickRecipe(recipe),
              onIngredientsClick: () => onIngredientsClick!(recipe),
              isFavorite: isFav,
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
