import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/recipe_list.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:aikitchen/widgets/toaster.dart';

class IngredientsPart extends StatefulWidget {
  final List<String> ingredientes;
  final Function(String) onNewIngredient;
  final Function(String) onRemoveIngredient;
  final Function onFav;
  final Function() onSearch;
  final bool isLoading;
  final bool isFavourite;

  const IngredientsPart({
    super.key,
    required this.onNewIngredient,
    required this.onRemoveIngredient,
    required this.ingredientes,
    required this.onSearch,
    required this.onFav,
    required this.isLoading,
    required this.isFavourite,
  });

  @override
  State<IngredientsPart> createState() => _IngredientsPartState();
}

TextEditingController _ingredientController = TextEditingController();

class _IngredientsPartState extends State<IngredientsPart> {
  bool _isCardExpanded = false; // Keep track of card expansion
  void _addNewIngredient() {
    widget.onNewIngredient(_ingredientController.text);
    Toaster.showToast('Ingrediente añadido: ${_ingredientController.text}');
    setState(() {
      _ingredientController.text = '';
    });
  }

  void _removeIngredient(String ingredient) {
    widget.onRemoveIngredient(ingredient);
    setState(() {});
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      isExpanded: _isCardExpanded, // Use the local state
      alwaysVisible: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: const Icon(Icons.kitchen_rounded),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(-4, -4),
                    inset: true,
                  ),
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(4, 4),
                    inset: true,
                  ),
                ],
              ),
              margin: const EdgeInsets.only(
                left: 5,
                top: 5,
                bottom: 5,
              ), // Keep the original margin
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  top: 8,
                  bottom: 8,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      // to avoid overflow
                      child: Text(
                        widget.ingredientes.join(', '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ], // Keep the original Row children
                ), // Keep the original Padding content
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onSearch,
            icon:
                widget.isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              widget.onFav();
            },
            icon: Icon(
              widget.isFavourite ? Icons.favorite : Icons.favorite_outline,
            ),
          ),
        ],
      ),
      onTap: () {
        // handle onTap event
        setState(() {
          _isCardExpanded = !_isCardExpanded;
        });
      },
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                onEditingComplete: _addNewIngredient,
                controller: _ingredientController,
                decoration: const InputDecoration(
                  hintText: 'Añadir ingrediente',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: _addNewIngredient,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Ingredientes:'),
        ...widget.ingredientes.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                Text('• $ingredient'),
                IconButton(
                  onPressed: () => _removeIngredient(ingredient),
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RecipesListHasData extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe) onFavRecipe;

  const RecipesListHasData({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return RecipeList(
      recipes: recipes,
      onClickRecipe: onClickRecipe,
      onFavRecipe: onFavRecipe,
    );
  }
}
